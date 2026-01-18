from pathlib import Path
from torch.utils.data import Dataset
import cv2
import torchvision.transforms.functional
from PIL import Image
import numpy as np
import torch

class HAM10000Dataset(Dataset):
    def __init__(self, dataframe, filter_list, transform=None, filter_transform=None):
        """
        Custom Dataset for HAM10000 skin lesion images.

        :param dataframe: Pandas DataFrame containing image paths and labels
        :param filter_list: List of filter names to load.
        :param transform: Optional transformations to be applied on the images
        """
        self.dataframe = dataframe
        self.filter_list = filter_list
        self.transform = transform
        self.filter_transform = filter_transform
        
    def __len__(self):
        return len(self.dataframe)

    def __getitem__(self, idx):
        """
        Retrieve an image and its corresponding label.

        :param idx: Index of the item to retrieve
        :return: Tuple of (image, label)
        """
        features_map = {} # dictionary to hold different features (filter/rgb)

        img_path = self.dataframe.iloc[idx]['image_path']
        pil_image = Image.open(img_path).convert('RGB')

        proj_dir = Path(__file__).resolve().parent.parent.parent
        filtered_path = Path(str(proj_dir) + "/data/filtered")
        filter_dirs = [p.name for p in filtered_path.iterdir() if p.is_dir()]

        for filter in self.filter_list:
            if filter in filter_dirs:
                features_file = np.load(filtered_path / filter / (self.dataframe.iloc[idx]['image_id'] + ".npy"))
                features_tensor = torch.from_numpy(features_file)
                channel_dim = features_tensor.unsqueeze(0).repeat(3, 1, 1)  # replicate to 3 channels
                features_map[filter] = channel_dim
            else:
                raise ValueError(f"No filter_dir for filter '{filter}' found in filtered_path.")

        label = self.dataframe.iloc[idx]['lesion_idx']

        if self.transform:
            image = self.transform(pil_image)
        else:
            image = torchvision.transforms.functional.to_tensor(pil_image)

        features_map['rgb'] = image

        if self.filter_transform:
            for key in features_map:
                if key != 'rgb':
                    features_map[key] = self.filter_transform(features_map[key])

        return features_map, label