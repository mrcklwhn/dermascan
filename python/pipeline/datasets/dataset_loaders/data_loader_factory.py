from pandas import DataFrame
import torch
from torch.utils.data import DataLoader
from pathlib import Path

from pipeline.dataclasses.enums import AugmentationType, DatasetLoaderType, FilterType
from pipeline.dataclasses.pipeline_runtime import TrainValTestDataLoaders, TrainValTestSplit

from pipeline.datasets.dataset_loaders.rgb_dataset_loader import RGBDatasetLoader
from pipeline.datasets.dataset_loaders.filter_dataset_loader import FilterDatasetLoader

class DataLoaderFactory:
    """
    DataLoaderFactory is a factory class responsible for creating PyTorch DataLoader instances for training, validation, and testing datasets based on the specified dataset loader type and filter type.
    It supports two types of dataset loaders:
    - RGBDatasetLoader: Loads RGB images and their corresponding labels from a DataFrame.
    - FilterDatasetLoader: Loads filtered features from .npy files and their corresponding labels from a DataFrame.
    """
    # defaults
    _NUM_WORKERS: int = 4
    _PIN_MEMORY: bool = torch.cuda.is_available()
    _PREFETCH_FACTOR: int = 2
    _PERSISTENT_WORKERS: bool = True

    @staticmethod
    def build(dataset_loader_type: DatasetLoaderType,
              filter_type: FilterType,
              df_split: TrainValTestSplit,
              filtered_data_path: Path,
              batch_size: int,
              augmentation: list[AugmentationType]) -> TrainValTestDataLoaders:
        """
        Builds PyTorch DataLoader instances for training, validation, and testing datasets based on the specified dataset loader type and filter type.

        Args:
            dataset_loader_type (DatasetLoaderType): The type of dataset loader to use (RGB or Filter).
            filter_type (FilterType): The type of filter to apply (only relevant for FilterDatasetLoader).
            df_split (TrainValTestSplit): A dataclass containing the train, validation, and test DataFrames.
            filtered_data_path (Path): The path to the directory containing filtered .npy files (only relevant for FilterDatasetLoader).
            batch_size (int): The batch size for the DataLoader.
            augmentation (list[AugmentationType]): A list of augmentations to apply to the dataset.

        Returns:
            TrainValTestDataLoaders: A dataclass containing the train, validation, and test DataLoader instances.
        """

        # transforms = DataLoaderFactory._get_transforms(augmentation)

        def make_loader(ids_df: DataFrame, shuffle: bool) -> DataLoader:
            """
            Inner function to create a DatasetLoader and wrap it in a DataLoader.

            Args:
                ids_df (DataFrame): The DataFrame containing the image IDs and labels for the dataset split.
                shuffle (bool): Whether to shuffle the dataset (typically True for training and False for validation/test).
            Returns:
                DataLoader: A PyTorch DataLoader instance for the specified dataset split.
            """
            dataset = DataLoaderFactory._build_dataset(dataset_loader_type, ids_df, filter_type, filtered_data_path)
            return DataLoader(
                dataset,
                batch_size=batch_size,
                shuffle=shuffle,
                num_workers=DataLoaderFactory._NUM_WORKERS,
                pin_memory=DataLoaderFactory._PIN_MEMORY,
                prefetch_factor=DataLoaderFactory._PREFETCH_FACTOR,
                persistent_workers=DataLoaderFactory._PERSISTENT_WORKERS
            )
        
        return TrainValTestDataLoaders(
            train_loader=make_loader(df_split.train_df, shuffle=True),
            val_loader=make_loader(df_split.val_df, shuffle=False),
            test_loader=make_loader(df_split.test_df, shuffle=False)
        )
        
    @staticmethod
    def _build_dataset(dataset_loader_type: DatasetLoaderType,
                       ids_df: DataFrame,
                       filter_type: FilterType,
                       data_path: Path,
                       transforms=None):
        """
        Builds a DatasetLoader instance based on the specified dataset loader type and filter type.

        Args:
            dataset_loader_type (DatasetLoaderType): The type of dataset loader to use (RGB or Filter).
            ids_df (DataFrame): The DataFrame containing the image IDs and labels for the dataset split.
            filter_type (FilterType): The type of filter to apply (only relevant for FilterDatasetLoader).
            data_path (Path): The path to the directory containing filtered .npy files (only relevant for FilterDatasetLoader).
            transforms (callable, optional): A function/transform to apply to the dataset items.
        Returns:
            Dataset: A PyTorch Dataset instance for the specified dataset split.
        """
        match dataset_loader_type:
            case DatasetLoaderType.RGB:
                return RGBDatasetLoader(dataframe=ids_df,
                                  transforms=transforms)
            case DatasetLoaderType.FILTER:
                return FilterDatasetLoader(dataframe=ids_df,
                                           filter_type=filter_type,
                                           data_path=data_path,
                                           transforms=transforms)