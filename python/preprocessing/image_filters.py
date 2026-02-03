import cv2
from skimage import filters
import numpy as np
from skimage.feature import local_binary_pattern, graycomatrix, graycoprops


def gabor_filter(image_gray: np.ndarray) -> np.ndarray:
    """
    Apply Gabor filter bank and aggregate responses.

    Args:
        image_gray: Grayscale image as a 1 Dim 2D numpy array
    Returns:
        3 Dim numpy array with Gabor filter result in (450, 600, 3) shape as 3 channels (gray replicated)
    """
    frequencies = [0.1, 0.3, 0.6]
    thetas = [0, np.pi / 4, np.pi / 2, 3 * np.pi / 4]

    responses = []
    for freq in frequencies:
        for theta in thetas:
            real, imag = filters.gabor(image_gray, frequency=freq, theta=theta)
            magnitude = np.sqrt(real**2 + imag**2)
            responses.append(magnitude)

    # Aggregate (e.g., mean or max across all filters)
    gabor_map = np.mean(responses, axis=0)

    # convert to 3 channel
    gabor_map_3d = np.stack([gabor_map, gabor_map, gabor_map], axis=-1)

    return gabor_map_3d


def lbp_filter(image_gray: np.ndarray, radius=3, n_points=24) -> np.ndarray:
    """
    Apply Local Binary Pattern filter to grayscale image.

    Args:
        image_gray: Grayscale image as a 1 Dim 2D numpy array
        radius: Radius for LBP
        n_points: Number of points for LBP

    Returns:
        3 Dim numpy array with LBP filter result in (450, 600, 3) shape as 3 channels (gray replicated)
    """
    # Convert to uint8 safely
    if image_gray.dtype != np.uint8:
        img = image_gray.astype(np.float32)
        if img.max() <= 1.0:
            img *= 255.0
        image_gray = np.clip(img, 0, 255).astype(np.uint8)

    lbp = local_binary_pattern(image_gray, n_points, radius, method="uniform")

    # convert to 3 channel
    lbp_3d = np.stack([lbp, lbp, lbp], axis=-1)

    return lbp_3d


def glcm_filter(
    image_gray: np.ndarray,  # float [0,1] or uint8 [0,255]
    win=21,  # patch size
    stride=8,  # grid stride
    levels=32,  # quantization levels
    distances=(1, 2),  # offsets
    angles=(0, np.pi / 4, np.pi / 2, 3 * np.pi / 4),
) -> np.ndarray:
    """
    Apply GLCM contrast filter to grayscale image.

    Args:
        image_gray: Grayscale image as a 1 Dim 2D numpy array
        win: Patch size for local GLCM computation
        stride: Stride for sliding window
        levels: Number of gray levels for quantization
        distances: Distances for GLCM
        angles: Angles for GLCM

    Returns:
        3 Dim numpy array with GLCM contrast filter result in (450, 600, 3) shape as 3 channels (gray replicated)

    """
    # 1) Convert to uint8 if needed
    if image_gray.dtype != np.uint8:
        img = image_gray.astype(np.float32)
        if img.max() <= 1.0:
            img *= 255.0
        image_gray_u8 = np.clip(img, 0, 255).astype(np.uint8)
    else:
        image_gray_u8 = image_gray

    # 2) Quantize 0..255 -> 0..levels-1 (required for a bounded GLCM size)
    q = (image_gray_u8.astype(np.float32) * (levels / 256.0)).astype(np.uint8)
    q = np.clip(q, 0, levels - 1)

    H, W = q.shape
    pad = win // 2
    qpad = np.pad(q, pad_width=pad, mode="reflect")

    gh = (H + stride - 1) // stride
    gw = (W + stride - 1) // stride
    feat = np.zeros((gh, gw), dtype=np.float32)

    # 3) Slide on a grid: compute one GLCM per patch, then contrast
    for iy, y in enumerate(range(0, H, stride)):
        for ix, x in enumerate(range(0, W, stride)):
            patch = qpad[y : y + win, x : x + win]

            glcm = graycomatrix(
                patch,
                distances=list(distances),
                angles=list(angles),
                levels=levels,
                symmetric=True,
                normed=True,
            )
            # graycoprops returns array [len(distances), len(angles)]
            c = graycoprops(glcm, "contrast").mean()
            feat[iy, ix] = c

    # 4) Upsample coarse grid to full resolution
    full = cv2.resize(feat, (W, H), interpolation=cv2.INTER_LINEAR)

    # 5) convert to 3 channel
    full_3d = np.stack([full, full, full], axis=-1)

    return full_3d
