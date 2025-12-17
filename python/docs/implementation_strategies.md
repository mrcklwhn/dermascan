# Updated Work Streams Based on Your Design Decisions 🎯

Perfect clarity! Now I can design a focused, parallelizable architecture. Here's your refined roadmap:

## Key Architecture Overview

```
Original HAM10000 Images
    ↓
[Offline Preprocessing - External]
    ├─ Texture Filters (Gabor, LBP, GLCM, Sobel) → Stored on Disk
    ├─ Color Filters (Contrast Enhancement, etc.) → Stored on Disk
    └─ Deterministic Scores (Symmetry, Color Uniformity) → CSV/JSON
    ↓
[DataLoader - Runtime Augmentation]
    ├─ Random rotation, skewing, etc.
    └─ Load original + filtered versions as multi-channel input
    ↓
[Two Identical ResNet Branches (Trained Separately)]
    ├─ Texture Branch (input: grayscale multi-channel from texture filters)
    └─ Color Branch (input: grayscale multi-channel from color filters)
    ↓
[Feature Vectors from FC Layer]
    ↓
[Fusion Layer (Variant 1) OR Soft Voter (Variant 2)]
    ↓
[Dense Classifier → Melanoma / Nevi Probability]
```

## Updated Parallel Work Streams

### Stream A: Preprocessing & Data Augmentation Pipeline ⏱️

**Priority:** FIRST - Enables all other streams

**Goals:** Build disk-based preprocessed dataset. No on-the-fly computation.

#### Task A1: Texture Filter Implementation

- **File:** `dualbranch/preprocessing/texture_filters.py`
- **Implement:** Gabor Wavelets, Local Binary Pattern (LBP), GLCM, Sobel
- **Output:** Functions that take image → multi-channel grayscale tensor (e.g., 8 Gabor filters = 8 channels)
- **Libraries:** scikit-image, OpenCV, pywt (PyWavelets)

```python
def apply_texture_filters(image_path, output_channels=8):
    """
    Returns: (H, W, C) where C = concatenated filter outputs
    E.g., 2x Sobel + 8x Gabor = 10 channels
    """
```

#### Task A2: Color Filter Implementation

- **File:** `dualbranch/preprocessing/color_filters.py`
- **Implement:** Contrast enhancement, color normalization, selective histogram equalization
- **Output:** Grayscale multi-channel (e.g., different contrast levels stacked)

```python
def apply_color_filters(image_path, output_channels=4):
    """
    Returns: (H, W, C) with different color/contrast enhancements
    """
```

#### Task A3: Batch Preprocessing Script

- **File:** `dualbranch/preprocessing/preprocess_dataset.py`
- **Input:** Original HAM10000 directory
- **Output:**
  - `{dataset_root}/texture_filtered/` (multi-channel images)
  - `{dataset_root}/color_filtered/` (multi-channel images)
  - Save as HDF5 or NumPy for efficient loading
- **Performance:** Parallelizable across cores

#### Task A4: Extend HAM10000Dataset Class

- **File:** `dualbranch/ham10000_dataset.py`
- **New class:** `DualPreprocessedDataset`
  - Loads original image
  - Loads texture-filtered version
  - Loads color-filtered version
  - Returns: `(texture_input, color_input, label)` tuples
  - Apply standard augmentation (rotate, skew, flip) to all versions identically

```python
class DualPreprocessedDataset(Dataset):
    def __init__(self, df, texture_dir, color_dir, transform=None):
        self.df = df
        self.texture_dir = texture_dir
        self.color_dir = color_dir
        self.transform = transform
    
    def __getitem__(self, idx):
        # Load texture & color versions
        # Apply same augmentation to both
        # Return (texture_tensor, color_tensor, label)
```

#### Task A5: Validation & Visualization

- **File:** `dualbranch/preprocessing/validate_preprocessing.py`
- **Tasks:**
  - Visualize sample texture/color filter outputs
  - Verify output shapes, value ranges, no NaN
  - Generate report of preprocessing statistics

---

### Stream B: Score Computation (Deterministic) ⏱️

**Priority:** PARALLEL with A (independent)

**Goals:** Compute deterministic descriptors from images. Usable both offline and in mobile app.

#### Task B1: Texture Score Computation

- **File:** `dualbranch/scoring/texture_scores.py`
- **Implement:**
  - Symmetry detection (e.g., via Laplacian variance, edge entropy)
- **Libraries:** scikit-image, OpenCV
- **Output:** Single float per image (0-1 scale)

```python
def compute_symmetry_score(image_path):
    """
    Detect if lesion is symmetric.
    Returns: float [0, 1]
    """
```

#### Task B2: Color Score Computation

- **File:** `dualbranch/scoring/color_scores.py`
- **Implement:**
  - Color uniformity (std deviation of dominant colors)
  - Outlier detection (unusual color patches)
- **Output:** Dict of scores per image

```python
def compute_color_uniformity_score(image_path):
    """Returns: float [0, 1]"""

def compute_color_outlier_score(image_path):
    """Returns: float [0, 1] - higher = more outliers"""
```

#### Task B3: ScoreComputer Utility Class

- **File:** `dualbranch/scoring/score_computer.py`
- **Purpose:** Unified interface for offline & online score computation
- **Usage:** During training (augment features) or for interpretability
- **Output:** Store scores in CSV alongside dataset

```python
class ScoreComputer:
    @staticmethod
    def compute_all_scores(image_path):
        return {
            'symmetry': compute_symmetry_score(...),
            'color_uniformity': compute_color_uniformity_score(...),
            'color_outliers': compute_color_outlier_score(...)
        }
```

#### Task B4: Mobile-Compatible Score Computation

- **File:** `mobile/lib/utils/image_scoring.dart`
- **Research:** Dart/Flutter packages for image processing
- **Goal:** Replicate score computation in Dart (no Python dependency)
- **Consider:** Lightweight alternatives (e.g., using Flutter's image package or native plugins)

---

### Stream C: Single-Branch Training & Evaluation ⏱️

**Priority:** PARALLEL with A, B - needs A to complete

**Goals:** Train each branch independently. Establish baseline performance.

#### Task C1: Create BranchTrainer Class

- **File:** `dualbranch/training/branch_trainer.py`
- **Extends:** `ResNetFineTuneTrainer` with key modifications:
  - Accept input channel count parameter (flexibility for different filter outputs)
  - Modify first conv layer to accept N channels instead of 3
  - Parameterize model type, input channels, branch name

```python
class BranchTrainer(ResNetFineTuneTrainer):
    def __init__(self, branch_name='texture', input_channels=8):
        super().__init__()
        self.branch_name = branch_name
        self.input_channels = input_channels
    
    def set_model(self, model_name='resnet50', pretrained=True):
        # Load standard ResNet, but modify first layer
        self.model = models.resnet50(weights=ResNet50_Weights.DEFAULT)
        
        # Replace first conv layer to accept custom channels
        if self.input_channels != 3:
            original_conv = self.model.conv1
            self.model.conv1 = nn.Conv2d(
                self.input_channels, 64, 
                kernel_size=7, stride=2, padding=3, bias=False
            )
            # Average weights across channels or random init
        
        # Freeze + modify final layer as before
        ...
```

#### Task C2: Train Texture-Focused Branch

- **File:** `scripts/train_texture_branch.py`
- **Input:** Texture-filtered multi-channel images from DataLoader
- **Output:**
  - Trained model: `results/models/texture_branch_*.pt`
  - Metrics: `results/results.csv`

#### Task C3: Train Color-Focused Branch

- **File:** `scripts/train_color_branch.py`
- **Same as C2**, but for color-filtered inputs
- **Output:** `results/models/color_branch_*.pt`

#### Task C4: Individual Branch Evaluation

- **File:** `scripts/evaluate_branches.py`
- **Tasks:**
  - Compare texture vs color branch performance
  - Generate confusion matrices, ROC curves for each
  - Document which captures melanoma features better

---

### Stream D: Fusion & Combination Logic ⏱️

**Priority:** PARALLEL with A, B, C (independent)

**Goals:** Implement both Variant 1 (Fusion) and Variant 2 (Voting). Test on dummy models first.

#### Task D1: Implement FusionLayer Class

- **File:** `dualbranch/models/fusion_layer.py`
- **Variant 1 Architecture:**
  - Input: Two feature vectors of size F (e.g., 512 from ResNet FC layer)
  - Concatenate: `[feat_texture; feat_color]` → 2F-dim vector
  - Dense layers → compressed representation
  - Output: Class probabilities (2 classes: melanoma/nevi)

```python
class FusionLayer(nn.Module):
    def __init__(self, feature_dim=512, hidden_dim=256, num_classes=2):
        super().__init__()
        self.fc1 = nn.Linear(feature_dim * 2, hidden_dim)
        self.relu = nn.ReLU()
        self.dropout = nn.Dropout(0.5)
        self.fc2 = nn.Linear(hidden_dim, num_classes)
    
    def forward(self, feat_texture, feat_color):
        combined = torch.cat([feat_texture, feat_color], dim=1)
        x = self.fc1(combined)
        x = self.relu(x)
        x = self.dropout(x)
        x = self.fc2(x)
        return x
```

#### Task D2: Implement EnsembleVoter Class

- **File:** `dualbranch/models/ensemble_voter.py`
- **Variant 2 Architecture:**
  - Input: Two probability vectors (from separate classifiers on each feature)
  - Soft voting: Average logits or probabilities
  - Optional: Learn voting weights

```python
class EnsembleVoter(nn.Module):
    def __init__(self, feature_dim=512, num_classes=2, learnable_weights=False):
        super().__init__()
        self.classifier_texture = nn.Linear(feature_dim, num_classes)
        self.classifier_color = nn.Linear(feature_dim, num_classes)
        
        if learnable_weights:
            self.weights = nn.Parameter(torch.tensor([0.5, 0.5]))
        else:
            self.weights = torch.tensor([0.5, 0.5])
    
    def forward(self, feat_texture, feat_color):
        logits_texture = self.classifier_texture(feat_texture)
        logits_color = self.classifier_color(feat_color)
        
        # Soft voting: average
        combined_logits = self.weights[0] * logits_texture + self.weights[1] * logits_color
        return combined_logits
```

#### Task D3: Test Fusion & Voting on Dummy Models

- **File:** `tests/test_fusion_voting.py`
- **Goal:** Validate output shapes & behavior WITHOUT training full models
- **Uses:** Random initialized dummy CNNs
- **Test:** Both Variant 1 & 2
- **No GPU needed**, fast validation

```python
def test_fusion_voting():
    # Create dummy branches
    dummy_texture = models.resnet50()
    dummy_color = models.resnet50()
    
    # Create fusion & voter
    fusion = FusionLayer(feature_dim=512)
    voter = EnsembleVoter(feature_dim=512)
    
    # Random batch
    batch_size = 4
    feat_texture = torch.randn(batch_size, 512)
    feat_color = torch.randn(batch_size, 512)
    
    # Test outputs
    fusion_out = fusion(feat_texture, feat_color)
    voter_out = voter(feat_texture, feat_color)
    
    assert fusion_out.shape == (batch_size, 2)
    assert voter_out.shape == (batch_size, 2)
```

#### Task D4: Architecture Comparison Framework

- **File:** `dualbranch/models/variant_comparison.py`
- **Purpose:**
  - Interface for swapping Variant 1 ↔ Variant 2
  - Log performance metrics for both
  - Generate comparison report

#### Task D5: ClassifierHead (Decision Layer)

- **File:** `dualbranch/models/classifier_head.py`
- **Purpose:** Post-fusion/voting processing
- **Options:** SVM, Decision Tree (as mentioned in requirements)
- **For now:** Keep simple (dense network) but allow future extensions

---

### Stream E: Dual-Branch Integration & Full Training ⏱️

**Priority:** AFTER C + D complete

**Goals:** Combine everything. Train Variant 1 end-to-end.

#### Task E1: Create DualBranchModel Class

- **File:** `dualbranch/models/dual_branch_model.py`
- **Purpose:** Wraps two BranchTrainer instances + FusionLayer/EnsembleVoter

```python
class DualBranchModel(nn.Module):
    def __init__(self, texture_branch, color_branch, fusion_variant='fusion'):
        super().__init__()
        self.texture_branch = texture_branch
        self.color_branch = color_branch
        
        if fusion_variant == 'fusion':
            self.combiner = FusionLayer(feature_dim=512)
        else:  # 'voting'
            self.combiner = EnsembleVoter(feature_dim=512)
    
    def forward_features(self, texture_input, color_input):
        """Extract features from both branches"""
        feat_texture = self.texture_branch.extract_features(texture_input)
        feat_color = self.color_branch.extract_features(color_input)
        return feat_texture, feat_color
    
    def forward(self, texture_input, color_input):
        feat_texture, feat_color = self.forward_features(texture_input, color_input)
        logits = self.combiner(feat_texture, feat_color)
        return logits
```

#### Task E2: Create DualBranchTrainer

- **File:** `dualbranch/training/dual_branch_trainer.py`
- **Extends:** Training logic to handle dual inputs
- **Options:**
  - Fine-tune both branches together (end-to-end)
  - Keep branches frozen, only train fusion layer
  - Unfreeze one layer at a time

```python
class DualBranchTrainer:
    def __init__(self, texture_branch_path, color_branch_path, variant='fusion'):
        self.texture_branch = self._load_branch(texture_branch_path)
        self.color_branch = self._load_branch(color_branch_path)
        self.model = DualBranchModel(
            self.texture_branch, 
            self.color_branch, 
            fusion_variant=variant
        )
    
    def train(self, train_loader, val_loader, epochs=20, freeze_branches=False):
        """
        Train dual-branch model.
        
        :param freeze_branches: If True, only train fusion layer
        """
        if freeze_branches:
            for param in self.texture_branch.parameters():
                param.requires_grad = False
            for param in self.color_branch.parameters():
                param.requires_grad = False
```

#### Task E3: Train Variant 1 (Fusion)

- **File:** `scripts/train_dual_branch_fusion.py`
- **Steps:**
  - Use trained branches from C2/C3
  - Train fusion layer (+ optionally fine-tune branches)
  - Save checkpoint: `results/models/dual_branch_fusion_*.pt`

#### Task E4: Train Variant 2 (Ensemble Voting)

- **File:** `scripts/train_dual_branch_voting.py`
- **Same as E3** but with EnsembleVoter
- **Output:** `results/models/dual_branch_voting_*.pt`

#### Task E5: Compare Variants

- **File:** `scripts/compare_variants.py`
- **Evaluate:** Fusion vs Voting on test set
- **Generate:** Side-by-side metrics
  - Accuracy, F1, AUC, Sensitivity, Specificity
  - Inference time
  - Confidence distributions
- **Document:** Which variant wins

---

### Stream F: Mobile Deployment ⏱️

**Priority:** PARALLEL with E (can start after E1)

**Goals:** Export models. Design mobile inference. Support Flutter/Dart.

#### Task F1: PyTorch to TFLite Conversion

- **File:** `scripts/export/pytorch_to_tflite.py`
- **Tasks:**
  - Convert dual-branch model to TFLite
  - Quantize for mobile (INT8 or FLOAT16)
  - Test on mock mobile device
- **Challenge:** TFLite has limited op support; may need conversion via ONNX

#### Task F2: PyTorch to ONNX Conversion

- **File:** `scripts/export/pytorch_to_onnx.py`
- **Tasks:**
  - Export as ONNX (more standard, better tooling)
  - Test with ONNX Runtime
  - Benchmark size & latency

#### Task F3: Comparison & Benchmarking

- **File:** `scripts/export/compare_formats.py`
- **Compare TFLite vs ONNX vs PyTorch:**
  - Model size
  - Inference latency (CPU/GPU on mobile device)
  - Accuracy (ensure no regression)
  - Export complexity

#### Task F4: Mobile Preprocessing Pipeline Design

- **File:** `mobile/lib/utils/image_preprocessing.dart`
- **Tasks:**
  - Implement texture/color filters in Dart (or via native plugin)
  - Test: Can you replicate Python preprocessing in Dart?
  - If not, plan Python backend microservice or pre-compute on device

#### Task F5: Flutter App Architecture

- **File:** `mobile/lib/screens/inference_screen.dart`
- **Design UI for:**
  - Camera capture
  - Image selection
  - Dual-branch inference display
  - Confidence/scores visualization
- **Integration:**
  - Model inference (ONNX Runtime or TFLite)
  - Plan communication with backend if preprocessing is heavy

#### Task F6: Latency & Deployment Testing

- **Deploy** on target mobile device (iOS/Android)
- **Benchmark** end-to-end pipeline:
  - Image capture → preprocessing → inference → result
- **Set latency targets** (e.g., <500ms for real-time)
- **Document** deployment steps

---

## Work Stream Dependencies & Timeline

```
START
  │
  ├─ Stream A (Preprocessing)  ─────────┐
  │   ├─ A1: Texture filters   │        │
  │   ├─ A2: Color filters     │        │
  │   ├─ A3: Batch preprocess  │        │
  │   ├─ A4: Dataset class     │ ~3-5 days
  │   └─ A5: Validation        │        │
  │                            │        │
  └──────────────────────────────────┐  │
                                     │  │
  ├─ Stream B (Scoring)  ────────────┼──┤
  │   ├─ B1: Texture scoring   │      │  │
  │   ├─ B2: Color scoring     │ ~2-3 days
  │   ├─ B3: ScoreComputer     │      │  │
  │   └─ B4: Mobile Dart impl. │      │  │
  │                            │      │  │
  └──────────────────────────┐ │      │  │
                             │ │      │  │
  ├─ Stream C (Single Branch) ├─┴──────┼──────┐
  │   ├─ C1: BranchTrainer    │        │      │
  │   ├─ C2: Train texture    │ ~5-7 days (GPU time)
  │   ├─ C3: Train color      │        │      │
  │   └─ C4: Evaluate         │        │      │
  │                           │        │      │
  └───────────────────────────┴──────┐ │      │
                                     │ │      │
  ├─ Stream D (Fusion/Voting) ───────┼─┤      │
  │   ├─ D1: FusionLayer      │      │ │      │
  │   ├─ D2: EnsembleVoter    │ ~2 days
  │   ├─ D3: Dummy test       │      │ │      │
  │   ├─ D4: Comparison       │      │ │      │
  │   └─ D5: ClassifierHead   │      │ │      │
  │                           │      │ │      │
  └───────────────────────────┴──────┘ │      │
                                       │      │
  ├─ Stream E (Integration)  ─────────┘      │
  │   ├─ E1: DualBranchModel         │       │
  │   ├─ E2: DualBranchTrainer       │ ~3-5 days (GPU time)
  │   ├─ E3: Train Variant 1 (Fusion)│       │
  │   ├─ E4: Train Variant 2 (Voting)│       │
  │   └─ E5: Compare variants         │       │
  │                                   │       │
  └───────────────────────────────────┘       │
                                              │
  ├─ Stream F (Mobile)  ──────────────────────┤
  │   ├─ F1: PyTorch → TFLite         │       │
  │   ├─ F2: PyTorch → ONNX           │ ~3-4 days
  │   ├─ F3: Format comparison        │       │
  │   ├─ F4: Mobile preprocessing     │       │
  │   ├─ F5: Flutter architecture     │       │
  │   └─ F6: Device testing           │       │
  │                                   │       │
  └───────────────────────────────────┘       │
                                              │
                                          END ~4 weeks
```

### Key Parallel Windows

- **Week 1:** Streams A, B, D can run simultaneously (independent)
- **Week 2:** Stream C starts after A completes (needs preprocessed data)
- **Week 3:** Stream E starts after C completes (needs trained branches)
- **Week 3-4:** Stream F runs parallel with E (independent)

---

## Recommended Development Order (if resources are limited)

If you're working solo/small team, prioritize like this:

1. **A → C → E** (Core pipeline first)
2. **B** (Scoring, can integrate later)
3. **D** (Test with dummy models early, refine during E)
4. **F** (Mobile after model is finalized)

---

## Suggested Project Structure

```
dualbranch/
├── preprocessing/
│   ├── __init__.py
│   ├── texture_filters.py          (A1)
│   ├── color_filters.py            (A2)
│   ├── preprocess_dataset.py       (A3)
│   └── validate_preprocessing.py   (A5)
├── scoring/
│   ├── __init__.py
│   ├── texture_scores.py           (B1)
│   ├── color_scores.py             (B2)
│   └── score_computer.py           (B3)
├── models/
│   ├── __init__.py
│   ├── fusion_layer.py             (D1)
│   ├── ensemble_voter.py           (D2)
│   ├── variant_comparison.py       (D4)
│   ├── classifier_head.py          (D5)
│   ├── dual_branch_model.py        (E1)
│   └── branch_utils.py
├── training/
│   ├── __init__.py
│   ├── branch_trainer.py           (C1)
│   └── dual_branch_trainer.py      (E2)
├── ham10000_dataset.py             (extended from yours)
├── utils/
│   ├── metrics.py
│   ├── visualization.py
│   └── config.py
├── scripts/
│   ├── train_texture_branch.py     (C2)
│   ├── train_color_branch.py       (C3)
│   ├── evaluate_branches.py        (C4)
│   ├── train_dual_branch_fusion.py (E3)
│   ├── train_dual_branch_voting.py (E4)
│   ├── compare_variants.py         (E5)
│   └── export/
│       ├── pytorch_to_tflite.py    (F1)
│       ├── pytorch_to_onnx.py      (F2)
│       └── compare_formats.py      (F3)
├── tests/
│   ├── test_fusion_voting.py       (D3)
│   ├── test_preprocessing.py
│   └── test_branches.py
├── mobile/
│   ├── lib/
│   │   ├── utils/
│   │   │   ├── image_preprocessing.dart  (F4)
│   │   │   └── image_scoring.dart        (B4)
│   │   └── screens/
│   │       └── inference_screen.dart     (F5)
│   └── pubspec.yaml
└── results/
    ├── models/
    ├── results.csv
    └── plots/
```