from pathlib import Path
from torch.utils.data import Dataset
import numpy as np
import torch
import pandas as pd
import albumentations as A

from pipeline.dataclasses.enums import FilterType

class FilterDatasetLoader(Dataset):
    """
    FilterDatasetLoader is a PyTorch Dataset class responsible for loading filtered features and their corresponding labels from a given DataFrame.
    Each item retrieved from the dataset consists of:
    - A tensor of filtered features loaded from a .npy file corresponding to the image.
    - An integer label corresponding to the lesion index.
    """
    def __init__(self, dataframe: pd.DataFrame,
                    filter_type: FilterType,
                    data_path: Path,
                    augmentations: A.Compose = None):
        """
        Initializes the FilterDatasetLoader with a DataFrame containing image IDs and labels, a filter type, and a data path.

        Args:
            dataframe (pd.DataFrame): A DataFrame containing the image IDs and labels.
            filter_type (FilterType): The type of filter applied to the features, which determines the subdirectory from which to load the .npy files.
            data_path (Path): The path to the data directory.
        """
        self.dataframe = dataframe
        self.filter_name = filter_type.filter_name
        self.data_path = data_path
        self.augmentations = augmentations

    def __len__(self):
        return len(self.dataframe)

    def __getitem__(self, idx) -> tuple[torch.Tensor, int]:
        """
        Retrieves the filtered features and their corresponding label for the given index.

        Args:
            idx: Index of the item to retrieve
        Returns:
            - image: Tensor of image features
            - label: Integer label of the image (lesion index)
        """
        filtered_path = Path(str(self.data_path) + "/filtered")
        filtered_features = np.load(filtered_path / self.filter_name / (self.dataframe.iloc[idx]['image_id'] + ".npy"))

        if self.augmentations:
            augmented = self.augmentations(image=filtered_features)
            features_tensor = augmented['image']
        else:
            features_tensor = torch.from_numpy(filtered_features)

        label = self.dataframe.iloc[idx]['lesion_idx']

        return features_tensor, label