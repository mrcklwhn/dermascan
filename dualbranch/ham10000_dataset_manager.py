import pandas as pd
import numpy as np
import os
from pathlib import Path
import kagglehub
from sklearn.model_selection import train_test_split
import matplotlib.pyplot as plt
from collections import Counter

lesion_type_dict = {
    'nv': 'Melanocytic nevi',
    'mel': 'Melanoma',
    'bkl': 'Benign keratosis-like lesions ',
    'bcc': 'Basal cell carcinoma',
    'akiec': 'Actinic keratoses',
    'vasc': 'Vascular lesions',
    'df': 'Dermatofibroma'
}

cell_type_idx_dict = {
    'akiec': 0,
    'bcc': 1,
    'bkl': 2,
    'df': 3,
    'nv': 4,
    'mel': 5,
    'vasc': 6,
}


class HAM10000DatasetManager:
    def __init__(self, data_dir='data/raw'):
        self.data_dir = Path(data_dir)
        self.metadata_path = None
        self.images_dir = None
        self.df = None  # Will hold the metadata
    
    def load_dataset(self, data_dir='data'):
        """Download HAM10000 from Kaggle and organize locally."""
        self.data_dir = Path(data_dir)
        self.metadata_path = self.data_dir / 'HAM10000_metadata.csv'
        self.clean_metadata_path = self.data_dir / 'HAM10000_metadata_cleaned.csv'
        self.images_dir = self.data_dir / 'raw'

        if not self.data_dir.exists():
            print("No data directory found. Downloading dataset from Kaggle...")

        if self.data_dir.exists() and self.images_dir.exists() and self.metadata_path.exists():
            metadata = pd.read_csv(self.metadata_path)

            # remove rows with null values in critical columns
            metadata = self._clean_null_values(metadata)

            # Add image paths and lesion indices as categorical labels
            metadata['image_path'] = metadata['image_id'].apply(lambda x: str(self.images_dir / f"{x}.jpg"))
            metadata['lesion_idx'] = metadata['dx'].map(cell_type_idx_dict)

            # Remove invalid image paths
            metadata = metadata[~metadata['image_path'].isin(self._get_invalid_image_paths(metadata))]

            # remove duplicate images
            metadata = self._remove_duplicates(metadata)

            # save cleaned metadata
            metadata.to_csv(self.clean_metadata_path, index=False)

        if self.clean_metadata_path.exists():

            self.df = pd.read_csv(self.clean_metadata_path)    

    def _get_invalid_image_paths(self, df: pd.DataFrame) -> list:
        """Check for invalid image paths."""
        invalid_paths = []
        for idx, row in df.iterrows():
            image_path = row['image_path']
            if not os.path.isfile(image_path):
                invalid_paths.append(image_path)
        return invalid_paths
    
    def _clean_null_values(self, df: pd.DataFrame) -> pd.DataFrame:
        """Remove rows with null values in critical columns."""
        # make sure there are no nulls in dx_type, dx, image_id, lesion_id
        df_cleaned = df.dropna(subset=['dx_type', 'dx', 'image_id', 'lesion_id'])

        # print number of rows removed
        num_removed = len(df) - len(df_cleaned)
        if num_removed > 0:
            print(f"Removed {num_removed} rows with null values in critical columns.")

        return df_cleaned

    def _remove_duplicates(self, df: pd.DataFrame) -> pd.DataFrame:
        """Remove duplicate images (same image hash with same diagnosis)."""
        
        # build image hash dataframe 
        image_hashes = []
        for idx, row in df.iterrows():
            image_path = row['image_path']
            with open(image_path, 'rb') as f:
                image_data = f.read()
                image_hash = hash(image_data)
                image_hashes.append(image_hash)

        df['image_hash'] = image_hashes
        df_cleaned = df.drop_duplicates(subset=['image_hash', 'dx'])

        if len(df) - len(df_cleaned) > 0:
            print(f"Removed {len(df) - len(df_cleaned)} duplicate images based on image hash and diagnosis.")

        return df_cleaned
    
    def print_class_distribution(self, df):
        """Visualize class distribution."""
        class_counts = Counter(df['dx'])
        labels, counts = zip(*class_counts.items())

        plt.figure(figsize=(10, 6))
        plt.bar(labels, counts)
        plt.xlabel('Lesion Type')
        plt.ylabel('Count')
        plt.title('Class Distribution')
        plt.xticks(rotation=45)
        plt.show()
    
    def train_test_val_split(self, test_size=0.2, val_size=0.1, random_state=42):
        """Split data into train/test/val while respecting patient_id (no leakage)."""
        train_val_df, test_df = train_test_split(
            self.df,
            test_size=test_size,
            stratify=self.df['dx'],
            random_state=random_state
        )

        train_df, val_df = train_test_split(
            train_val_df,
            test_size=val_size / (1 - test_size),
            stratify=train_val_df['dx'],
            random_state=random_state
        )

        return train_df, val_df, test_df
    
    def create_dataloaders(self, train_df, val_df, test_df, batch_size=32, num_workers=4):
        """Create PyTorch DataLoaders for train/test/val."""
        pass

        