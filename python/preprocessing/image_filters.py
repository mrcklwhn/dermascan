import cv2
from skimage import filters
from scipy.ndimage import gaussian_filter
from scipy.signal import fftconvolve
from scipy import ndimage as ndim
import numpy as np
from skimage.feature import local_binary_pattern, graycomatrix, graycoprops
from pathlib import Path
import pickle

current_dir = Path.cwd()
proj_dir = current_dir.parent.parent.resolve() # get project root directory

# Cache file for precomputed Gabor kernels to speed up subsequent runs
_GABOR_CACHE_FILE = proj_dir / "data" / "filtered" / "gabor_filter" / "_GABOR_KERNELS_CACHE.pkl"

# Global variable to hold precomputed Gabor kernels in memory
_GABOR_KERNELS = None

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
        print("Gabor kernels not loaded. Checking cache...")
        cache_dir = _GABOR_CACHE_FILE.parent
        cache_dir.mkdir(parents=True, exist_ok=True)

        # Check cache
        if _GABOR_CACHE_FILE.exists():
            print("Gabor kernel cache found. Loading kernels...")
            with open(_GABOR_CACHE_FILE, 'rb') as f:
                _GABOR_KERNELS = pickle.load(f)
        # if cache not found, compute kernels and save to cache
        else:
            print("Precomputing Gabor kernels...")
            # 5 frequencies for multi-scale texture capture
            # Low freq (0.05) = coarse texture, High freq (0.4) = fine details
            frequencies = [0.05, 0.1, 0.2, 0.3, 0.4]

            # 8 orientations for complete directional coverage
            # Critical for capturing border irregularity and asymmetry in melanoma
            thetas = np.arange(0, np.pi, np.pi/8)  # 0°, 22.5°, 45°, 67.5°, 90°, 112.5°, 135°, 157.5°

            # Precompute Gabor kernels
            kernels = []
            for freq in frequencies:
                for theta in thetas:
                    kernel = filters.gabor_kernel(frequency=freq, theta=theta)
                    kernels.append(kernel)

            _GABOR_KERNELS = kernels
            
            # Save with pickle
            with open(_GABOR_CACHE_FILE, 'wb') as f:
                pickle.dump(_GABOR_KERNELS, f)
            print(f"Cached kernels to {_GABOR_CACHE_FILE}") 
           
    responses = []
    for kernel in _GABOR_KERNELS:
            # FFT-based convolution for speed, especially with larger kernels
            filtered_real = fftconvolve(image_gray, np.real(kernel), mode='same')
            filtered_imag = fftconvolve(image_gray, np.imag(kernel), mode='same')
            magnitude = np.sqrt(filtered_real**2 + filtered_imag**2)
            responses.append(magnitude)
    
    # Stack all responses: (40, H, W)
    gabor_map = np.stack(responses, axis=0)
    
    # Global normalization - preserves relative magnitudes across channels
    # Strong responses remain stronger than weak ones
    global_min = gabor_map.min()
    global_max = gabor_map.max()
    gabor_map = ((gabor_map - global_min) / (global_max - global_min + 1e-8)).astype(np.float32)
    
    return gabor_map

def lbp_filter(image_gray: np.ndarray) -> np.ndarray:
    """
    Apply Local Binary Pattern filter optimized for skin lesion analysis.
    Uses rotation-invariant uniform LBP with P=8 circular neighbors and R=1 radius distance configuration.
    
    Args:
        image_gray: Grayscale image as a 2D numpy array (H x W)
    
    Returns:
        3D numpy array with shape (1, H, W) - single channel
    """
    # Preprocessing: Apply slight Gaussian smoothing to reduce noise
    smoothed = gaussian_filter(image_gray, sigma=1.0)
    
    # Convert to uint8 safely
    if smoothed.dtype != np.uint8:
        img = smoothed.astype(np.float32)
        if img.max() <= 1.0:
            img *= 255.0
        smoothed = np.clip(img, 0, 255).astype(np.uint8)
    
    # Apply rotation-invariant uniform LBP
    lbp = local_binary_pattern(smoothed, P=8, R=1, method='uniform')
    
    # Normalize to [0, 1]
    lbp_normalized = (lbp / (lbp.max() + 1e-8)).astype(np.float32)
    
    # Add channel dimension: (H, W) -> (1, H, W)
    lbp_3d = lbp_normalized[np.newaxis, ...]
    
    return lbp_3d


def glcm_filter(
    image_gray: np.ndarray,
    win: int = 21,
    stride: int = 8,
    levels: int = 8,  # Or try 16
    distances: tuple = (1, 3),
    angles: tuple = (0, np.pi/4, np.pi/2, 3*np.pi/4),
    properties: tuple = ('contrast', 'homogeneity', 'energy', 'correlation')
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
            patch = qpad[y:y + win, x:x + win]
            
            glcm = graycomatrix(
                patch,
                distances=list(distances),
                angles=list(angles),
                levels=levels,
                symmetric=True,
                normed=True,
            )
            
            # Extract all properties for each angle/distance combination
            ch_idx = 0
            for prop in properties:
                props = graycoprops(glcm, prop)  # returns (len(distances), len(angles))
                feat_maps[iy, ix, ch_idx:ch_idx + props.size] = props.flatten()
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



