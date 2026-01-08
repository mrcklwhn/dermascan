from pathlib import Path
from torch.utils.data import Dataset
import cv2
import torchvision.transforms.functional
from PIL import Image
import numpy as np

class HAM10000Dataset(Dataset):
    def __init__(self, dataframe, transform=None):
        """
        Custom Dataset for HAM10000 skin lesion images.

        :param dataframe: Pandas DataFrame containing image paths and labels
        :param transform: Optional transformations to be applied on the images
        """
        self.dataframe = dataframe
        self.transform = transform

    def __len__(self):
        return len(self.dataframe)

    def __getitem__(self, idx):
        """
        Retrieve an image and its corresponding label.

        :param idx: Index of the item to retrieve
        :return: Tuple of (image, label)
        """
        img_path = self.dataframe.iloc[idx]['image_path']
        pil_image = Image.open(img_path).convert('RGB')
        pil_image = pil_image.resize((224, 224))
        rgb_channel = np.array(pil_image)
        rgb_channel = rgb_channel.astype(np.float32) / 255.0 # for preventing exploding gradients

        filtered_path = Path(r"C:\Users\T22127A\Documents\priv\priv_dev\dermascan\data\filtered") / (self.dataframe.iloc[idx]['image_id'] + ".npz")
        filtered_image = np.load(filtered_path)
        gabor_channel = filtered_image['gabor_filter']
        lbp_channel = filtered_image['lbp_filter']
        glcm_channel = filtered_image['glcm_filter']

        # Normalize each filtered channel to [0, 1]
        gabor_channel = self.minmax_normalize_filtered_image(gabor_channel)
        gabor_channel = cv2.resize(gabor_channel, (224, 224), interpolation=cv2.INTER_LINEAR)

        glcm_channel = self.minmax_normalize_filtered_image(glcm_channel)
        glcm_channel  = cv2.resize(glcm_channel,  (224, 224), interpolation=cv2.INTER_LINEAR)

        lbp_channel = lbp_channel.astype(np.float32) / 255.0 # because LBP is in [0, 255]
        lbp_channel   = cv2.resize(lbp_channel,   (224, 224), interpolation=cv2.INTER_NEAREST)

        combined_channels = np.concatenate(
            [rgb_channel,
             gabor_channel[:, :, np.newaxis],
             lbp_channel[:, :, np.newaxis],
             glcm_channel[:, :, np.newaxis]], axis=2)

        tensor = torchvision.transforms.functional.to_tensor(combined_channels)

        label = self.dataframe.iloc[idx]['lesion_idx']

        if self.transform:
            image = self.transform(tensor)
        else:
            image = tensor

        return image, label
    
    def minmax_normalize_filtered_image(self, npz_image):
        """Normalize filtered image to [0, 1] range."""
        image_min, image_max = npz_image.min(), npz_image.max()
        if image_max - image_min > 1e-8:
            normalized_image = (npz_image - image_min) / (image_max - image_min)
        else:
            normalized_image = np.zeros_like(npz_image)
        return np.float32(normalized_image)