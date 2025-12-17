from torch.utils.data import Dataset
import torchvision.transforms.functional
from PIL import Image

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
        label = self.dataframe.iloc[idx]['lesion_idx']

        image = Image.open(img_path).convert('RGB')
        
        if self.transform:
            image = self.transform(image)
        else:
            image = torchvision.transforms.functional.to_tensor(image)

        return image, label