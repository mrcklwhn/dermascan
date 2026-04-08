from pathlib import Path
from torch.utils.data import Dataset
import torchvision.transforms.functional
from PIL import Image
import numpy as np
import torch
import pandas as pd

class RGBDatasetLoader(Dataset):
    def __init__(self, dataframe: pd.DataFrame, transforms=None):
        """
        Custom Dataset for HAM10000 skin lesion images.

        Args:
            dataframe: Pandas DataFrame containing image paths and labels
            transform: Optional transformations to be applied on the images
        """
        self.dataframe = dataframe
        self.transform = transforms
    def __len__(self):
        return len(self.dataframe)

    def __getitem__(self, idx) -> tuple[torch.Tensor, int]:
        """
        Retrieve an image and its corresponding label.

        Args:
            idx: Index of the item to retrieve
        Returns:
            - image: Tensor of image features
            - label: Integer label of the image (lesion index)
        """
        img_path = self.dataframe.iloc[idx]['image_path']
        pil_image = Image.open(img_path).convert('RGB')

        if self.transform:
            features_tensor = self.transform(pil_image)
        else:
            features_tensor = torchvision.transforms.functional.to_tensor(pil_image)

        label = self.dataframe.iloc[idx]['lesion_idx']

        return features_tensor, label