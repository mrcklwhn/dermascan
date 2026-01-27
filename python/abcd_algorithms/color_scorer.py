"""
Color analysis utilities for skin lesion dermoscopic images.

This module implements color uniformity scoring based on relative-color
histogram analysis with background skin normalization.
"""

import numpy as np
from skimage.util import img_as_float64 as img_as_float
from typing import Tuple, Dict


def compute_avg_skin_color(image: np.ndarray, lesion_mask: np.ndarray) -> np.ndarray:
    """
    Compute average background skin color from non-lesion pixels.
    
    Args:
        image : np.ndarray
            RGB image in [0, 1] float range
        lesion_mask : np.ndarray
            Boolean mask (True = lesion, False = background)
    
    Returns:
        np.ndarray: Average skin color as (3,) array in [0, 1] range
    """
    img = img_as_float(image)
    
    # Background = non-lesion pixels
    bg_mask = ~lesion_mask
    
    # Optional: basic skin filter in RGB (avoid dark corners, clothes etc.)
    r = img[..., 0]
    g = img[..., 1]
    b = img[..., 2]
    skin_like = (r > b) & (r > g) & (r > 0.35)
    
    valid_bg = bg_mask & skin_like
    
    # Fallback: if filter is too strict, use all non-lesion pixels
    if np.count_nonzero(valid_bg) < 0.01 * img.size / 3:
        valid_bg = bg_mask
    
    avg_skin = img[valid_bg].mean(axis=0)
    return avg_skin


def extract_lesion_relative_colors(image: np.ndarray, lesion_mask: np.ndarray, 
                                   avg_skin: np.ndarray) -> np.ndarray:
    """
    Convert lesion pixels to relative color by subtracting average skin color.
    
    Args:
        image : np.ndarray
            RGB image in [0, 1] float range
        lesion_mask : np.ndarray
            Boolean mask (True = lesion)
        avg_skin : np.ndarray
            Average skin color (3,) array
    
    Returns:
        np.ndarray: Relative colors (N, 3) in roughly [-1, 1] range
    """
    img = img_as_float(image)
    lesion_pixels = img[lesion_mask]
    rel_colors = lesion_pixels - avg_skin[None]
    return rel_colors


def quantize_relative_colors(rel_colors: np.ndarray, n_bins: int = 32) -> np.ndarray:
    """
    Quantize relative colors into coarse bins.
    
    Args:
        rel_colors : np.ndarray
            Relative colors (N, 3) in roughly [-1, 1] range
        n_bins : int
            Number of bins per channel (default: 32)
    
    Returns:
        np.ndarray: Quantized bin indices (N, 3) with values in [0, n_bins-1]
    """
    # Shift & scale from [-1, 1] to [0, 1]
    rel_shifted = (rel_colors + 1.0) / 2.0
    rel_shifted = np.clip(rel_shifted, 0.0, 1.0)
    
    # Quantize
    bin_indices = (rel_shifted * (n_bins - 1)).astype(np.int32)
    return bin_indices


def build_color_histogram(bin_indices: np.ndarray, n_bins: int = 32) -> np.ndarray:
    """
    Build a color histogram from quantized bin indices.
    
    Args:
        bin_indices : np.ndarray
            Quantized bin indices (N, 3)
        n_bins : int
            Number of bins per channel (default: 32)
    
    Returns:
        np.ndarray: Normalized histogram (n_bins^3,) with probabilities
    """
    # Map 3D bin index -> 1D index
    r_bin = bin_indices[:, 0]
    g_bin = bin_indices[:, 1]
    b_bin = bin_indices[:, 2]
    
    flat_index = r_bin * n_bins * n_bins + g_bin * n_bins + b_bin
    
    # Count occurrences
    max_index = n_bins ** 3
    hist = np.bincount(flat_index, minlength=max_index).astype(np.float64)
    
    # Convert to probabilities
    hist /= hist.sum() + 1e-12
    return hist


def skin_like_bin(avg_skin: np.ndarray, n_bins: int = 32) -> np.ndarray:
    """
    Compute quantized bin index for average skin color.
    
    Args:
        avg_skin : np.ndarray
            Average skin color (3,) in [0, 1] range
        n_bins : int
            Number of bins per channel
    
    Returns:
        np.ndarray: Bin indices (3,) for skin color
    """
    avg_shifted = np.clip(avg_skin, 0.0, 1.0)
    return (avg_shifted * (n_bins - 1)).astype(np.int32)


def mask_skin_like_in_hist(hist: np.ndarray, avg_skin: np.ndarray, 
                           n_bins: int = 32, radius: int = 1) -> np.ndarray:
    """
    Remove colors similar to average skin from histogram.
    
    Args:
        hist : np.ndarray
            Histogram (n_bins^3,) with probabilities
        avg_skin : np.ndarray
            Average skin color (3,) in [0, 1] range
        n_bins : int
            Number of bins per channel
        radius : int
            Radius in bin space to exclude around skin color
    
    Returns:
        np.ndarray: Filtered histogram with skin-like colors removed
    """
    skin_bin = skin_like_bin(avg_skin, n_bins=n_bins)
    r0, g0, b0 = skin_bin
    
    # Build boolean mask of size (n_bins, n_bins, n_bins)
    mask3d = np.ones((n_bins, n_bins, n_bins), dtype=bool)
    for dr in range(-radius, radius + 1):
        for dg in range(-radius, radius + 1):
            for db in range(-radius, radius + 1):
                rr = r0 + dr
                gg = g0 + dg
                bb = b0 + db
                if 0 <= rr < n_bins and 0 <= gg < n_bins and 0 <= bb < n_bins:
                    mask3d[rr, gg, bb] = False
    
    # Flatten and apply
    mask_flat = mask3d.reshape(-1)
    hist_filtered = hist.copy()
    hist_filtered[~mask_flat] = 0.0
    hist_filtered /= hist_filtered.sum() + 1e-12
    return hist_filtered


def histogram_entropy(hist: np.ndarray) -> float:
    """
    Calculate entropy of histogram.
    
    Higher entropy indicates more variegated (less uniform) lesion.
    
    Args:
        hist : np.ndarray
            Normalized histogram (probabilities sum to 1)
    
    Returns:
        float: Entropy in bits
    """
    p = hist[hist > 0]
    return -np.sum(p * np.log2(p))


def effective_color_count(hist: np.ndarray, min_prob: float = 1e-4) -> int:
    """
    Count number of significantly populated bins.
    
    Args:
        hist : np.ndarray
            Normalized histogram
        min_prob : float
            Minimum probability threshold for counting
    
    Returns:
        int: Number of bins with probability > min_prob
    """
    return int(np.sum(hist > min_prob))


def calculate_color_uniformity_score(image: np.ndarray, mask: np.ndarray, 
                                    n_bins: int = 32, skin_radius: int = 1, 
                                    min_prob: float = 1e-4) -> float:
    """
    Calculate color uniformity score using relative-color histogram analysis.
    
    Pipeline:
    1. Compute average background skin color
    2. Extract lesion pixels and convert to relative colors (subtract skin color)
    3. Quantize relative colors into coarse bins
    4. Build color histogram
    5. Remove colors similar to skin
    6. Calculate normalized uniformity score from entropy
    
    Args:
        image : np.ndarray
            RGB dermoscopic image, uint8 [0, 255] or float [0, 1]
            Shape: (height, width, 3)
        mask : np.ndarray
            Binary lesion mask (True/1 = lesion, False/0 = background)
            Shape: (height, width)
        n_bins : int
            Number of bins per RGB channel for quantization (default: 32)
        skin_radius : int
            Radius in bin space to exclude around skin color (default: 1)
        min_prob : float
            Minimum probability for counting effective colors (default: 1e-4)
    
    Returns:
        float: Normalized uniformity score in [0, 1]
               0 = highly variegated (high entropy, many colors)
               1 = highly uniform (low entropy, few colors)
    """
    # Convert mask to boolean
    lesion_mask = mask.astype(bool)
    
    # Check for valid lesion pixels
    if not lesion_mask.any():
        return 1.0  # No lesion = perfectly uniform
    
    # 1. Compute average skin color
    avg_skin = compute_avg_skin_color(image, lesion_mask)
    
    # 2. Extract relative lesion colors
    rel_colors = extract_lesion_relative_colors(image, lesion_mask, avg_skin)
    
    # 3. Quantize to bins
    bin_indices = quantize_relative_colors(rel_colors, n_bins=n_bins)
    
    # 4. Build histogram
    hist = build_color_histogram(bin_indices, n_bins=n_bins)
    
    # 5. Remove skin-like colors
    hist_filtered = mask_skin_like_in_hist(hist, avg_skin, n_bins=n_bins, 
                                          radius=skin_radius)
    
    # 6. Calculate uniformity metrics
    entropy = histogram_entropy(hist_filtered)
    n_eff = effective_color_count(hist_filtered, min_prob=min_prob)
    
    # Normalize entropy to [0, 1] score
    # Max possible entropy is log2(n_bins^3) for uniform distribution
    # But we use effective colors as upper bound for more practical normalization
    max_entropy = np.log2(max(n_eff, 1))
    
    # Uniformity score: invert so high uniformity = high score
    if max_entropy > 0:
        uniformity_score = 1.0 - min(entropy / (max_entropy + 5.0), 1.0)
    else:
        uniformity_score = 1.0
    
    return uniformity_score


def analyze_lesion_colors(image: np.ndarray, mask: np.ndarray, 
                         n_bins: int = 32, skin_radius: int = 1) -> Tuple:
    """
    Comprehensive color analysis of a skin lesion image using histogram method.
    
    Args:
        image : np.ndarray
            RGB dermoscopic image of skin lesion
        mask : np.ndarray
            Binary lesion mask (True/1 = lesion, False/0 = background)
        n_bins : int
            Number of bins per RGB channel (default: 32)
        skin_radius : int
            Radius for excluding skin-like colors (default: 1)
    
    Returns:
        dict: Analysis results containing
            - uniformity_score: Float from 0 to 1 (1 = most uniform)
            - effective_colors: Number of significantly populated color bins
            - entropy: Raw entropy value in bits
    """
    lesion_mask = mask.astype(bool)
    
    if not lesion_mask.any():
        return (1.0, 0, 0.0)
    
    # Compute metrics
    avg_skin = compute_avg_skin_color(image, lesion_mask)
    rel_colors = extract_lesion_relative_colors(image, lesion_mask, avg_skin)
    bin_indices = quantize_relative_colors(rel_colors, n_bins=n_bins)
    hist = build_color_histogram(bin_indices, n_bins=n_bins)
    hist_filtered = mask_skin_like_in_hist(hist, avg_skin, n_bins=n_bins, 
                                          radius=skin_radius)
    
    entropy = histogram_entropy(hist_filtered)
    n_eff = effective_color_count(hist_filtered, min_prob=1e-4)
    
    # Calculate uniformity score
    uniformity_score = calculate_color_uniformity_score(image, mask, n_bins=n_bins, 
                                                       skin_radius=skin_radius)
    
    return (uniformity_score, n_eff, entropy)
