from skimage import filters
from skimage.feature import local_binary_pattern, graycomatrix, graycoprops
import numpy as np
import cv2
from skimage import color

def gabor_filter(image, frequency=0.6, theta=0) -> np.ndarray:
    """Apply Gabor wavelet filter to grayscale image.
    Args:
        image (np.ndarray): Input image in BGR format.
        frequency (float): Frequency of the sinusoidal function.
        theta (float): Orientation of the Gabor filter in radians.
    Returns:
        np.ndarray: Gabor filtered image."""
    image = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)

    gabor_real, gabor_imag = filters.gabor(image, frequency=frequency, theta=theta)
    # Combine real and imaginary parts for magnitude
    gabor_magnitude = np.sqrt(gabor_real**2 + gabor_imag**2)
    return gabor_magnitude

def lbp_filter(image, radius=3, n_points=24) -> np.ndarray:
    """Apply Local Binary Pattern filter to grayscale image.
    Args:
        image (np.ndarray): Input image in BGR format.
        radius (int): Radius of circle for LBP.
        n_points (int): Number of points to consider for LBP.
    Returns:
        np.ndarray: LBP image.
    """
    image = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    lbp = local_binary_pattern(image, n_points, radius, method='uniform')
    return lbp

def glcm_filter(image, distances=[1], angles=[0]) -> np.ndarray:
    """
    Apply GLCM-based texture visualization.
    Creates a texture map based on local GLCM properties.

    Args:
        image (np.ndarray): Input image in BGR format.
        distances (list): List of pixel pair distance offsets.
        angles (list): List of pixel pair angles in radians.
    Returns:
        np.ndarray: Texture map based on GLCM properties.
    """
    image = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)

    # Normalize and convert to uint8 for GLCM
    image_uint8 = ((image - image.min()) / 
                    (image.max() - image.min()) * 255).astype(np.uint8)
    
    # Compute GLCM-based texture map using sliding window approach
    window_size = 15
    half_win = window_size // 2
    
    # Pad the image
    padded = np.pad(image_uint8, half_win, mode='reflect')
    
    # Create output texture map (using contrast as the texture measure)
    texture_map = np.zeros_like(image)
    
    # Sample every few pixels for efficiency, then interpolate
    step = 3
    for i in range(0, image.shape[0], step):
        for j in range(0, image.shape[1], step):
            window = padded[i:i+window_size, j:j+window_size]
            # Reduce levels for faster computation
            window_reduced = (window // 16).astype(np.uint8)
            glcm = graycomatrix(window_reduced, distances, angles, 
                                levels=16, symmetric=True, normed=True)
            contrast = graycoprops(glcm, 'contrast')[0, 0]
            # Fill the step x step region
            end_i = min(i + step, image.shape[0])
            end_j = min(j + step, image.shape[1])
            texture_map[i:end_i, j:end_j] = contrast
    
    return texture_map
    