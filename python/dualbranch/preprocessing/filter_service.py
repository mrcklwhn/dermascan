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
        lbp = local_binary_pattern(image_gray, n_points, radius, method='uniform')
        return lbp

    def _glcm_filter(self, image_gray, distances=[1], angles=[0, np.pi/4, np.pi/2, 3*np.pi/4]):
        """
        Apply GLCM-based texture visualization.
        Creates a texture map based on local GLCM properties.
        """
        # Normalize and convert to uint8 for GLCM
        image_uint8 = ((image_gray - image_gray.min()) / 
                       (image_gray.max() - image_gray.min()) * 255).astype(np.uint8)
        
        # Compute GLCM-based texture map using sliding window approach
        window_size = 15
        half_win = window_size // 2
        
        # Pad the image
        padded = np.pad(image_uint8, half_win, mode='reflect')
        
        # Create output texture map (using contrast as the texture measure)
        texture_map = np.zeros_like(image_gray)
        
        # Sample every few pixels for efficiency, then interpolate
        step = 3
        for i in range(0, image_gray.shape[0], step):
            for j in range(0, image_gray.shape[1], step):
                window = padded[i:i+window_size, j:j+window_size]
                # Reduce levels for faster computation
                window_reduced = (window // 16).astype(np.uint8)
                glcm = graycomatrix(window_reduced, distances, angles, 
                                   levels=16, symmetric=True, normed=True)
                contrast_values = graycoprops(glcm, 'contrast')
                contrast = np.mean(contrast_values)
                # Fill the step x step region
                end_i = min(i + step, image_gray.shape[0])
                end_j = min(j + step, image_gray.shape[1])
                texture_map[i:end_i, j:end_j] = contrast
        
        return texture_map
    
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
    
    def save_applied_filters(self, filters_result_dict, image_id, output_dir=None):
        """Save the applied filters result to a compressed .npz file. Use np.stack to stack the arrays if needed.
        :param filters_result_dict: Dictionary of filter results for one image
        """
        if output_dir is None:
            output_dir = self.filtered_output_dir

        output_dir.mkdir(parents=True, exist_ok=True)

        filename = Path(output_dir) / (image_id + ".npz")
        np.savez_compressed(filename, **filters_result_dict)

    def save_applied_filters_batch(self, filters_results_map, output_dir=None):
        """Save the applied filters results for a batch of images.
        :param filters_results_map: Dictionary mapping image IDs to their filter results
        """
        for image_id, filters_result_dict in filters_results_map.items():
            if filters_result_dict is not None:
                self.save_applied_filters(filters_result_dict, image_id, output_dir)

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

    def filtered_image_generator(self, list_image_ids, filter_list=None, batch_size=32, **kwargs):
        """Generator that applies and saves filtered images in batches.
        
        :param list_image_ids: List of image IDs to process
        :param filter_list: List of filter names to apply.
        :param batch_size: Number of images per batch
        :param kwargs: filter params
        """
        progress_counter = 0
        for batch_ids in self.batch_generator(list_image_ids, batch_size):
            filters_results_map = self.apply_texture_filters_batch(
                batch_ids, filter_list=filter_list, **kwargs
            )
            self.save_applied_filters_batch(filters_results_map)
            progress_counter += len(batch_ids)
            print(f"Processed {progress_counter} / {len(list_image_ids)} images.")

        