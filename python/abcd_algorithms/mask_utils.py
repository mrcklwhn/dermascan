import numpy as np
import cv2
from skimage.measure import regionprops, label
from skimage.measure._regionprops import RegionProperties


def create_simple_binary_mask(image: np.ndarray) -> np.ndarray:
    """
    Create a binary mask of the lesion in the image using Otsu's thresholding and
    morphological operations.
    Args:
        image: Input image as a numpy array.
    Returns:
        Binary mask of the lesion.
    """

    gray = cv2.cvtColor(image, cv2.COLOR_RGB2GRAY)

    # Otsu's thresholding
    _, mask = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)

    # Invert mask so the lesion is white
    mask = cv2.bitwise_not(mask)

    # Morphological operations to clean up the mask
    kernel = np.ones((5, 5), np.uint8)
    mask = cv2.morphologyEx(mask, cv2.MORPH_CLOSE, kernel)
    mask = cv2.morphologyEx(mask, cv2.MORPH_OPEN, kernel)

    # Find contours and keep the largest one that is most central
    contours, _ = cv2.findContours(mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    if contours:
        image_center = np.array(image.shape[:2]) / 2

        def contour_score(contour):
            M = cv2.moments(contour)
            if M["m00"] == 0:
                return float("inf")
            cx = M["m10"] / M["m00"]
            cy = M["m01"] / M["m00"]
            contour_center = np.array([cy, cx])
            distance = np.linalg.norm(contour_center - image_center)
            area = cv2.contourArea(contour)
            return distance - area / 1000  # Adjust weight as needed

        best_contour = min(contours, key=contour_score)
        mask = np.zeros_like(mask)
        cv2.drawContours(mask, [best_contour], -1, 255, thickness=cv2.FILLED)

    return mask


def boundary_extraction(binary_mask: np.ndarray) -> np.ndarray:
    """
    Extract the boundary; outer most edge of the lesion mask.
    Args:
        binary_mask: Binary mask as a numpy array.
    Returns:
        Binary mask of the boundary (outline).
    """

    contour = cv2.dilate(binary_mask, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (3, 3)), iterations=2) - binary_mask

    return contour


def compute_centroid(binary_mask: np.ndarray) -> tuple[int, int]:
    """
    Compute the centroid of the binary mask.
    Args:
        binary_mask: Binary mask of the lesion.
    Returns:
        Tuple of (cx, cy) coordinates of the centroid.
    """

    y, x = np.nonzero(binary_mask)
    centroid = (np.mean(x), np.mean(y))
    cx, cy = int(centroid[0]), int(centroid[1])
    return (cx, cy)


def simple_axis_split(
    binary_mask: np.ndarray, cx: int, cy: int
) -> tuple[np.ndarray, np.ndarray, np.ndarray, np.ndarray]:
    """
    Split the binary mask into quadrants based on centroid.
    Args:
        binary_mask: Binary mask of the lesion.
        cx: X-coordinate of the centroid.
        cy: Y-coordinate of the centroid.
    Returns:
        Tuple of four quadrants: (top_left, top_right, bottom_left, bottom_right).
    """
    h, w = binary_mask.shape
    top_left = binary_mask[0:cy, 0:cx]
    top_right = binary_mask[0:cy, cx:w]
    bottom_left = binary_mask[cy:h, 0:cx]
    bottom_right = binary_mask[cy:h, cx:w]
    return top_left, top_right, bottom_left, bottom_right


def get_largest_region_skimage(binary_mask: np.ndarray) -> RegionProperties:
    """
    Get the largest connected region from a binary mask using scikit-image.
    Args:
        binary_mask: Binary mask as a numpy array.
    Returns:
        The largest connected region as a binary mask.
    """
    if not np.any(binary_mask):
        raise ValueError("No regions found in the binary mask.")

    labeled = label(binary_mask)
    regions = regionprops(labeled)

    largest_region = max(regions, key=lambda r: r.area)

    return largest_region


def rotate_mask_to_principal_axis(
    binary_mask: np.ndarray, preserve_original_dimensions: bool = False
) -> tuple[np.ndarray, float]:
    """
    Rotate a binary mask to align its principal axis (major axis) vertically.

    Args:
        binary_mask: Binary mask as a numpy array.
        preserve_original_dimensions: Whether to clip the rotated mask to original dimensions.
    Returns:
        - rotated_mask: The mask rotated so its major axis is vertical
        - angle_degrees: The rotation angle applied in degrees
    """
    import math

    M = cv2.moments(binary_mask.astype(np.uint8))
    if M["m00"] == 0:
        return binary_mask, 0.0

    angle_rad = 0.5 * math.atan2(2 * M["mu11"], M["mu20"] - M["mu02"])
    angle_degrees = math.degrees(angle_rad)

    cx = int(M["m10"] / M["m00"])
    cy = int(M["m01"] / M["m00"])

    rot_mat = cv2.getRotationMatrix2D((cx, cy), angle_degrees, 1.0)

    cos_a = abs(rot_mat[0, 0])
    sin_a = abs(rot_mat[0, 1])

    new_width = int(np.ceil(binary_mask.shape[0] * sin_a + binary_mask.shape[1] * cos_a))
    new_height = int(np.ceil(binary_mask.shape[0] * cos_a + binary_mask.shape[1] * sin_a))

    if new_width % 2 != 0:
        new_width += 1
    if new_height % 2 != 0:
        new_height += 1

    tx = rot_mat[0, 2] + (new_width / 2.0) - cx
    ty = rot_mat[1, 2] + (new_height / 2.0) - cy
    rot_mat[0, 2] = tx
    rot_mat[1, 2] = ty

    rotated_mask = cv2.warpAffine(binary_mask.astype(np.uint8), rot_mat, (new_width, new_height))

    return rotated_mask, angle_degrees
