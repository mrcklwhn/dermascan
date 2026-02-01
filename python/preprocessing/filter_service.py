from skimage import io
import numpy as np
from pathlib import Path

class FilterService:
    
    def __init__(self, data_dir, raw_images='raw', filtered_output_dir='filtered'):
        self.data_dir = Path(data_dir)
        self.images_dir = self.data_dir / raw_images
        self.filtered_output_dir = self.data_dir / filtered_output_dir
    
    def apply_texture_filters(self, image_id, filter_list: list[callable], **kwargs):
        """Apply specified texture filters to the image.

        :param filter_list: List of filter names to apply.
        :param kwargs: filter params
        """

        image_path = Path(self.images_dir) / (image_id + ".jpg")
        image_gray = io.imread(image_path, as_gray=True)

        filters_result_dict = {}
        for filter_name in filter_list:
            try:
                filters_result_dict[filter_name.__name__] = filter_name(image_gray, **kwargs)
            except Exception as e:
                raise RuntimeError(f"Error applying filter '{filter_name.__name__}' to image '{image_id}': {str(e)}")
            
        return filters_result_dict
    
    def apply_texture_filters_batch(self, list_image_ids, filter_list: list[callable], stop_on_error=True, **kwargs):
        """
        Docstring for apply_texture_filters_batch
        
        :param image_ids: List of Image Ids
        :param filter_list: List of filter names to apply.
        :param kwargs: filter params
        """

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