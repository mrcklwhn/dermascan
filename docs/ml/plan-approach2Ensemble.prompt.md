Plan: Build Approach 2 Ensemble for Interpretable Melanoma Classification

## Project Goal
**Improve neural network interpretability for skin lesion classification** through domain-specialized preprocessing. The system uses multiple expert CNNs, each focusing on distinct lesion characteristics that a dermatologist would examine (e.g., color distribution, texture/borders, asymmetry). Their predictions are combined via soft voting, with the final ensemble running on mobile (Flutter/iOS/Android) for clinical decision support.

## Overview
Build a modular, mobile-deployable two-branch soft-voting ensemble: define branch configs with branch-specific preprocessing pipelines, train branches independently on pretrained backbones, and implement an inference-time voter that generalizes to 2+ branches and can later be swapped for a learned fusion layer.
For simplicity all branches will use a RGB image input; future extensions may add specialized inputs (e.g., segmentation masks). 
For training purposes the images of the HAM10000 dataset will be transformed with branch-specific filters and stored in separate directories to avoid on-the-fly computation overhead. Inference in flutter will apply the same filters but won't necessarily store the filtered images besides for reproducibility testing.


## Steps

### Phase 1: Config & Data Pipeline
1. **Define ensemble config schema** in python/dualbranch/ensemble_config.py with:
   - Branch registry: id, backbone, pretrained weights, checkpoint path
   - Per-branch transforms (resize, crop, filters like Gabor/LBP for texture, color normalization for RGB)
   - Shared dataset splits (train/val/test CSV paths, seed) and per-branch dataloaders
   - Voting strategy config (weights, tie-breaker, future fusion layer placeholder)
   - Logging/metrics output paths
   - **NEW: Export config** (model serialization format, TensorFlow Lite/ONNX for mobile, preprocessing serialization)

2. **Extend dataset orchestration** in python/dualbranch/ham10000_dataset_manager.py:
   - Load splits once (shared train/val/test indices)
   - Emit per-branch dataloaders with branch-specific transforms/filters applied at dataset level
   - Document filter behavior (Gabor for texture branch, identity for RGB branch) in docs/lesions_classification/filter_experiments.md
   - **NEW: Validate preprocessing** reproducibility (ensure filters/normalization are deterministic for mobile)

### Phase 2: Training & Checkpoint Management
3. **Factor training into reusable branch trainer** from python/dualbranch/ResNetFinetuneTrain.py:
   - Extract train_branch(branch_config, device, data_loaders) function
   - Save per-branch checkpoints, metrics, and preprocessing metadata (filter params, normalization stats) under results/approach2_v1/{branch_id}/
   - Add CLI entry to launch two branch trainings in parallel or sequentially
   - Log training curves (loss, accuracy, F1, AUC) per branch for comparison

### Phase 3: Python-side Inference & Voting
4. **Implement ensemble inference utilities** in python/dualbranch/ensemble_inference.py:
   - load_branch_model(config) → loads checkpoint + preprocessing config
   - soft_vote_predict(models, weights, dataloader) → per-image probabilities for each branch, weighted average, final label
   - Compute ensemble metrics (F1, AUC, sensitivity, specificity) alongside per-branch results
   - **NEW: Export ensemble for mobile**: serialize models to TensorFlow Lite or ONNX; export preprocessing pipeline (filter coefficients, normalization params) as portable config

### Phase 4: Mobile Integration (Flutter)
5. **Mobile inference architecture** (design + implementation roadmap):
   - Each branch model runs independently on device (TensorFlow Lite or similar)
   - Preprocessing pipeline on device: load branch-specific filters and normalization from exported config
   - Soft voting combiner: simple weighted average (no learned fusion layer at v1)
   - Add placeholder for future fusion layer (learned combiner trained on val set)
   - Document in docs/lesions_classification/mobile_inference.md (new)

### Phase 5: Documentation & Playbook
6. **End-to-end runbook** in docs/lesions_classification/machine_learning.md:
   - Prepare ENSEMBLE_CONFIG with branch definitions
   - Train branches (parallel or sequential)
   - Run ensemble evaluation on test set
   - Export models + preprocessing config for Flutter
   - Note integration points: where soft voter becomes fusion layer, how to retrain on new data while keeping other branch frozen
   - Flutter integration example: load TensorFlow Lite models, apply preprocessing, aggregate predictions

## Key Design Decisions
- **Branch independence**: Each branch is trained separately with its own backbone, transforms, and optimizer to allow specialization.
- **Preprocessing as first-class**: Filters/transforms are versioned with models and exported for mobile reproducibility.
- **Soft voting v1, fusion layer ready**: Voting is simple weighted average; infrastructure supports swapping in a learned fusion layer trained on validation set.
- **Mobile-first export**: All model checkpoints and preprocessing configs must be serializable to TensorFlow Lite and portable JSON/binary for Flutter.

## Further Considerations
1. **Assignments**: 
   - Person A: ensemble config schema, dataset orchestration, training refactor
   - Person B: Python inference voter, model export, mobile integration design
   - Agree on ensemble config and export format first (JSON schema for preprocessing, model serialization target)

2. **Testing strategy**: Unit tests for each branch's transform pipeline (determinism), integration tests for soft voting, end-to-end tests with exported mobile models.

3. **Future extensions**: 
   - Add 3+ branches (e.g., asymmetry detector, border analyzer)
   - Implement learned fusion layer (train on val set after branch convergence)
   - Fine-tune voting weights via Bayesian optimization
