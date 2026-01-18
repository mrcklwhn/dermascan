import pandas as pd
import os
from pathlib import Path
from sklearn.model_selection import train_test_split
import matplotlib.pyplot as plt
from collections import Counter
import numpy as np
from skimage import io, color, filters
from skimage.feature import local_binary_pattern, graycomatrix, graycoprops
from scipy import ndimage
import random
from typing import Dict

clinical_groups = {
    'melanoma_and_atypical_nevi': {
        'mel': 'Melanoma',
        'nv': 'Melanocytic nevi (includes atypical nevi)'
    },
    'benign_lesions': {
        'bkl': 'Benign keratosis-like lesions',
        'df': 'Dermatofibroma',
        'vasc': 'Vascular lesions'
    },
    'non_melanoma_cancers': {
        'bcc': 'Basal cell carcinoma',
        'akiec': 'Actinic keratoses (pre-cancerous)'
    }
}

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

class HAM10000DatasetManager:
    def __init__(self, data_dir='data'):
        self.data_dir = Path(data_dir)
        self.metadata_path = self.data_dir / 'HAM10000_metadata.csv'
        self.clean_metadata_path = self.data_dir / 'HAM10000_metadata_cleaned.csv'
        self.images_dir = self.data_dir / 'raw'
        self.df = None  # Will hold the metadata

    def load_dataset(self, data_dir='data', metadata_path=None, clean_metadata_path=None, images_dir=None, filter_melanoma_only=True):
        """Download HAM10000 from Kaggle and organize locally."""
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

    def load_cleaned_metadata(self, filter_melanoma_only=True, sample_size=10000):
        """Load cleaned metadata CSV."""
        
        if self.clean_metadata_path and self.clean_metadata_path.exists():
            self.df = pd.read_csv(self.clean_metadata_path)

            if filter_melanoma_only:
                self.df = self._filter_melanoma_nevi(self.df)

                # create balanced dataset if sample_size is specified 50/50 mel/nv split
                if sample_size and sample_size < len(self.df):
                    self.df = self.df.groupby('dx').sample(n=sample_size // 2, random_state=42).reset_index(drop=True)
                    self.df = self.df.sample(frac=1, random_state=42).reset_index(drop=True)  # shuffle

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
        """Split data into train/test/val while respecting stratified by lesion type."""
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
    
    def _apply_gabor_filter(self, image_gray, frequency=0.6, theta=0):
        """Apply Gabor wavelet filter to grayscale image."""
        gabor_real, gabor_imag = filters.gabor(image_gray, frequency=frequency, theta=theta)
        # Combine real and imaginary parts for magnitude
        gabor_magnitude = np.sqrt(gabor_real**2 + gabor_imag**2)
        return gabor_magnitude

    def _apply_lbp_filter(self, image_gray, radius=3, n_points=24):
        """Apply Local Binary Pattern filter to grayscale image."""
        lbp = local_binary_pattern(image_gray, n_points, radius, method='uniform')
        return lbp

    def _apply_glcm_filter(self, image_gray, distances=[1], angles=[0]):
        """
        Apply GLCM-based texture visualization.
        Creates a texture map based on local GLCM properties.
        """
        # Normalize and convert to uint8 for GLCM
        image_uint8 = ((image_gray - image_gray.min()) / 
                       (image_gray.max() - image_gray.min()) * 255).astype(np.uint8)
        
        # Compute GLCM-based texture map using sliding window approach
        window_size = 15
        half_win = window_size // 2
        
        # Pad the image
        padded = np.pad(image_uint8, half_win, mode='reflect')
        
        # Create output texture map (using contrast as the texture measure)
        texture_map = np.zeros_like(image_gray)
        
        # Sample every few pixels for efficiency, then interpolate
        step = 3
        for i in range(0, image_gray.shape[0], step):
            for j in range(0, image_gray.shape[1], step):
                window = padded[i:i+window_size, j:j+window_size]
                # Reduce levels for faster computation
                window_reduced = (window // 16).astype(np.uint8)
                glcm = graycomatrix(window_reduced, distances, angles, 
                                   levels=16, symmetric=True, normed=True)
                contrast = graycoprops(glcm, 'contrast')[0, 0]
                # Fill the step x step region
                end_i = min(i + step, image_gray.shape[0])
                end_j = min(j + step, image_gray.shape[1])
                texture_map[i:end_i, j:end_j] = contrast
        
        return texture_map
    
    def get_random_lesions(self, lesion_types=None) -> Dict[str, str]:
        """
        Get one image names from each specified lesion types.
        Args:
            lesion_types: List of lesion type codes (e.g., ['nv', 'mel']).
                          If None, selects from all lesion types.
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

    def visualize_image_with_filters_side_by_side(self, image_names):
        """
        Visualize multiple images with different texture filters side by side.
        Args:
            image_names: List of image_ids (without file extension).
        """
        if self.df is None:
            raise ValueError("Dataset not loaded. Please run load_dataset() first.")
        
        # Load images and apply filters
        images = []
        for image_name in image_names:
            matching = self.df[self.df['image_id'] == image_name]
            
            if len(matching) == 0:
                raise ValueError(f"Image '{image_name}' not found in dataset.")
            
            row = matching.iloc[0]
            lesion_class = row['dx']
            lesion_name = lesion_type_dict.get(lesion_class, lesion_class)
            image_path = row['image_path']
            image = io.imread(image_path)
            image_gray = color.rgb2gray(image)
            
            gabor_result = self._apply_gabor_filter(image_gray)
            lbp_result = self._apply_lbp_filter(image_gray)
            glcm_result = self._apply_glcm_filter(image_gray)
            
            images.append((image_name, lesion_name, image, gabor_result, lbp_result, glcm_result))

        # Set up the subplot grid
        num_images = len(image_names)
        fig, axes = plt.subplots(num_images, 4, figsize=(16, 4 * num_images))

        # Plot each image and its filters
        for i, (image_name, lesion_name, image, gabor_result, lbp_result, glcm_result) in enumerate(images):
            axes[i, 0].imshow(image)
            axes[i, 0].set_title(f'Original Image | {image_name} | {lesion_name}')
            axes[i, 0].axis('off')

            axes[i, 1].imshow(gabor_result, cmap='gray')
            axes[i, 1].set_title('Gabor Wavelet Filter')
            axes[i, 1].axis('off')

            axes[i, 2].imshow(lbp_result, cmap='gray')
            axes[i, 2].set_title('Local Binary Pattern')
            axes[i, 2].axis('off')

            axes[i, 3].imshow(glcm_result, cmap='hot')
            axes[i, 3].set_title('GLCM Texture Map (Contrast)')
            axes[i, 3].axis('off')


    
    def visualize_image_with_filters(self, image_name=None):
        """
        Visualize an image with different texture filters.
        
        Args:
            image_name: Optional image_id (without .jpg extension). 
                       If None, a random image is selected.
        
        Returns:
            tuple: (image_name, lesion_class)
        """
        if self.df is None:
            raise ValueError("Dataset not loaded. Please run load_dataset() first.")
        
        # Select image
        if image_name is None:
            # Random selection
            random_idx = random.randint(0, len(self.df) - 1)
            row = self.df.iloc[random_idx]
        else:
            # Find by image_id
            matching = self.df[self.df['image_id'] == image_name]
            if len(matching) == 0:
                raise ValueError(f"Image '{image_name}' not found in dataset.")
            row = matching.iloc[0]
        
        image_id = row['image_id']
        lesion_class = row['dx']
        lesion_name = lesion_type_dict.get(lesion_class, lesion_class)
        image_path = row['image_path']
        
        # Load image
        image = io.imread(image_path)
        image_gray = color.rgb2gray(image)
        
        # Apply filters
        gabor_result = self._apply_gabor_filter(image_gray)
        lbp_result = self._apply_lbp_filter(image_gray)
        glcm_result = self._apply_glcm_filter(image_gray)
        
        # Create visualization
        fig, axes = plt.subplots(2, 2, figsize=(12, 10))
        fig.suptitle(f'Image: {image_id} | Class: {lesion_class} ({lesion_name})', 
                     fontsize=14, fontweight='bold')
        
        # Original image
        axes[0, 0].imshow(image)
        axes[0, 0].set_title('Original Image')
        axes[0, 0].axis('off')
        
        # Gabor filter
        axes[0, 1].imshow(gabor_result, cmap='gray')
        axes[0, 1].set_title('Gabor Wavelet Filter')
        axes[0, 1].axis('off')
        
        # GLCM texture map
        axes[1, 0].imshow(glcm_result, cmap='hot')
        axes[1, 0].set_title('GLCM Texture Map (Contrast)')
        axes[1, 0].axis('off')
        
        # Local Binary Pattern
        axes[1, 1].imshow(lbp_result, cmap='gray')
        axes[1, 1].set_title('Local Binary Pattern')
        axes[1, 1].axis('off')
        
        plt.tight_layout()
        plt.show()
        
        return image_id, lesion_class

    def create_dataloaders(self, train_df, val_df, test_df, batch_size=32, num_workers=4):
        """Create PyTorch DataLoaders for train/test/val."""
        pass

