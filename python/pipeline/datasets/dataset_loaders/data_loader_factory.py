from pandas import DataFrame
import torch
import numpy as np
from torch.utils.data import DataLoader, Dataset
from pathlib import Path
import albumentations as A
import random

from pipeline.dataclasses.enums import DatasetLoaderType, FilterType
from pipeline.dataclasses.pipeline_config import AugmentationConfig
from pipeline.dataclasses.pipeline_runtime import TrainValTestDataLoaders, TrainValTestSplit

from pipeline.datasets.dataset_loaders.rgb_dataset_loader import RGBDatasetLoader
from pipeline.datasets.dataset_loaders.filter_dataset_loader import FilterDatasetLoader
from pipeline.datasets.dataset_loaders.augmentation_builder import AugmentationBuilder

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
              sampler_weights: tuple[float, float] | None = None,
              augmentation: AugmentationConfig | None = None,
              seed: int | None = None) -> TrainValTestDataLoaders:
        """
        Builds PyTorch DataLoader instances for training, validation, and testing datasets based on the specified dataset loader type and filter type.

        Args:
            dataset_loader_type (DatasetLoaderType): The type of dataset loader to use (RGB or Filter).
            filter_type (FilterType): The type of filter to apply (only relevant for FilterDatasetLoader).
            df_split (TrainValTestSplit): A dataclass containing the train, validation, and test DataFrames.
            filtered_data_path (Path): The path to the directory containing filtered .npy files (only relevant for FilterDatasetLoader).
            batch_size (int): The batch size for the DataLoader.
            sampler_weights (tuple[float, float] | None): Weights for WeightedRandomSampler (class_0_weight, class_1_weight). If None, shuffle=True is used instead.
            augmentation (AugmentationConfig): A dataclass containing the train and validation augmentations.
            seed (int | None): The seed for reproducibility.

        Returns:
            TrainValTestDataLoaders: A dataclass containing the train, validation, and test DataLoader instances.
        """

        if augmentation:
            train_augmentations = AugmentationBuilder.build(filter_type, augmentation.train, seed)
            val_augmentations = AugmentationBuilder.build(filter_type, augmentation.val, seed)
            test_augmentations = AugmentationBuilder.build(filter_type, [], seed)  # only apply normalization to test set if using filter dataset loader
        else:
            train_augmentations = None
            val_augmentations = None
            test_augmentations = None

        def make_loader(ids_df: DataFrame, sampler_weights: tuple[float, float] | None, shuffle: bool, augmentations: A.Compose | None = None, seed: int | None = None) -> DataLoader:
            """
            Inner function to create a DatasetLoader and wrap it in a DataLoader.

            Args:
                ids_df (DataFrame): The DataFrame containing the image IDs and labels for the dataset split.
                shuffle (bool): Whether to shuffle the dataset (typically True for training and False for validation/test).
                augmentations (A.Compose, optional): A composed augmentation transform to be applied to the dataset items. Defaults to None.
                seed (int | None): The seed for reproducibility.
            Returns:
                DataLoader: A PyTorch DataLoader instance for the specified dataset split.
            """
            def worker_init(worker_id):
                if seed is not None:
                    torch.manual_seed(seed)
                    np.random.seed(seed)
                    random.seed(seed)
                    np.random.seed(seed)
                    torch.manual_seed(seed)
                    if torch.cuda.is_available():
                        torch.cuda.manual_seed_all(seed)

            dataset = DataLoaderFactory._build_dataset(dataset_loader_type, ids_df, filter_type, filtered_data_path, augmentations)
            # if sampler is True shuffle must be False
            weighted_sampler = DataLoaderFactory._build_weighted_sampler(ids_df, sampler_weights) if sampler_weights is not None and not shuffle else None

            generator = None
            if seed is not None:
                generator = torch.Generator()
                generator.manual_seed(seed)

            return DataLoader(
                dataset,
                batch_size=batch_size,
                sampler=weighted_sampler,
                shuffle=shuffle,
                num_workers=DataLoaderFactory._NUM_WORKERS,
                pin_memory=DataLoaderFactory._PIN_MEMORY,
                prefetch_factor=DataLoaderFactory._PREFETCH_FACTOR,
                persistent_workers=DataLoaderFactory._PERSISTENT_WORKERS,
                worker_init_fn=worker_init if seed is not None else None,
                generator=generator
            )
        
        return TrainValTestDataLoaders(
            train_loader=make_loader(df_split.train_df, sampler_weights=sampler_weights, shuffle=sampler_weights is None, augmentations=train_augmentations, seed=seed),
            val_loader=make_loader(df_split.val_df, sampler_weights=None, shuffle=False, augmentations=val_augmentations, seed=seed),
            test_loader=make_loader(df_split.test_df, sampler_weights=None, shuffle=False, augmentations=test_augmentations, seed=seed)
        )
        
    @staticmethod
    def _build_dataset(dataset_loader_type: DatasetLoaderType,
                       ids_df: DataFrame,
                       filter_type: FilterType,
                       data_path: Path,
                       augmentations: A.Compose = None) -> Dataset:
        """
        Builds a DatasetLoader instance based on the specified dataset loader type and filter type.

        Args:
            dataset_loader_type (DatasetLoaderType): The type of dataset loader to use (RGB or Filter).
            ids_df (DataFrame): The DataFrame containing the image IDs and labels for the dataset split.
            filter_type (FilterType): The type of filter to apply (only relevant for FilterDatasetLoader).
            data_path (Path): The path to the directory containing filtered .npy files (only relevant for FilterDatasetLoader).
            augmentations (A.Compose, optional): A composed augmentation transform to be applied to the dataset items. Defaults to None.
        Returns:
            Dataset: A PyTorch Dataset instance for the specified dataset split.
        """
        match dataset_loader_type:
            case DatasetLoaderType.RGB:
                return RGBDatasetLoader(dataframe=ids_df,
                                  augmentations=augmentations)
            case DatasetLoaderType.FILTER:
                return FilterDatasetLoader(dataframe=ids_df,
                                           filter_type=filter_type,
                                           data_path=data_path,
                                           augmentations=augmentations)

    @staticmethod
    def _build_weighted_sampler(ids_df: DataFrame, class_weights: tuple[float, float]) -> torch.utils.data.WeightedRandomSampler:
        """
        Builds a WeightedRandomSampler to address class imbalance in the dataset.

        Args:
            ids_df (DataFrame): The DataFrame containing the image IDs and labels for the dataset split.
            class_weights (tuple[float, float]): Per-class sampling weights (class_0, class_1).

        Returns:
            WeightedRandomSampler: A PyTorch WeightedRandomSampler instance that can be used in a DataLoader to sample data points with probabilities inversely proportional to their class frequencies.
        """
        weight_map = {0: class_weights[0], 1: class_weights[1]}
        sample_weights = torch.tensor(
            ids_df['lesion_idx'].map(weight_map).values,
            dtype=torch.float
        )
        print("WEIGHTS: ", sample_weights)

        return torch.utils.data.WeightedRandomSampler(
            sample_weights, num_samples=len(ids_df), replacement=True
        )