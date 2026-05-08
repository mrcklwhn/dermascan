from pathlib import Path

import pandas as pd
from dataset_manager import DatasetManager
from pipeline.dataclasses.pipeline_config import CustomSplitConfig, SplitConfig, SplitType, TrainValTestSplitRatio
from pipeline.dataclasses.pipeline_runtime import TrainValTestSplit

class SplitProvider:
    """
    SplitProvider is responsible for providing train/validation/test splits of the dataset based on the specified configuration.
    It supports two types of splits:
    - Automatic splits based on specified ratios.
    - Custom splits provided via CSV files.
    """
    @staticmethod
    def get_split(data_path: Path, split_config: SplitConfig, seed: int | None = None) -> TrainValTestSplit:
        """
        Provides the train/validation/test split of the dataset based on the specified configuration.

        Args:
            data_path (Path): The path to the dataset.
            split_config (SplitConfig): The configuration for how to split the dataset, which can be either:
                - TrainValTestSplitRatio: Specifies the ratios for train/validation/test splits.
                - CustomSplitConfig: Specifies paths to CSV files containing the splits.
            seed (int | None): The seed for reproducibility.
        Returns:
            TrainValTestSplit: An object containing the train, validation, and test splits as pandas DataFrames.
        """
        if split_config.split_type == SplitType.CUSTOM:
            return SplitProvider._load_custom_split(split_config)
        else:
            return SplitProvider._create_split(data_path, split_config, seed)
            
    @staticmethod
    def _create_split(data_path: Path, train_val_test_split_ratio: TrainValTestSplitRatio, seed: int | None = None) -> TrainValTestSplit:
        """
        Creates a train/validation/test split of the dataset based on the specified ratios.

        Args:
            data_path (Path): The path to the dataset.
            train_val_test_split_ratio (TrainValTestSplitRatio): The ratios for train/validation/test splits.
        Returns:
            TrainValTestSplit: An object containing the train, validation, and test splits as pandas DataFrames.
        """
        manager = DatasetManager(data_path)
        manager.load_cleaned_metadata(filter_melanoma_only=True)
        train_df, val_df, test_df = manager.train_test_val_split(
            train_val_test_split_ratio.val_ratio,
            train_val_test_split_ratio.test_ratio,
            random_state=seed)
        
        print(f"Training samples: {len(train_df)}")
        print(f"Validation samples: {len(val_df)}")
        print(f"Test samples: {len(test_df)}")
        print("-" * 10)

        return TrainValTestSplit(
            train_df=train_df,
            val_df=val_df,
            test_df=test_df
        )
    
    @staticmethod
    def _load_custom_split(custom_split_config: CustomSplitConfig) -> TrainValTestSplit:
        """
        Loads a custom train/validation/test split of the dataset from specified CSV files.

        Args:
            custom_split_config (CustomSplitConfig): The configuration containing paths to the CSV files for the splits.
        Returns:
            TrainValTestSplit: An object containing the train, validation, and test splits as pandas DataFrames.
        """
        return TrainValTestSplit(
            train_df=pd.read_csv(custom_split_config.train_csv_path),
            val_df=pd.read_csv(custom_split_config.val_csv_path),
            test_df=pd.read_csv(custom_split_config.test_csv_path)
        )
