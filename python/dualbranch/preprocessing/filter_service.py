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
    
    def _gabor_filter(self, image_gray):
        """Apply Gabor filter bank and aggregate responses."""
        frequencies = [0.1, 0.3, 0.6]
        thetas = [0, np.pi/4, np.pi/2, 3*np.pi/4]
        
        responses = []
        for freq in frequencies:
            for theta in thetas:
                real, imag = filters.gabor(image_gray, frequency=freq, theta=theta)
                magnitude = np.sqrt(real**2 + imag**2)
                responses.append(magnitude)
        
        # Aggregate (e.g., mean or max across all filters)
        gabor_map = np.mean(responses, axis=0)
        
        # Normalize to [0, 1]
        normalized = self.minmax_normalize_filtered_image(gabor_map)
        return normalized

    def _lbp_filter(self, image_gray, radius=3, n_points=24):
        """Apply Local Binary Pattern filter to grayscale image."""
        # Convert to uint8 safely
        if image_gray.dtype != np.uint8:
            img = image_gray.astype(np.float32)
            if img.max() <= 1.0:
                img *= 255.0
            image_gray = np.clip(img, 0, 255).astype(np.uint8)
        
        lbp = local_binary_pattern(image_gray, n_points, radius, method='uniform')
        
        # Normalize correctly: uniform LBP range is [0, n_points+2]
        normalized_lbp = lbp.astype(np.float32) / (n_points + 2)
        
        return normalized_lbp

    def _glcm_filter(
        self,
        image_gray,               # float [0,1] or uint8 [0,255]
        win=21,                   # patch size
        stride=8,                 # grid stride
        levels=32,                # quantization levels
        distances=(1, 2),         # offsets
        angles=(0, np.pi/4, np.pi/2, 3*np.pi/4),
    ):
        """Apply GLCM contrast filter to grayscale image."""
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
                patch = qpad[y:y+win, x:x+win]

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
        
        # 5) Normalize to [0,1] - this happens during preprocessing
        mn, mx = float(full.min()), float(full.max())
        full01 = (full - mn) / (mx - mn + 1e-8)

        return full01
    
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
    
    def save_applied_filters(self, filters_result_dict, image_id, output_dir=None, asnpz=False):
        """Save the applied filters result in filtered_output_dir or to a compressed .npz file. Use np.stack to stack the arrays if needed.
        :param filters_result_dict: Dictionary of filter results for one image
        :param asnpz: Whether to save each filter result as one npz file
        """
        if output_dir is None:
            output_dir = self.filtered_output_dir

        # make sure dir exists else create
        output_dir.mkdir(parents=True, exist_ok=True)

        # Save each filter result together as npz or separately
        if asnpz:
            filename = Path(output_dir) / (image_id + ".npz")
            np.savez_compressed(filename, **filters_result_dict)
        else:
            for filter_name, filter_result in filters_result_dict.items():
                filter_output_dir = Path(output_dir) / f"{filter_name}"
                filter_output_dir.mkdir(parents=True, exist_ok=True)
                filename = Path(output_dir) / f"{filter_name}" / (image_id + ".npy")
                np.save(filename, filter_result)
            

    def save_applied_filters_batch(self, filters_results_map, output_dir=None, asnpz=False):
        """Save the applied filters results for a batch of images.
        :param filters_results_map: Dictionary mapping image IDs to their filter results
        """
        for image_id, filters_result_dict in filters_results_map.items():
            if filters_result_dict is not None:
                self.save_applied_filters(filters_result_dict, image_id, output_dir, asnpz)

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

    def filtered_image_generator(self, list_image_ids, filter_list=None, batch_size=32, output_dir=None, asnpz=False, **kwargs):
        """Generator that applies and saves filtered images in batches.
        
        :param list_image_ids: List of image IDs to process
        :param filter_list: List of filter names to apply.
        :param batch_size: Number of images per batch
        :param asnpz: Whether to save each filter result as one npz file
        :param kwargs: filter params
        """
        progress_counter = 0
        for batch_ids in self.batch_generator(list_image_ids, batch_size):
            filters_results_map = self.apply_texture_filters_batch(
                batch_ids, filter_list=filter_list, **kwargs
            )
            self.save_applied_filters_batch(filters_results_map, output_dir, asnpz)
            progress_counter += len(batch_ids)
            print(f"Processed {progress_counter} / {len(list_image_ids)} images.")

    def minmax_normalize_filtered_image(self, image):
        """Normalize filtered image to [0, 1] range."""
        image_min, image_max = image.min(), image.max()
        if image_max - image_min > 1e-8:
            normalized_image = (image - image_min) / (image_max - image_min)
        else:
            normalized_image = np.zeros_like(image)
        return np.float32(normalized_image)
