import torch
import torch.nn as nn
import torch.nn.functional as F
import cv2
import albumentations as A
import numpy as np
from pathlib import Path

DEVICE = torch.device("cuda" if torch.cuda.is_available() else "cpu")


class UNet(nn.Module):
    def __init__(self, n_channels, n_classes):
        super(UNet, self).__init__()
        self.n_channels = n_channels
        self.n_classes = n_classes

        # Contracting path (encoder)
        self.conv1 = nn.Conv2d(self.n_channels, 64, kernel_size=3, padding=1)
        self.conv2 = nn.Conv2d(64, 128, kernel_size=3, padding=1)
        self.conv3 = nn.Conv2d(128, 256, kernel_size=3, padding=1)
        self.conv4 = nn.Conv2d(256, 512, kernel_size=3, padding=1)
        self.conv5 = nn.Conv2d(512, 1024, kernel_size=3, padding=1)
        self.pool = nn.MaxPool2d(kernel_size=2, stride=2)

        # Expansive path (decoder)
        self.upconv1 = nn.ConvTranspose2d(1024, 512, kernel_size=2, stride=2)
        self.conv6 = nn.Conv2d(1024, 512, kernel_size=3, padding=1)
        self.upconv2 = nn.ConvTranspose2d(512, 256, kernel_size=2, stride=2)
        self.conv7 = nn.Conv2d(512, 256, kernel_size=3, padding=1)
        self.upconv3 = nn.ConvTranspose2d(256, 128, kernel_size=2, stride=2)
        self.conv8 = nn.Conv2d(256, 128, kernel_size=3, padding=1)
        self.upconv4 = nn.ConvTranspose2d(128, 64, kernel_size=2, stride=2)
        self.conv9 = nn.Conv2d(128, 64, kernel_size=3, padding=1)
        self.conv10 = nn.Conv2d(64, self.n_classes, kernel_size=1)

    def forward(self, x):
        # Contracting path (encoder)
        x1 = F.relu(self.conv1(x))
        x2 = F.relu(self.conv2(self.pool(x1)))
        x3 = F.relu(self.conv3(self.pool(x2)))
        x4 = F.relu(self.conv4(self.pool(x3)))
        x5 = F.relu(self.conv5(self.pool(x4)))

        # Expansive path (decoder)
        x6 = F.relu(self.upconv1(x5))
        x6 = torch.cat([x4, x6], dim=1)
        x6 = F.relu(self.conv6(x6))
        x7 = F.relu(self.upconv2(x6))
        x7 = torch.cat([x3, x7], dim=1)
        x7 = F.relu(self.conv7(x7))
        x8 = F.relu(self.upconv3(x7))
        x8 = torch.cat([x2, x8], dim=1)
        x8 = F.relu(self.conv8(x8))
        x9 = F.relu(self.upconv4(x8))
        x9 = torch.cat([x1, x9], dim=1)
        x9 = F.relu(self.conv9(x9))
        x10 = self.conv10(x9)

        return x10


# Helper methods for cleaning the generated mask
def to_binary_mask(mask, threshold=0.5, use_sigmoid=True):
    """
    Convert model output to a binary uint8 mask (0 or 255).
    """
    mask = mask.astype(np.float32)

    if use_sigmoid:
        mask = 1.0 / (1.0 + np.exp(-mask))

    binary = (mask >= threshold).astype(np.uint8) * 255
    return binary


def get_largest_connected_area(binary_mask):
    """
    Keep only the largest connected component in a binary mask.
    """
    num_labels, labels, stats, _ = cv2.connectedComponentsWithStats(binary_mask, connectivity=8)

    # No foreground found
    if num_labels <= 1:
        return np.zeros_like(binary_mask, dtype=np.uint8)

    largest_label = 1 + np.argmax(stats[1:, cv2.CC_STAT_AREA])
    largest = (labels == largest_label).astype(np.uint8) * 255
    return largest


def smooth_mask_edges(mask, morph_kernel_size=7, blur_kernel_size=9):
    """
    Smooth contour using morphology + Gaussian blur.
    Returns a cleaned binary mask (0 or 255).
    """
    if blur_kernel_size % 2 == 0:
        blur_kernel_size += 1  # Gaussian kernel must be odd

    kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (morph_kernel_size, morph_kernel_size))

    cleaned = cv2.morphologyEx(mask, cv2.MORPH_CLOSE, kernel)
    cleaned = cv2.morphologyEx(cleaned, cv2.MORPH_OPEN, kernel)

    blurred = cv2.GaussianBlur(cleaned, (blur_kernel_size, blur_kernel_size), sigmaX=0)
    smoothed = (blurred > 127).astype(np.uint8) * 255

    return smoothed


def fill_holes_in_mask(mask):
    """
    Fill internal holes in a binary mask (0 or 255).
    """
    mask_u8 = (mask > 0).astype(np.uint8) * 255

    h, w = mask_u8.shape[:2]
    flood = mask_u8.copy()
    flood_fill_buffer = np.zeros((h + 2, w + 2), dtype=np.uint8)

    cv2.floodFill(flood, flood_fill_buffer, seedPoint=(0, 0), newVal=255)

    holes = cv2.bitwise_not(flood)
    filled = cv2.bitwise_or(mask_u8, holes)
    return filled


def resize_mask_to_original(mask, original_size):
    """
    Resize the mask back to the original image size.
    """
    return cv2.resize(mask, (original_size[1], original_size[0]), interpolation=cv2.INTER_NEAREST)


def clean_generated_mask(
    raw_mask, threshold=0.5, use_sigmoid=True, resize_to_shape=(256, 256)
):
    """
    Full cleanup pipeline:
    1) binarize
    2) keep largest connected region
    3) Remove holes in the mask by filling the area
    4) Resize to original size
    5) smooth edges
    """
    binary = to_binary_mask(raw_mask, threshold=threshold, use_sigmoid=use_sigmoid)
    largest = get_largest_connected_area(binary)
    filled = fill_holes_in_mask(largest)
    resized = resize_mask_to_original(filled, original_size=resize_to_shape)
    return resized


# Global cached model to prevent reloading it repeatedly
_model = None


def create_binary_mask(image, model_path=None):
    """
    Uses the trained UNet model to predict and return a cleaned binary mask of the lesion.
    """
    global _model

    # If no path provided, try to resolve the location based on typical directory structure
    if model_path is None:
        current_dir = Path(__file__).parent
        model_path = current_dir / "enhanced_lesion_cutout" / "lesion_cutout.pth.tar"

    if _model is None:
        _model = UNet(n_channels=3, n_classes=1).to(DEVICE)

        # Load weights
        checkpoint = torch.load(model_path, map_location=DEVICE, weights_only=False)
        _model.load_state_dict(checkpoint["state_dict"] if "state_dict" in checkpoint else checkpoint)
        _model.eval()

    original_shape = image.shape[:2]

    # Preprocessing
    transform = A.Compose([A.Resize(height=256, width=256)])
    augmentations = transform(image=image)
    img_resized = augmentations["image"]

    # Convert to tensor and normalise
    img_tensor = torch.from_numpy(img_resized).float() / 255.0
    img_tensor = img_tensor.permute(2, 0, 1).unsqueeze(0).to(DEVICE)

    # Inference
    with torch.no_grad():
        generated_mask = _model(img_tensor).squeeze().cpu().numpy()

    # Post-processing and cleanup
    cleaned_mask = clean_generated_mask(
        generated_mask,
        threshold=0.7,
        use_sigmoid=True,
        morph_kernel_size=7,
        blur_kernel_size=9,
        resize_to_shape=original_shape,
    )

    return generated_mask, cleaned_mask
