import pandas as pd

from dataset_manager import DatasetManager
from pipeline.json_dataclasses import CustomSplitConfig, SplitConfig, TrainValTestSplitRatio, SplitType
from pipeline.pipeline_dataclasses import TrainValTestSplit

from pathlib import Path


class SplitProvider:
    @staticmethod
    def get_split(data_path: Path, split_config: SplitConfig) -> TrainValTestSplit:
        if split_config.split_type == SplitType.CUSTOM:
            return SplitProvider._load_custom_split(split_config)
        else:
            return SplitProvider._create_split(data_path, split_config)
            
    @staticmethod
    def _create_split(data_path: Path, train_val_test_split_ratio: TrainValTestSplitRatio) -> TrainValTestSplit:
        manager = DatasetManager(data_path)
        manager.load_cleaned_metadata(filter_melanoma_only=True)
        train_df, val_df, test_df = manager.train_test_val_split(
            train_val_test_split_ratio.val_ratio,
            train_val_test_split_ratio.test_ratio)
        
        print(f"Training samples: {len(train_df)}")
        print(f"Validation samples: {len(val_df)}")
        print(f"Test samples: {len(test_df)}")

        return TrainValTestSplit(
            train_df=train_df,
            val_df=val_df,
            test_df=test_df
        )
    
    @staticmethod
    def _load_custom_split(custom_split_config: CustomSplitConfig) -> TrainValTestSplit:
        return TrainValTestSplit(
            train_df=pd.read_csv(custom_split_config.train_csv_path),
            val_df=pd.read_csv(custom_split_config.val_csv_path),
            test_df=pd.read_csv(custom_split_config.test_csv_path)
        )
