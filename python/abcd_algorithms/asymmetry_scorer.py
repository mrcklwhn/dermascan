import numpy as np
import cv2
from abcd_algorithms.mask_utils import (
    create_simple_binary_mask,
    compute_centroid,
    simple_axis_split,
    get_largest_region_skimage,
    rotate_mask_to_principal_axis
)


def calculate_quadrant_asymmetry(q1: np.ndarray, q2: np.ndarray) -> float:
    """
    Calculate asymmetry between two quadrants.
    Args:
        q1: First quadrant binary mask.
        q2: Second quadrant binary mask.
    Returns:
        Asymmetry score between the two quadrants ranging from 0 to 1.
    """
    h1, w1 = q1.shape
    h2, w2 = q2.shape
    h, w = max(h1, h2), max(w1, w2)
    q1_resized = cv2.resize(q1, (w, h), interpolation=cv2.INTER_NEAREST)
    q2_resized = cv2.resize(q2, (w, h), interpolation=cv2.INTER_NEAREST)

    difference = cv2.absdiff(q1_resized, q2_resized)
    asymmetry_score = np.sum(difference) / (255 * h * w)

    return asymmetry_score


def calculate_asymmetry(image: np.ndarray) -> float:
    """
    Calculate the asymmetry of the lesion in the image.
    Args:
        image: Input image as a numpy array.
    Returns:
        Asymmetry score of the lesion ranging from 0 to 1.
        where 0 is perfectly symmetric and 1 is highly asymmetric.
    """

    mask = create_simple_binary_mask(image)

    cx, cy = compute_centroid(mask)

    top_left, top_right, bottom_left, bottom_right = simple_axis_split(mask, cx, cy)

    asymmetry_score_1 = calculate_quadrant_asymmetry(top_left, bottom_right)
    asymmetry_score_2 = calculate_quadrant_asymmetry(top_right, bottom_left)
    total_asymmetry_score = (asymmetry_score_1 + asymmetry_score_2) / 2

    return total_asymmetry_score


def calculate_asymmetry_skimage(image: np.ndarray) -> float:
    """
    Calculate the asymmetry of the lesion using scikit-image regionprops and rotation.

    Algorithm:
    1. Create a binary mask of the lesion using Otsu's thresholding.
    2. Rotate the mask to align with its principal axis.
    3. Split the rotated mask into left-right and top-bottom halves based on the centroid.
    4. Flip one half and calculate the overlap area with the other half to quantify asymmetry.
    5. Average the asymmetry scores from both splits to get the final asymmetry score.

    Args:
        image: Input image as a numpy array (BGR format expected).
    Returns:
        Asymmetry score ranging from 0 to 1, where 0 is perfectly symmetric
        and higher values indicate greater asymmetry.
    """
    # Step 1: Create binary mask
    mask_binary = create_simple_binary_mask(image)
    largest_region = get_largest_region_skimage(mask_binary)
    
    # Step 2: Rotate mask to principal axis
    rotated_mask, angle_degrees = rotate_mask_to_principal_axis(mask_binary)
    
    # Step 3: Get centroid of rotated mask
    rotated_region = get_largest_region_skimage(rotated_mask)
    cy, cx = int(rotated_region.centroid[0]), int(rotated_region.centroid[1])
    
    # Step 4: Calculate left-right asymmetry
    left_half = rotated_mask[:, :cx]
    right_half = rotated_mask[:, cx:]
    right_half_flipped = np.fliplr(right_half)
    
    # Resize to match dimensions
    min_width = min(left_half.shape[1], right_half_flipped.shape[1])
    left_half_resized = left_half[:, :min_width]
    right_half_resized = right_half_flipped[:, :min_width]
    
    # Calculate overlap asymmetry (1 - overlap ratio)
    intersection_lr = np.logical_and(left_half_resized, right_half_resized)
    union_lr = np.logical_or(left_half_resized, right_half_resized)
    lr_asymmetry = 1.0 - (np.sum(intersection_lr) / (np.sum(union_lr) + 1e-7))
    
    # Step 5: Calculate top-bottom asymmetry
    top_half = rotated_mask[:cy, :]
    bottom_half = rotated_mask[cy:, :]
    bottom_half_flipped = np.flipud(bottom_half)
    
    # Resize to match dimensions
    min_height = min(top_half.shape[0], bottom_half_flipped.shape[0])
    top_half_resized = top_half[:min_height, :]
    bottom_half_resized = bottom_half_flipped[:min_height, :]
    
    # Calculate overlap asymmetry
    intersection_tb = np.logical_and(top_half_resized, bottom_half_resized)
    union_tb = np.logical_or(top_half_resized, bottom_half_resized)
    tb_asymmetry = 1.0 - (np.sum(intersection_tb) / (np.sum(union_tb) + 1e-7))
    
    # Step 6: Average the asymmetry scores
    total_asymmetry = (lr_asymmetry + tb_asymmetry) / 2.0
    
    return total_asymmetry


def visualize_asymmetry_calculation(image: np.ndarray) -> tuple[np.ndarray, np.ndarray]:
    """
    Visualize the asymmetry calculation steps.
    
    Args:
        image: Input image as a numpy array.
    Returns:
        Tuple of (original_mask_vis, rotated_mask_vis) with centroids and split lines drawn.
    """
    mask_binary = create_simple_binary_mask(image)
    largest_region = get_largest_region_skimage(mask_binary)
    
    # Original mask visualization
    original_vis = cv2.cvtColor((mask_binary).astype(np.uint8), cv2.COLOR_GRAY2BGR)
    cx, cy = int(largest_region.centroid[1]), int(largest_region.centroid[0])
    cv2.circle(original_vis, (cx, cy), 5, (0, 255, 0), -1)
    
    # Rotate mask
    rotated_mask, angle_degrees = rotate_mask_to_principal_axis(mask_binary)
    
    # Rotated mask visualization
    rotated_vis = cv2.cvtColor((rotated_mask * 255).astype(np.uint8), cv2.COLOR_GRAY2BGR)
    rotated_region = get_largest_region_skimage(rotated_mask)
    rotated_cy, rotated_cx = int(rotated_region.centroid[0]), int(rotated_region.centroid[1])
    
    cv2.circle(rotated_vis, (rotated_cx, rotated_cy), 5, (0, 255, 0), -1)
    cv2.line(rotated_vis, (rotated_cx, 0), (rotated_cx, rotated_vis.shape[0]), (255, 0, 0), 2)
    cv2.line(rotated_vis, (0, rotated_cy), (rotated_vis.shape[1], rotated_cy), (255, 0, 0), 2)
    
    return original_vis, rotated_vis


