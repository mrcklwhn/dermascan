import cv2
from skimage import io, color, filters
import numpy as np
from skimage.feature import local_binary_pattern, graycomatrix, graycoprops
from pathlib import Path

class FilterService:

    TEXTURE_FILTERS = ['gabor_filter', 'lbp_filter', 'glcm_filter']
    
    def __init__(self, data_dir, raw_images='raw', filtered_output_dir='filtered'):
        self.data_dir = Path(data_dir)
        self.images_dir = self.data_dir / raw_images
        self.filtered_output_dir = self.data_dir / filtered_output_dir
        self._filters_maps = {
            name: getattr(self, f"_{name}") for name in self.TEXTURE_FILTERS
        }

    def _gabor_filter(self, image_gray, frequency=0.6, theta=0):
        """Apply Gabor wavelet filter to grayscale image."""
        gabor_real, gabor_imag = filters.gabor(image_gray, frequency=frequency, theta=theta)
        # Combine real and imaginary parts for magnitude
        gabor_magnitude = np.sqrt(gabor_real**2 + gabor_imag**2)
        return gabor_magnitude

    def _lbp_filter(self, image_gray, radius=3, n_points=24):
        """Apply Local Binary Pattern filter to grayscale image."""
        # Convert float [0,1] to uint8 [0,255]
        if image_gray.dtype != np.uint8:
            image_gray = (image_gray * 255).astype(np.uint8)

        lbp = local_binary_pattern(image_gray, n_points, radius, method='uniform')
        return lbp

    def _glcm_filter(self, image_gray, window_size=7):
        """
        Apply GLCM-based texture visualization.
        Creates a texture map based on local GLCM properties.
        """

        # Ensure image is float for calculations
        img = image_gray.astype(np.float32)
        
        # 1. Calculate Squared Differences for 4 directions (vectorized)
        # 0 degrees (Horizontal)
        diff_0 = (img[:, :-1] - img[:, 1:]) ** 2
        # 90 degrees (Vertical)
        diff_90 = (img[:-1, :] - img[1:, :]) ** 2
        # 45 degrees (Diagonal)
        diff_45 = (img[:-1, :-1] - img[1:, 1:]) ** 2
        # 135 degrees (Anti-Diagonal)
        diff_135 = (img[:-1, 1:] - img[1:, :-1]) ** 2

        # Pad results to match original size (lost 1 pixel at borders)
        h, w = img.shape
        map_0 = cv2.resize(diff_0, (w, h))
        map_90 = cv2.resize(diff_90, (w, h))
        map_45 = cv2.resize(diff_45, (w, h))
        map_135 = cv2.resize(diff_135, (w, h))

        # 2. Average the difference maps to get "Raw Contrast"
        avg_diff = (map_0 + map_90 + map_45 + map_135) / 4.0

        # 3. Apply Local Averaging (Smoothing) equivalent to Sliding Window
        # This replaces the loop: summing values inside the window
        kernel = np.ones((window_size, window_size), np.float32) / (window_size**2)
        contrast_map = cv2.filter2D(avg_diff, -1, kernel)

        # Normalize to 0-255 range for visualization/saving
        contrast_map = cv2.normalize(contrast_map, None, 0, 255, cv2.NORM_MINMAX)
        
        return contrast_map.astype(np.uint8)
    
    def apply_texture_filters(self, image_id, filter_list=None, **kwargs):
        """Apply specified texture filters to the image.

        :param filter_list: List of filter names to apply.
        :param kwargs: filter params
        """
        if filter_list is None:
            filter_list = self.TEXTURE_FILTERS

        image_path = Path(self.images_dir) / (image_id + ".jpg")
        image_gray = io.imread(image_path, as_gray=True)

        filters_result_dict = {}
        for filter_name in filter_list:
            if filter_name in self._filters_maps:
                filter_func = self._filters_maps[filter_name]
                filters_result_dict[filter_name] = filter_func(image_gray, **kwargs)
            else:
                raise ValueError(f"Filter '{filter_name}' is not recognized.")
            
        return filters_result_dict
    
    def apply_texture_filters_batch(self, list_image_ids, filter_list=None, stop_on_error=True, **kwargs):
        """
        Docstring for apply_texture_filters_batch
        
        :param image_ids: List of Image Ids
        :param filter_list: List of filter names to apply.
        :param kwargs: filter params
        """
        if filter_list is None:
            filter_list = self.TEXTURE_FILTERS

        filters_results_map = {}

        for image_id in list_image_ids:
            try:
                filters_result_dict = self.apply_texture_filters(image_id, filter_list, **kwargs)
                filters_results_map.update({image_id: filters_result_dict})
            except Exception as e:
                print(f"Error processing {image_id}: {str(e)}")
                filters_results_map[image_id] = None

                if stop_on_error: 
                    raise

        return filters_results_map
    
    def save_applied_filters(self, filters_result_dict, image_id, output_dir=None, separate=False):
        """Save the applied filters result to a compressed .npz file. Use np.stack to stack the arrays if needed.
        :param filters_result_dict: Dictionary of filter results for one image
        """
        if output_dir is None:
            output_dir = self.filtered_output_dir

        # make sure dir exists else create
        output_dir.mkdir(parents=True, exist_ok=True)

        # Save each filter result separately or together
        if separate:
            for filter_name, filter_result in filters_result_dict.items():
                filter_output_dir = Path(output_dir) / f"{filter_name}"
                filter_output_dir.mkdir(parents=True, exist_ok=True)
                filename = Path(output_dir) / f"{filter_name}" / (image_id + ".npy")
                np.save(filename, filter_result)
        else:
            filename = Path(output_dir) / (image_id + ".npz")
            np.savez_compressed(filename, **filters_result_dict)

    def save_applied_filters_batch(self, filters_results_map, output_dir=None, separate=False):
        """Save the applied filters results for a batch of images.
        :param filters_results_map: Dictionary mapping image IDs to their filter results
        """
        for image_id, filters_result_dict in filters_results_map.items():
            if filters_result_dict is not None:
                self.save_applied_filters(filters_result_dict, image_id, output_dir, separate)

    def batch_generator(self, list_image_ids, batch_size=32):
        """Generator that yields images in batches.
        
        :param list_image_ids: List of image IDs to process
        :param batch_size: Number of images per batch
        """
        batch_ids = []
        
        for image_id in list_image_ids:
            batch_ids.append(image_id)

            if len(batch_ids) == batch_size:
                yield batch_ids
                batch_ids = []
        
        if batch_ids:
            yield batch_ids

    def filtered_image_generator(self, list_image_ids, filter_list=None, batch_size=32, output_dir=None, separate=False, **kwargs):
        """Generator that applies and saves filtered images in batches.
        
        :param list_image_ids: List of image IDs to process
        :param filter_list: List of filter names to apply.
        :param batch_size: Number of images per batch
        :param separate: Whether to save each filter result in separate folder
        :param kwargs: filter params
        """
        progress_counter = 0
        for batch_ids in self.batch_generator(list_image_ids, batch_size):
            filters_results_map = self.apply_texture_filters_batch(
                batch_ids, filter_list=filter_list, **kwargs
            )
            self.save_applied_filters_batch(filters_results_map, output_dir, separate)
            progress_counter += len(batch_ids)
            print(f"Processed {progress_counter} / {len(list_image_ids)} images.")

        