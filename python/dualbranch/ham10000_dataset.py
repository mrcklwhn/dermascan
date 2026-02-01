from pathlib import Path
from torch.utils.data import Dataset
import cv2
import torchvision.transforms.functional
from PIL import Image
import numpy as np
import torch

class HAM10000Dataset(Dataset):
    def __init__(self, dataframe, filter_name, data_path, transform=None):
        """
        Custom Dataset for HAM10000 skin lesion images.

        :param dataframe: Pandas DataFrame containing image paths and labels
        :param filter_list: List of filter names to load.
        :param transform: Optional transformations to be applied on the images
        """
        self.dataframe = dataframe
        self.filter_name = filter_name
        self.transform = transform
        self.data_path = data_path
    def __len__(self):
        return len(self.dataframe)

    def __getitem__(self, idx):
        """
        Retrieve an image and its corresponding label.

        :param idx: Index of the item to retrieve
        :return: Tuple of (image, label)
        """
        if self.filter_name == "rgb":
            img_path = self.dataframe.iloc[idx]['image_path']
            pil_image = Image.open(img_path).convert('RGB')

            if self.transform:
                features_tensor = self.transform(pil_image)
            else:
                features_tensor = torchvision.transforms.functional.to_tensor(pil_image)

        else:
            filtered_path = Path(str(self.data_path) + "/filtered")
            filtered_features = np.load(filtered_path / self.filter_name / (self.dataframe.iloc[idx]['image_id'] + ".npy"))
        
            if self.transform:
                features_tensor = self.transform(filtered_features)
            else:
                features_tensor = torch.from_numpy(filtered_features)

        label = self.dataframe.iloc[idx]['lesion_idx']

        return features_tensor, label