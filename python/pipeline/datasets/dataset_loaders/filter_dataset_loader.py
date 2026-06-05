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

    def __init__(
        self, dataframe: pd.DataFrame, filter_type: FilterType, data_path: Path, augmentations: A.Compose | None = None
    ):
        """
        Initializes the FilterDatasetLoader with a DataFrame containing image IDs and labels, a filter type, and a data path.

        Args:
            dataframe (pd.DataFrame): A DataFrame containing the image IDs and labels.
            filter_type (FilterType): The type of filter applied to the features, which determines the subdirectory from which to load the .npy files.
            data_path (Path): The path to the data directory.
            augmentations (A.Compose | None, optional): A composed augmentation transform to be applied to the dataset items. Defaults to None.
        """
        self.dataframe = dataframe
        self.filter_name = filter_type.filter_name
        self.expected_channels = filter_type.num_channels
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
        filtered_features = np.load(filtered_path / self.filter_name / (self.dataframe.iloc[idx]["image_id"] + ".npy"))
        # Convert CHW to HWC if channels are first
        if filtered_features.shape[0] == self.expected_channels:
            filtered_features_hwc = np.moveaxis(filtered_features, 0, -1)
        else:
            filtered_features_hwc = filtered_features

        if self.augmentations:
            augmented = self.augmentations(image=filtered_features_hwc)
            features_tensor = augmented["image"]
        else:
            filtered_features_chw = np.moveaxis(filtered_features_hwc, -1, 0)
            features_tensor = torch.from_numpy(filtered_features_chw)

        label = self.dataframe.iloc[idx]["lesion_idx"]

        return features_tensor, label
