from pandas import DataFrame
import torch

from torch.utils.data import DataLoader

from pipeline.json_dataclasses import AugmentationType, DatasetLoaderType, FilterType
from pipeline.pipeline_dataclasses import TrainValTestDataLoaders, TrainValTestSplit

from pathlib import Path

from pipeline.rgb_dataset_loader import RGBDatasetLoader
from pipeline.filter_dataset_loader import FilterDatasetLoader

class DataLoaderFactory:

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
        # transforms = DataLoaderFactory._get_transforms(augmentation)

        def make_loader(ids_df: DataFrame, shuffle: bool) -> DataLoader:
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
        
        match dataset_loader_type:
            case DatasetLoaderType.RGB:
                return RGBDatasetLoader(dataframe=ids_df,
                                  transforms=transforms)
            case DatasetLoaderType.FILTER:
                return FilterDatasetLoader(dataframe=ids_df,
                                           filter_type=filter_type,
                                           data_path=data_path,
                                           transforms=transforms)