from enum import Enum

class ModelType(Enum):
    RESNET_18 = "resnet18"
    RESNET_50 = "resnet50"
    RESNET_101 = "resnet101"
    EFFICIENTNET_V2_S = "efficientnet_v2_s"
    INCEPTION_V3 = "inception_v3"
    SQUEEZENET_1_1 = "squeezenet_1_1" 
    MOBILENET_V3_SMALL = "mobilenet_v3_small"
    MOBILENET_V3_LARGE = "mobilenet_v3_large"

class LossType(Enum):
    BCE_WITH_LOGITS = "bce_with_logits" # used for single node binary classification
    CROSS_ENTROPY = "cross_entropy" # used for multi-node binary classification

class DatasetLoaderType(Enum):
    RGB = "rgb"
    FILTER = "filter"

class AugmentationType(Enum):
    # geometric/spatial augmentations
    RANDOM_RESIZE_CROP = "random_resize_crop"
    RESIZE = "resize"
    CENTER_CROP = "center_crop"
    RANDOM_HORIZONTAL_FLIP = "random_horizontal_flip"
    RANDOM_VERTICAL_FLIP = "random_vertical_flip"
    RANDOM_ROTATION = "random_rotation"

    # color/appearance augmentations
    COLOR_JITTER = "color_jitter"
    RANDOM_ERASING = "random_erasing"

class MetricsType(Enum):
    ACCURACY = "accuracy"
    PRECISION = "precision"
    RECALL = "recall"
    AUC = "auc"
    F1_SCORE_MACRO = "f1_score_macro"
    F1_SCORE_WEIGHTED = "f1_score_weighted"
    SENSITIVITY = "sensitivity"
    SPECIFICITY = "specificity"

class FilterType(Enum):
    RGB = ("rgb", 3)
    GABOR = ("gabor", 40)
    GLCM = ("glcm", 32)
    LBP = ("lbp", 1)

    def __init__(self, filter_name: str, num_channels: int):
        self.filter_name = filter_name
        self.num_channels = num_channels

class OptimizerType(Enum):
    ADAM = "adam"
    ADAMW = "adamw"
    SGD = "sgd"

class SchedulerType(Enum):
    REDUCE_ON_PLATEAU = "reduce_on_plateau"
    COSINE_ANNEALING = "cosine_annealing"

class SplitType(Enum):
    RATIO = "ratio"
    CUSTOM = "custom"