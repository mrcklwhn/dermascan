import numpy as np
import cv2

class ImageAsymmetry:

    @staticmethod    
    def create_binary_mask(image: np.ndarray) -> np.ndarray:
        """
        Create a binary mask of the lesion in the image using Otsu's thresholding and
        morphological operations.
        Args:
            image: Input image as a numpy array.
        Returns:
            Binary mask of the lesion.
        """

        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)

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
                    return float('inf')
                cx = int(M["m10"] / M["m00"])
                cy = int(M["m01"] / M["m00"])
                contour_center = np.array([cy, cx])
                distance = np.linalg.norm(contour_center - image_center)
                area = cv2.contourArea(contour)
                return distance - area / 1000  # Adjust weight as needed

            best_contour = min(contours, key=contour_score)
            mask = np.zeros_like(mask)
            cv2.drawContours(mask, [best_contour], -1, 255, thickness=cv2.FILLED)

        return mask

    def compute_centroid(mask: np.ndarray) -> tuple[int, int]:
        """
        Compute the centroid of the binary mask.
        Args:
            mask: Binary mask of the lesion.
            Returns:
            Tuple of (cx, cy) coordinates of the centroid.
        """

        y, x = np.nonzero(mask)
        centroid = (np.mean(x), np.mean(y))
        cx, cy = int(centroid[0]), int(centroid[1])
        return (cx, cy)
    
    def simple_axis_split(mask: np.ndarray, cx: int, cy: int) -> tuple[np.ndarray, np.ndarray, np.ndarray, np.ndarray]:
        """
        Split the mask into quadrants based on centroid.
        Args:
            mask: Binary mask of the lesion.
            cx: X-coordinate of the centroid.
            cy: Y-coordinate of the centroid.
        Returns:
            Tuple of four quadrants: (top_left, top_right, bottom_left, bottom_right).
        """
        h, w = mask.shape
        top_left = mask[0:cy, 0:cx]
        top_right = mask[0:cy, cx:w]
        bottom_left = mask[cy:h, 0:cx]
        bottom_right = mask[cy:h, cx:w]
        return top_left, top_right, bottom_left, bottom_right

    def calculate_quadrant_asymmetry(q1: np.ndarray, q2: np.ndarray) -> float:
        """
        Calculate asymmetry between two quadrants.
        Args:
            q1: First quadrant binary mask.
            q2: Second quadrant binary mask.
        Returns:
            Asymmetry score between the two quadrants ranging from 0 to 1.
        """
        # Resize quadrants to the same size
        h1, w1 = q1.shape
        h2, w2 = q2.shape
        h, w = max(h1, h2), max(w1, w2)
        q1_resized = cv2.resize(q1, (w, h), interpolation=cv2.INTER_NEAREST)
        q2_resized = cv2.resize(q2, (w, h), interpolation=cv2.INTER_NEAREST)

        # Calculate pixel-wise difference
        difference = cv2.absdiff(q1_resized, q2_resized)
        asymmetry_score = np.sum(difference) / (255 * h * w)  # Normalize to [0, 1]

        return asymmetry_score

    @staticmethod
    def calculate_asymmetry(image: np.ndarray) -> float:
        """
        Calculate the asymmetry of the lesion in the image.
        Args:
            image: Input image as a numpy array.
        Returns:
            Asymmetry score of the lesion ranging from 0 to 1.
        """
        
        # Generate binary mask
        mask = ImageAsymmetry.create_binary_mask(image)

        # Compute centroid
        cx, cy = ImageAsymmetry.compute_centroid(mask)

        # Split mask into quadrants
        top_left, top_right, bottom_left, bottom_right = ImageAsymmetry.simple_axis_split(mask, cx, cy)

        # Calculate asymmetry scores
        asymmetry_score_1 = ImageAsymmetry.calculate_quadrant_asymmetry(top_left, bottom_right)
        asymmetry_score_2 = ImageAsymmetry.calculate_quadrant_asymmetry(top_right, bottom_left)
        total_asymmetry_score = (asymmetry_score_1 + asymmetry_score_2) / 2

        return total_asymmetry_score
