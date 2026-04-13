from pathlib import Path
from torch.utils.data import Dataset
import torchvision.transforms.functional
from PIL import Image
import numpy as np
import torch
import pandas as pd

class RGBDatasetLoader(Dataset):
    """
    RGBDatasetLoader is a PyTorch Dataset class responsible for loading RGB images and their corresponding labels from a given DataFrame.
    Each item retrieved from the dataset consists of:
    - An RGB image transformed into a PyTorch tensor.
    - An integer label corresponding to the lesion index.
    """
    def __init__(self, dataframe: pd.DataFrame, transforms=None):
        """
        Initializes the RGBDatasetLoader with a DataFrame containing image paths and labels.

        Args:
            dataframe (pd.DataFrame): A DataFrame containing the image paths and labels.
            transforms (callable, optional): A function/transform to apply to the images.
        """
        self.dataframe = dataframe
        self.transform = transforms

    def __len__(self):
        return len(self.dataframe)

    def __getitem__(self, idx) -> tuple[torch.Tensor, int]:
        """
        Retrieves the RGB image and its corresponding label for the given index.

        Args:
            idx (int): The index of the item to retrieve.
        Returns:
            tuple[torch.Tensor, int]: A tuple containing the RGB image as a PyTorch tensor and the corresponding label as an integer.
        """
        img_path = self.dataframe.iloc[idx]['image_path']
        pil_image = Image.open(img_path).convert('RGB')

        if self.transform:
            features_tensor = self.transform(pil_image)
        else:
            features_tensor = torchvision.transforms.functional.to_tensor(pil_image)

        label = self.dataframe.iloc[idx]['lesion_idx']

        return features_tensor, label