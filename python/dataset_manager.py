import pandas as pd
import os
from pathlib import Path
from sklearn.model_selection import train_test_split
import matplotlib.pyplot as plt
from collections import Counter
import numpy as np
from skimage import io
import random
from typing import Dict

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

# Binary classification for melanoma screening
melanoma_binary_dict = {
    'nv': 0,   # Melanocytic nevi (benign/atypical)
    'mel': 1,  # Melanoma (malignant)
}

class DatasetManager:
    def __init__(self, data_dir='data'):
        self.data_dir = Path(data_dir)
        self.metadata_path = self.data_dir / 'HAM10000_metadata.csv'
        self.clean_metadata_path = self.data_dir / 'HAM10000_metadata_cleaned.csv'
        self.images_dir = self.data_dir / 'raw'
        self.df = None  # Will hold the metadata

    def load_dataset(self, data_dir='data', metadata_path=None, clean_metadata_path=None, images_dir=None, filter_melanoma_only=True):
        """
        Download HAM10000 from Kaggle and organize locally.
        
        Args:
            data_dir: Base directory for dataset
            metadata_path: Path to metadata CSV file
            clean_metadata_path: Path to cleaned metadata CSV file
            images_dir: Directory containing raw images
            filter_melanoma_only: Whether to filter dataset to only melanoma (mel) and melanocytic nevi (nv)
        """
        self.data_dir = Path(data_dir)
        self.metadata_path = Path(metadata_path) if metadata_path else self.data_dir / 'HAM10000_metadata.csv'
        self.clean_metadata_path = Path(clean_metadata_path) if clean_metadata_path else self.data_dir / 'HAM10000_metadata_cleaned.csv'
        self.images_dir = Path(images_dir) if images_dir else self.data_dir / 'raw'

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

            if filter_melanoma_only:
                self.df = self._filter_melanoma_nevi(self.df)

    def load_cleaned_metadata(self, filter_melanoma_only=True):
        """
        Load cleaned metadata CSV.
        
        Args:
            filter_melanoma_only: Whether to filter dataset to only melanoma (mel) and melanocytic nevi (nv)
        """
        
        if self.clean_metadata_path and self.clean_metadata_path.exists():
            self.df = pd.read_csv(self.clean_metadata_path)

            if filter_melanoma_only:
                self.df = self._filter_melanoma_nevi(self.df)
        else:
            raise FileNotFoundError("Cleaned metadata file not found. Please run load_dataset() first.")

    def _filter_melanoma_nevi(self, df: pd.DataFrame) -> pd.DataFrame:
        """
        Filter dataset to only include melanoma (mel) and melanocytic nevi (nv).
        Adds binary classification label for melanoma detection.
        
        Args:
            df: Full dataset DataFrame
            
        Returns:
            Filtered DataFrame with only mel and nv classes
        """
        # Filter for melanoma and melanocytic nevi only
        melanoma_classes = ['mel', 'nv']
        df_filtered = df[df['dx'].isin(melanoma_classes)].copy()
        
        # Add binary label (0 = nv, 1 = mel)
        df_filtered['melanoma_binary'] = df_filtered['dx'].map(melanoma_binary_dict)
        
        # Update lesion_idx for binary classification
        df_filtered['lesion_idx'] = df_filtered['melanoma_binary']
                
        return df_filtered

    def _get_invalid_image_paths(self, df: pd.DataFrame) -> list:
        """
        Check for invalid image paths.

        Args:
            df: DataFrame containing dataset metadata

        Returns:
            A list of invalid image paths.
        """
        invalid_paths = []
        for idx, row in df.iterrows():
            image_path = row['image_path']
            if not os.path.isfile(image_path):
                invalid_paths.append(image_path)
        return invalid_paths
    
    def _clean_null_values(self, df: pd.DataFrame) -> pd.DataFrame:
        """
        Remove rows with null values in critical columns.

        Args:
            df: DataFrame containing dataset metadata

        Returns:
            Cleaned DataFrame with no nulls in critical columns.
        """
        # make sure there are no nulls in dx_type, dx, image_id, lesion_id
        df_cleaned = df.dropna(subset=['dx_type', 'dx', 'image_id', 'lesion_id'])

        # print number of rows removed
        num_removed = len(df) - len(df_cleaned)
        if num_removed > 0:
            print(f"Removed {num_removed} rows with null values in critical columns.")

        return df_cleaned

    def _remove_duplicates(self, df: pd.DataFrame) -> pd.DataFrame:
        """
        Remove duplicate images (same image hash with same diagnosis).
        
        Args:
            df: DataFrame containing dataset metadata

        Returns:
            DataFrame with duplicates removed.
        """
        
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
    
    def print_class_distribution(self, df: pd.DataFrame):
        """
        Visualize class distribution.
        
        Args:
            df: DataFrame containing dataset metadata
        """
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
        """
        Split data into train/test/val while respecting stratified by lesion type.
        
        Args:
            test_size: Proportion of data to use for testing
            val_size: Proportion of data to use for validation 

        Returns:
            train_df, val_df, test_df: DataFrames for each split       
        """
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
    
    def get_sample(self):
        """
        Returns a sample row from the dataset.

        Returns:
            A random row from the dataset as a pandas Series.
        """

        if self.df is None:
            raise ValueError("Dataset not loaded. Please run load_dataset() first.")
        
        random_idx = random.randint(0, len(self.df) - 1)
        row = self.df.iloc[random_idx]
        return row

    def get_sample_image(self, lesion_type = None) -> tuple[str, str, np.ndarray]:
        """
        Get a sample image from the dataset.

        Args:
            lesion_type: Optional lesion type code (e.g., 'nv', 'mel').
                         If None, a random lesion type is selected.

        Returns:
            Tuple of (image_id, lesion_type, image as numpy array)
        """
        if self.df is None:
            raise ValueError("Dataset not loaded. Please run load_dataset() first.")
        
        if lesion_type is None:
            # Random selection
            random_idx = random.randint(0, len(self.df) - 1)
            row = self.df.iloc[random_idx]
        else:
            # Find by lesion type
            subset = self.df[self.df['dx'] == lesion_type]
            if len(subset) == 0:
                raise ValueError(f"No images found for lesion type '{lesion_type}'.")
            random_idx = random.randint(0, len(subset) - 1)
            row = subset.iloc[random_idx]
        
        image_id = row['image_id']
        image_path = row['image_path']
        lesion_type = row['dx']
        
        image = io.imread(image_path)
        
        return image_id, lesion_type, image

    def get_random_lesions(self, lesion_types=None) -> Dict[str, str]:
        """
        Get one image names from each specified lesion types.

        Args:
            lesion_types: List of lesion type codes (e.g., ['nv', 'mel']).
                          If None, selects from all lesion types.

        Returns:
            A dictionary mapping lesion type to image_id.
        """
        if self.df is None:
            raise ValueError("Dataset not loaded. Please run load_dataset() first.")
        
        if lesion_types is None:
            lesion_types = list(lesion_type_dict.keys())

        selected_images = {}
        for lesion in lesion_types:
            subset = self.df[self.df['dx'] == lesion]
            if len(subset) == 0:
                raise ValueError(f"No images found for lesion type '{lesion}'.")
            random_idx = random.randint(0, len(subset) - 1)
            row = subset.iloc[random_idx]
            selected_images[lesion] = row['image_id']

        return selected_images
    
    def get_n_samples(self, n: int, lesion_type: str = None) -> list[np.ndarray]:
        """
        Get n sample images from the dataset.

        Args:
            n: Number of samples to retrieve.
            lesion_type: Optional lesion type code (e.g., 'nv', 'mel').
                         If None, samples from all lesion types.

        Returns:
            List of rows from the dataset.
        """
        if self.df is None:
            raise ValueError("Dataset not loaded. Please run load_dataset() first.")
        
        if lesion_type is None:
            sampled_df = self.df.sample(n=n)
        else:
            subset = self.df[self.df['dx'] == lesion_type]
            if len(subset) < n:
                raise ValueError(f"Not enough images for lesion type '{lesion_type}'. Requested: {n}, Available: {len(subset)}")
            sampled_df = subset.sample(n=n)

        return sampled_df

    def get_image_by_id(self, image_id: str) -> np.ndarray:
        """
        Get an image from the dataset by image_id.
        
        Args:
            image_id: image_id (without .jpg extension).
            
        Returns:
            Image as numpy array.
        """
        if self.df is None:
            raise ValueError("Dataset not loaded. Please run load_dataset() first.")
        
        # Find by image_id
        matching = self.df[self.df['image_id'] == image_id]
        if len(matching) == 0:
            raise ValueError(f"Image '{image_id}' not found in dataset.")
        row = matching.iloc[0]
        
        image_path = row['image_path']
        
        # Load image
        image = io.imread(image_path)
        
        return image

    def visualize_image_with_filters(self, image_id: str, filter_method_list: list[callable]):
        """
        Visualize an image from the dataset with specified filters.
        
        Args:
            image_id: image_id (without .jpg extension).
            filter_method_list: List of callable filters methods, that take an image as input and return processed image.

        """

        if self.df is None:
            raise ValueError("Dataset not loaded. Please run load_dataset() first.")
        
        # Find by image_id
        matching = self.df[self.df['image_id'] == image_id]
        if len(matching) == 0:
            raise ValueError(f"Image '{image_id}' not found in dataset.")
        row = matching.iloc[0]
        
        image_id = row['image_id']
        lesion_class = row['dx']
        lesion_name = lesion_type_dict.get(lesion_class, lesion_class)
        image_path = row['image_path']
        
        # Load image
        image = io.imread(image_path)
        filter_image = image
        
        # Apply filters
        filtered_results = []
        for filter_method in filter_method_list:
            result = filter_method(filter_image)
            filtered_results.append(result)
        
        # Create visualization
        num_filters = len(filter_method_list)
        fig, axes = plt.subplots(1, num_filters + 1, figsize=(5 * (num_filters + 1), 5))
        fig.suptitle(f'Image: {image_id} | Class: {lesion_class} ({lesion_name})', 
                     fontsize=14, fontweight='bold')
        
        # Original image
        axes[0].imshow(image)
        axes[0].set_title('Original Image')
        axes[0].axis('off')
        
        # Filtered images
        for i, result in enumerate(filtered_results):
            axes[i + 1].imshow(result, cmap='gray')
            axes[i + 1].set_title(f'Filter {i + 1}')
            axes[i + 1].axis('off')
        
        plt.tight_layout()
        plt.show()