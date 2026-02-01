import numpy as np
from python.abcd_algorithms.mask_utils import boundary_extraction
from skimage.morphology import convex_hull_image, closing, remove_small_holes, disk
from skimage.measure import label, regionprops, find_contours
from typing import Dict, List, Tuple



def calculate_rdv_metrics(mask: np.ndarray, centroid_x: float, centroid_y: float) -> float:
    """
    Calculate radial distance variation (RDV) metrics to measure border irregularity of a skin lesion.
    
    The method computes distances from the centroid to all boundary points and calculates
    statistical metrics to quantify how irregular the border is. A perfectly circular lesion
    would have minimal variation, while irregular borders show higher variation.
    
    Args:
        mask: Binary mask of the lesion as a numpy array.
        centroid_x: X-coordinate of the centroid.
        centroid_y: Y-coordinate of the centroid.
    
    Returns:
        rdv-score: A float value representing the radial distance variation score. 0 indicates
        a perfectly regular border, while higher values indicate more irregularity.
    """
    # Extract the boundary from the mask
    outline = boundary_extraction(mask)
    
    # Get boundary point coordinates
    boundary_points = np.argwhere(outline > 0)
    
    if len(boundary_points) == 0:
        # No boundary found, throw an error
        raise ValueError("No boundary points found in the lesion mask.")
    
    # Calculate Euclidean distances from centroid to each boundary point
    distances = np.sqrt(
        (boundary_points[:, 1] - centroid_x) ** 2 + 
        (boundary_points[:, 0] - centroid_y) ** 2
    )
    
    # Calculate statistical metrics
    mean_distance = np.mean(distances)
    std_distance = np.std(distances)
    
    # Calculate RDV score (coefficient of variation)
    # Normalized by mean to make it scale-invariant
    if mean_distance > 0:
        rdv_score = std_distance / mean_distance
    else:
        rdv_score = 0.0
    
    # Clip to [0, 1] range for consistency
    rdv_score = float(np.clip(rdv_score, 0, 1))
    
    return rdv_score


def preprocess_lesion(binary_mask: np.ndarray) -> np.ndarray:
    """
    Basic artifact suppression on the binary mask to reduce thin hair-like
    indentations that can inflate irregularity.

    Applies a small morphological closing and fills tiny holes.
    """
    if binary_mask.dtype != np.bool_:
        mask = binary_mask.astype(bool)
    else:
        mask = binary_mask

    # Close thin gaps (hair-like cuts) and smooth minor notches
    mask_closed = closing(mask, footprint=disk(2))
    # Remove small holes within the lesion
    mask_clean = remove_small_holes(mask_closed, max_size=64)
    return mask_clean.astype(np.uint8)


def polygon_area(coords: np.ndarray) -> float:
    """
    Compute area of a 2D polygon given ordered coordinates using the shoelace formula.
    Expects coords as array of shape (N, 2) with (y, x) ordering.
    """
    if coords.shape[0] < 3:
        return 0.0
    y = coords[:, 0]
    x = coords[:, 1]
    # Shoelace formula on (x, y)
    s1 = np.dot(x, np.roll(y, -1))
    s2 = np.dot(y, np.roll(x, -1))
    return float(abs(s1 - s2) * 0.5)


def extract_parametric_border(binary_mask: np.ndarray) -> Tuple[np.ndarray, np.ndarray, np.ndarray]:
    """
    Extract the largest ordered border from the binary mask and parameterize by arc length.

    Returns arrays (x_s, y_s, s) where s is normalized arc length in [0, 1].
    Coordinates are in (y, x) image space and returned as floats.
    """
    mask = binary_mask.astype(bool)
    contours = find_contours(mask, level=0.5)
    if not contours:
        return np.array([]), np.array([]), np.array([])

    # Choose the longest contour
    border = max(contours, key=lambda c: c.shape[0])  # shape (N, 2) as (row=y, col=x)

    # Ensure closed path by appending first point if needed
    if not (np.allclose(border[0], border[-1])):
        border = np.vstack([border, border[0]])

    # Parameterize by cumulative arc length
    diffs = np.diff(border, axis=0)
    seg_lengths = np.linalg.norm(diffs, axis=1)
    s = np.concatenate([[0.0], np.cumsum(seg_lengths)])
    if s[-1] == 0:
        # Degenerate
        return np.array([]), np.array([]), np.array([])
    s /= s[-1]

    y_s = border[:, 0]
    x_s = border[:, 1]
    return x_s, y_s, s


def calculate_irregularity_index(binary_mask: np.ndarray) -> Dict[str, object]:
    """
    Area-based border irregularity index.

    Computes the area of concavities by comparing the lesion mask against its
    convex hull, then normalizes by the lesion area. Also reports the most
    significant single concavity area fraction.

    Returns a dict with:
      - overall_irregularity_index: float in [0, 1]
      - most_significant_index: float in [0, 1]
      - feature_areas: list of areas (pixel units) for individual concavities
    """
    # Step 0: Preprocess to mitigate thin hair cuts
    mask = preprocess_lesion(binary_mask)

    lesion_area = float(np.sum(mask > 0))
    if lesion_area == 0:
        return {
            "overall_irregularity_index": 0.0,
            "most_significant_index": 0.0,
            "feature_areas": []
        }

    # Convex hull to capture indentation baseline
    hull = convex_hull_image(mask.astype(bool)).astype(np.uint8)

    # Concavity regions: hull minus original mask
    concavities = (hull > 0) & ~(mask > 0)

    # Label concavities and measure areas
    lbl = label(concavities.astype(np.uint8))
    props = regionprops(lbl)
    feature_areas = [float(p.area) for p in props]

    total_area = float(np.sum(concavities))
    overall_index = total_area / lesion_area
    most_significant = (max(feature_areas) / lesion_area) if feature_areas else 0.0

    return {
        "overall_irregularity_index": float(np.clip(overall_index, 0.0, 1.0)),
        "most_significant_index": float(np.clip(most_significant, 0.0, 1.0)),
        "feature_areas": feature_areas,
    }