import cv2
import numpy as np
from pathlib import Path
import pickle

current_dir = Path.cwd()
proj_dir = current_dir.parent.parent.resolve()  # get project root directory

# Cache file for precomputed Gabor kernels to speed up subsequent runs
_GABOR_CACHE_FILE = proj_dir / "data" / "filtered" / "gabor_filter" / "_GABOR_KERNELS_CACHE.pkl"

# Global variable to hold precomputed Gabor kernels in memory
_GABOR_KERNELS = None


def _sigma_prefactor(bandwidth: float) -> float:
    """Match skimage.filters._gabor._sigma_prefactor."""
    b = float(bandwidth)
    return (1.0 / np.pi) * np.sqrt(np.log(2.0) / 2.0) * ((2.0**b + 1.0) / (2.0**b - 1.0))


def _build_gabor_kernel_skimage_compatible(
    frequency: float,
    theta: float = 0.0,
    bandwidth: float = 1.0,
    sigma_x: float | None = None,
    sigma_y: float | None = None,
    n_stds: int = 3,
    offset: float = 0.0,
) -> np.ndarray:
    """Build a complex Gabor kernel using OpenCV with skimage-equivalent parameters."""
    if sigma_x is None:
        sigma_x = _sigma_prefactor(bandwidth) / frequency
    if sigma_y is None:
        sigma_y = _sigma_prefactor(bandwidth) / frequency

    ct = float(np.cos(theta))
    st = float(np.sin(theta))
    x0 = int(np.ceil(max(abs(n_stds * sigma_x * ct), abs(n_stds * sigma_y * st), 1.0)))
    y0 = int(np.ceil(max(abs(n_stds * sigma_y * ct), abs(n_stds * sigma_x * st), 1.0)))

    # OpenCV expects ksize=(width, height).
    ksize = (2 * x0 + 1, 2 * y0 + 1)
    lambd = 1.0 / float(frequency)
    gamma = float(sigma_x / sigma_y)

    real_kernel = cv2.getGaborKernel(
        ksize=ksize,
        sigma=float(sigma_x),
        theta=float(theta),
        lambd=lambd,
        gamma=gamma,
        psi=float(offset),
        ktype=cv2.CV_64F,
    )

    # cv2.getGaborKernel emits cosine-phase kernels; psi=offset-pi/2 yields sine phase.
    imag_kernel = cv2.getGaborKernel(
        ksize=ksize,
        sigma=float(sigma_x),
        theta=float(theta),
        lambd=lambd,
        gamma=gamma,
        psi=float(offset - (np.pi / 2.0)),
        ktype=cv2.CV_64F,
    )

    # skimage scales kernels by 1 / (2 * pi * sigma_x * sigma_y).
    norm = 1.0 / (2.0 * np.pi * float(sigma_x) * float(sigma_y))
    return (real_kernel + 1j * imag_kernel).astype(np.complex128) * norm


def _is_valid_cached_gabor_kernels(kernels: object) -> bool:
    if not isinstance(kernels, list) or len(kernels) != 40:
        return False

    for kernel in kernels:
        if not isinstance(kernel, np.ndarray):
            return False
        if kernel.ndim != 2:
            return False
        if not np.iscomplexobj(kernel):
            return False

    return True


def _load_or_build_gabor_kernels() -> list[np.ndarray]:
    cache_dir = _GABOR_CACHE_FILE.parent
    cache_dir.mkdir(parents=True, exist_ok=True)

    if _GABOR_CACHE_FILE.exists():
        try:
            with open(_GABOR_CACHE_FILE, "rb") as f:
                cached = pickle.load(f)

            if _is_valid_cached_gabor_kernels(cached):
                return [np.asarray(kernel, dtype=np.complex128) for kernel in cached]
        except Exception:
            pass

    frequencies = [0.05, 0.1, 0.2, 0.3, 0.4]
    thetas = np.arange(0, np.pi, np.pi / 8)

    kernels = [
        _build_gabor_kernel_skimage_compatible(frequency=freq, theta=theta) for freq in frequencies for theta in thetas
    ]

    with open(_GABOR_CACHE_FILE, "wb") as f:
        pickle.dump(kernels, f)

    return kernels


def _convolve_same_zero_pad(image: np.ndarray, kernel: np.ndarray) -> np.ndarray:
    # OpenCV filter2D is correlation; flip the kernel to perform true convolution.
    flipped_kernel = cv2.flip(np.ascontiguousarray(kernel, dtype=np.float64), -1)
    return cv2.filter2D(
        src=np.ascontiguousarray(image, dtype=np.float64),
        ddepth=cv2.CV_64F,
        kernel=flipped_kernel,
        borderType=cv2.BORDER_CONSTANT,
    )

def _round_half_away_from_zero(value: float) -> int:
    """Match skimage's Cython round helper used in GLCM offset computation."""
    if value > 0.0:
        return int(np.floor(value + 0.5))
    return int(np.ceil(value - 0.5))


def _graycomatrix_skimage_compatible(
    image: np.ndarray,
    distances: np.ndarray,
    angles: np.ndarray,
    levels: int,
    symmetric: bool = False,
    normed: bool = False,
) -> np.ndarray:
    """Numpy implementation matching skimage.feature.graycomatrix behavior."""
    image_i = np.ascontiguousarray(image)
    distances_f = np.ascontiguousarray(distances, dtype=np.float64)
    angles_f = np.ascontiguousarray(angles, dtype=np.float64)

    rows, cols = image_i.shape
    out = np.zeros((levels, levels, len(distances_f), len(angles_f)), dtype=np.uint32, order="C")

    for a_idx, angle in enumerate(angles_f):
        for d_idx, distance in enumerate(distances_f):
            offset_row = _round_half_away_from_zero(np.sin(angle) * distance)
            offset_col = _round_half_away_from_zero(np.cos(angle) * distance)

            start_row = max(0, -offset_row)
            end_row = min(rows, rows - offset_row)
            start_col = max(0, -offset_col)
            end_col = min(cols, cols - offset_col)

            if start_row >= end_row or start_col >= end_col:
                continue

            src = image_i[start_row:end_row, start_col:end_col].astype(np.int64, copy=False)
            dst = image_i[
                start_row + offset_row : end_row + offset_row,
                start_col + offset_col : end_col + offset_col,
            ].astype(np.int64, copy=False)

            valid = (src >= 0) & (src < levels) & (dst >= 0) & (dst < levels)
            if not np.any(valid):
                continue

            linear = (src[valid] * levels + dst[valid]).ravel()
            counts = np.bincount(linear, minlength=levels * levels)
            out[:, :, d_idx, a_idx] = counts.reshape((levels, levels)).astype(np.uint32, copy=False)

    if symmetric:
        out = out + np.transpose(out, (1, 0, 2, 3))

    if normed:
        out = out.astype(np.float64)
        glcm_sums = np.sum(out, axis=(0, 1), keepdims=True)
        glcm_sums[glcm_sums == 0] = 1
        out /= glcm_sums

    return out


def _graycoprops_skimage_compatible(P: np.ndarray, prop: str = "contrast") -> np.ndarray:
    """Numpy implementation matching skimage.feature.graycoprops behavior."""
    num_level, num_level2, num_dist, num_angle = P.shape
    if num_level != num_level2:
        raise ValueError("num_level and num_level2 must be equal.")
    if num_dist <= 0:
        raise ValueError("num_dist must be positive.")
    if num_angle <= 0:
        raise ValueError("num_angle must be positive.")

    # graycoprops normalizes input even when graycomatrix was already normalized.
    P = P.astype(np.float64)
    glcm_sums = np.sum(P, axis=(0, 1), keepdims=True)
    glcm_sums[glcm_sums == 0] = 1
    P /= glcm_sums

    row_levels, col_levels = np.ogrid[0:num_level, 0:num_level]
    if prop == "contrast":
        weights = (row_levels - col_levels) ** 2
    elif prop == "dissimilarity":
        weights = np.abs(row_levels - col_levels)
    elif prop == "homogeneity":
        weights = 1.0 / (1.0 + (row_levels - col_levels) ** 2)
    elif prop in ["ASM", "energy", "correlation", "entropy", "variance", "mean", "std"]:
        pass
    else:
        raise ValueError(f"{prop} is an invalid property")

    if prop == "energy":
        asm = np.sum(P**2, axis=(0, 1))
        results = np.sqrt(asm)
    elif prop == "ASM":
        results = np.sum(P**2, axis=(0, 1))
    elif prop == "mean":
        I2 = np.arange(num_level).reshape((num_level, 1, 1, 1))
        results = np.sum(I2 * P, axis=(0, 1))
    elif prop == "variance":
        I2 = np.arange(num_level).reshape((num_level, 1, 1, 1))
        mean = np.sum(I2 * P, axis=(0, 1))
        results = np.sum(P * ((I2 - mean) ** 2), axis=(0, 1))
    elif prop == "std":
        I2 = np.arange(num_level).reshape((num_level, 1, 1, 1))
        mean = np.sum(I2 * P, axis=(0, 1))
        var = np.sum(P * ((I2 - mean) ** 2), axis=(0, 1))
        results = np.sqrt(var)
    elif prop == "entropy":
        ln = -np.log(P, where=(P != 0), out=np.zeros_like(P))
        results = np.sum(P * ln, axis=(0, 1))
    elif prop == "correlation":
        results = np.zeros((num_dist, num_angle), dtype=np.float64)
        I2 = np.arange(num_level).reshape((num_level, 1, 1, 1))
        J2 = np.arange(num_level).reshape((1, num_level, 1, 1))

        diff_i = I2 - np.sum(I2 * P, axis=(0, 1))
        diff_j = J2 - np.sum(J2 * P, axis=(0, 1))

        std_i = np.sqrt(np.sum(P * (diff_i**2), axis=(0, 1)))
        std_j = np.sqrt(np.sum(P * (diff_j**2), axis=(0, 1)))
        cov = np.sum(P * (diff_i * diff_j), axis=(0, 1))

        mask_0 = std_i < 1e-15
        mask_0[std_j < 1e-15] = True
        results[mask_0] = 1

        mask_1 = ~mask_0
        results[mask_1] = cov[mask_1] / (std_i[mask_1] * std_j[mask_1])
    elif prop in ["contrast", "dissimilarity", "homogeneity"]:
        weights = weights.reshape((num_level, num_level, 1, 1))
        results = np.sum(P * weights, axis=(0, 1))

    return results


def gabor_filter(image_gray: np.ndarray) -> np.ndarray:
    """
    Apply Gabor filter optimized for skin lesion analysis.
    Load precomputed kernels from cache if available, otherwise compute and save for performance.
    Configuration: 8 orientations × 5 scales = 40 channels

    Args:
        image_gray: Grayscale image as a 2D numpy array (H x W)

    Returns:
        3D numpy array with shape (40, H, W) - 40 channels
    """
    global _GABOR_KERNELS

    if _GABOR_KERNELS is None:
        _GABOR_KERNELS = _load_or_build_gabor_kernels()

    image = np.asarray(image_gray, dtype=np.float64)

    responses = []
    for kernel in _GABOR_KERNELS:
        filtered_real = _convolve_same_zero_pad(image, np.real(kernel))
        filtered_imag = _convolve_same_zero_pad(image, np.imag(kernel))
        magnitude = cv2.magnitude(filtered_real, filtered_imag)
        responses.append(magnitude)

    # Stack all responses: (40, H, W)
    gabor_map = np.stack(responses, axis=0)

    # Global normalization - preserves relative magnitudes across channels
    # Strong responses remain stronger than weak ones
    global_min = gabor_map.min()
    global_max = gabor_map.max()
    gabor_map = ((gabor_map - global_min) / (global_max - global_min + 1e-8)).astype(np.float32)

    return gabor_map

def glcm_filter(
    image_gray: np.ndarray,
    win: int = 21,
    stride: int = 8,
    levels: int = 8,  # Or try 16
    distances: tuple = (1, 3),
    angles: tuple = (0, np.pi / 4, np.pi / 2, 3 * np.pi / 4),
    properties: tuple = ("contrast", "homogeneity", "energy", "correlation"),
) -> np.ndarray:
    """
    Apply GLCM texture filter optimized for skin lesion analysis.
    Configuration: 4 properties × 4 orientations × 2 distances = 32 channels

    Args:
        image_gray: Grayscale image as a 2D numpy array (H x W)
        win: Patch size for local GLCM computation
        stride: Stride for sliding window
        levels: Number of gray levels (quantization) for GLCM (8 or 16 recommended)
        distances: Distances for GLCM (1, 3 recommended)
        angles: Angles for GLCM (4 orientations)
        properties: GLCM properties ('contrast', 'dissimilarity', 'homogeneity', 'energy')

    Returns:
        3D numpy array with shape (32, H, W) - 32 channels
    """
    # Convert to uint8 if needed, ensuring values are in [0, 255]
    if image_gray.dtype != np.uint8:
        img = image_gray.astype(np.float32)
        if img.max() <= 1.0:
            img *= 255.0
        image_gray_u8 = np.clip(img, 0, 255).astype(np.uint8)
    else:
        image_gray_u8 = image_gray

    # Quantize to specified levels (e.g., 8) for GLCM computation
    q = (image_gray_u8.astype(np.float32) * (levels / 256.0)).astype(np.uint8)
    q = np.clip(q, 0, levels - 1)

    distances_arr = np.ascontiguousarray(distances, dtype=np.float64)
    angles_arr = np.ascontiguousarray(angles, dtype=np.float64)

    H, W = q.shape
    pad = win // 2
    qpad = np.pad(q, pad_width=pad, mode="reflect")

    gh = (H + stride - 1) // stride
    gw = (W + stride - 1) // stride

    # Initialize feature maps for all property/orientation/distance combinations
    # Shape: (gh, gw, 32) where 32 = 4 properties × 4 angles × 2 distances
    n_channels = len(properties) * len(angles) * len(distances)
    feat_maps = np.zeros((gh, gw, n_channels), dtype=np.float32)

    # Slide over the image with the specified window and stride
    # Compute GLCM per patch, extract properties, and store in feature maps
    for iy, y in enumerate(range(0, H, stride)):
        for ix, x in enumerate(range(0, W, stride)):
            patch = qpad[y : y + win, x : x + win]

            glcm = _graycomatrix_skimage_compatible(
                patch,
                distances=distances_arr,
                angles=angles_arr,
                levels=levels,
                symmetric=True,
                normed=True,
            )

            # Extract all properties for each angle/distance combination
            ch_idx = 0
            for prop in properties:
                props = _graycoprops_skimage_compatible(glcm, prop)  # returns (len(distances), len(angles))
                feat_maps[iy, ix, ch_idx : ch_idx + props.size] = props.flatten()
                ch_idx += props.size

    # Upsample each channel back to original image size using interpolation
    channels = []
    for ch in range(n_channels):
        full_res = cv2.resize(feat_maps[:, :, ch], (W, H), interpolation=cv2.INTER_LINEAR)
        channels.append(full_res)

    # Stack channels to get final output: (32, H, W)
    glcm_features = np.stack(channels, axis=0)

    # Global normalization accross the entire feature map to preserve relative differences between channels
    global_min = glcm_features.min()
    global_max = glcm_features.max()
    glcm_normalized = ((glcm_features - global_min) / (global_max - global_min + 1e-8)).astype(np.float32)

    return glcm_normalized