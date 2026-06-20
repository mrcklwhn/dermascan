import sys
from pathlib import Path

current_dir = Path.cwd()
proj_dir = Path("/home/pichkuril97175/dermascan")
data_dir = Path("/nfs/scratch/students/pichkuril97175/ham10000")

print(f"Project directory set to: {proj_dir}")

# Add the project root to the system path to import local modules
sys.path.insert(0, str(proj_dir / 'python'))

from pipeline.pipeline_orchestrator import PipelineOrchestrator
from pipeline.dataclasses.pipeline_config import PipelineConfig, BranchConfig, ModelConfig, TrainerConfig, TrainValTestSplitRatio, AugmentationConfig, CustomSplitConfig
from pipeline.dataclasses.enums import ModelType, FilterType, DatasetLoaderType, AugmentationType, LossType
from pipeline.dataclasses.training_configs import AdamWConfig, CosineAnnealingLRConfig

pipeline_config = PipelineConfig(
    pipeline_id="efficientnet_refinement",
    data_path=data_dir,
    split_config=CustomSplitConfig(
        train_csv_path=Path(data_dir / "custom" / "train_df.csv"),
        val_csv_path=Path(data_dir / "custom" / "val_df.csv"),
        test_csv_path=Path(data_dir / "custom" / "test_df.csv"),
    ),
    seed=42,
    branches=[
        # Branch 1: best of MiniPC (CE Baseline)
        BranchConfig(
            branch_id="eff_ce_best_known",
            sampler_weights=None,
            branch_model_config=ModelConfig(
                model_type=ModelType.EFFICIENTNET_V2_S,
                filter_type=FilterType.RGB,
                num_classes=2,
                pretrained=True,
                freeze_weights=False,
            ),
            trainer_config=TrainerConfig(
                batch_size=8,
                num_epochs=25,
                learning_rate=0.0003,
                loss_type=LossType.CROSS_ENTROPY,
                pos_weight=1.0,
                class_weights=None,
                optimizer=AdamWConfig(weight_decay=0.0001),
                scheduler=CosineAnnealingLRConfig(t_max=25, eta_min=1e-05),
            ),
            dataset_loader=DatasetLoaderType.RGB,
            augmentation=AugmentationConfig(
                train=[
                    AugmentationType.RANDOM_RESIZE_CROP,
                    AugmentationType.RANDOM_HORIZONTAL_FLIP,
                ],
            ),
        ),

        # Branch 2: CE winner + mild sampler
        BranchConfig(
            branch_id="eff_ce_with_sampler",
            sampler_weights=(1.0, 4.0),
            branch_model_config=ModelConfig(
                model_type=ModelType.EFFICIENTNET_V2_S,
                filter_type=FilterType.RGB,
                num_classes=2,
                pretrained=True,
                freeze_weights=False,
            ),
            trainer_config=TrainerConfig(
                batch_size=8,
                num_epochs=25,
                learning_rate=0.0003,
                loss_type=LossType.CROSS_ENTROPY,
                pos_weight=1.0,
                class_weights=None,
                optimizer=AdamWConfig(weight_decay=0.0001),
                scheduler=CosineAnnealingLRConfig(t_max=25, eta_min=1e-05),
            ),
            dataset_loader=DatasetLoaderType.RGB,
            augmentation=AugmentationConfig(
                train=[
                    AugmentationType.RANDOM_RESIZE_CROP,
                    AugmentationType.RANDOM_HORIZONTAL_FLIP,
                ],
            ),
        ),

        # Branch 3: BCE with stronger regularization + fixed t_max=num_epochs
        BranchConfig(
            branch_id="eff_bce_strong_reg",
            sampler_weights=(1.0, 7.0),
            branch_model_config=ModelConfig(
                model_type=ModelType.EFFICIENTNET_V2_S,
                filter_type=FilterType.RGB,
                num_classes=1,
                pretrained=True,
                freeze_weights=False,
            ),
            trainer_config=TrainerConfig(
                batch_size=16,
                num_epochs=30,
                learning_rate=0.0001,
                loss_type=LossType.BCE_WITH_LOGITS,
                pos_weight=8.0,
                class_weights=None,
                optimizer=AdamWConfig(weight_decay=0.005),
                scheduler=CosineAnnealingLRConfig(t_max=30, eta_min=1e-06),
            ),
            dataset_loader=DatasetLoaderType.RGB,
            augmentation=AugmentationConfig(
                train=[
                    AugmentationType.RANDOM_RESIZE_CROP,
                    AugmentationType.RANDOM_HORIZONTAL_FLIP,
                    AugmentationType.RANDOM_VERTICAL_FLIP,
                    AugmentationType.RANDOM_ROTATION,
                    AugmentationType.COLOR_JITTER,
                ],
            ),
        ),

        # Branch 4: BCE with halved class penalty
        BranchConfig(
            branch_id="eff_bce_lower_penalty",
            sampler_weights=(1.0, 4.0),
            branch_model_config=ModelConfig(
                model_type=ModelType.EFFICIENTNET_V2_S,
                filter_type=FilterType.RGB,
                num_classes=1,
                pretrained=True,
                freeze_weights=False,
            ),
            trainer_config=TrainerConfig(
                batch_size=16,
                num_epochs=30,
                learning_rate=0.0001,
                loss_type=LossType.BCE_WITH_LOGITS,
                pos_weight=4.0,
                class_weights=None,
                optimizer=AdamWConfig(weight_decay=0.005),
                scheduler=CosineAnnealingLRConfig(t_max=30, eta_min=1e-06),
            ),
            dataset_loader=DatasetLoaderType.RGB,
            augmentation=AugmentationConfig(
                train=[
                    AugmentationType.RANDOM_RESIZE_CROP,
                    AugmentationType.RANDOM_HORIZONTAL_FLIP,
                    AugmentationType.RANDOM_VERTICAL_FLIP,
                    AugmentationType.RANDOM_ROTATION,
                    AugmentationType.COLOR_JITTER,
                ],
            ),
        ),

        # Branch 5: CE + class_weights only
        BranchConfig(
            branch_id="eff_ce_class_weights_only",
            sampler_weights=None,
            branch_model_config=ModelConfig(
                model_type=ModelType.EFFICIENTNET_V2_S,
                filter_type=FilterType.RGB,
                num_classes=2,
                pretrained=True,
                freeze_weights=False,
            ),
            trainer_config=TrainerConfig(
                batch_size=16,
                num_epochs=25,
                learning_rate=0.0001,
                loss_type=LossType.CROSS_ENTROPY,
                pos_weight=1.0,
                class_weights=(1.0, 7.0),
                optimizer=AdamWConfig(weight_decay=0.0001),
                scheduler=CosineAnnealingLRConfig(t_max=25, eta_min=1e-05),
            ),
            dataset_loader=DatasetLoaderType.RGB,
            augmentation=AugmentationConfig(
                train=[
                    AugmentationType.RANDOM_RESIZE_CROP,
                    AugmentationType.RANDOM_HORIZONTAL_FLIP,
                ],
            ),
        ),

        # Branch 6: CE + class_weights + mild sampler
        BranchConfig(
            branch_id="eff_ce_class_weights_plus_sampler",
            sampler_weights=(1.0, 4.0),
            branch_model_config=ModelConfig(
                model_type=ModelType.EFFICIENTNET_V2_S,
                filter_type=FilterType.RGB,
                num_classes=2,
                pretrained=True,
                freeze_weights=False,
            ),
            trainer_config=TrainerConfig(
                batch_size=16,
                num_epochs=25,
                learning_rate=0.0001,
                loss_type=LossType.CROSS_ENTROPY,
                pos_weight=1.0,
                class_weights=(1.0, 4.0),
                optimizer=AdamWConfig(weight_decay=0.0001),
                scheduler=CosineAnnealingLRConfig(t_max=25, eta_min=1e-05),
            ),
            dataset_loader=DatasetLoaderType.RGB,
            augmentation=AugmentationConfig(
                train=[
                    AugmentationType.RANDOM_RESIZE_CROP,
                    AugmentationType.RANDOM_HORIZONTAL_FLIP,
                ],
            ),
        ),

        # Branch 7: CE + class_weights + stronger regularization
        BranchConfig(
            branch_id="eff_ce_class_weights_strong_reg",
            sampler_weights=None,
            branch_model_config=ModelConfig(
                model_type=ModelType.EFFICIENTNET_V2_S,
                filter_type=FilterType.RGB,
                num_classes=2,
                pretrained=True,
                freeze_weights=False,
            ),
            trainer_config=TrainerConfig(
                batch_size=16,
                num_epochs=25,
                learning_rate=0.0001,
                loss_type=LossType.CROSS_ENTROPY,
                pos_weight=1.0,
                class_weights=(1.0, 7.0),
                optimizer=AdamWConfig(weight_decay=0.001),
                scheduler=CosineAnnealingLRConfig(t_max=25, eta_min=1e-05),
            ),
            dataset_loader=DatasetLoaderType.RGB,
            augmentation=AugmentationConfig(
                train=[
                    AugmentationType.RANDOM_RESIZE_CROP,
                    AugmentationType.RANDOM_HORIZONTAL_FLIP,
                ],
            ),
        ),

        # Branch 8: CE + moderate class_weights
        BranchConfig(
            branch_id="eff_ce_class_weights_moderate",
            sampler_weights=None,
            branch_model_config=ModelConfig(
                model_type=ModelType.EFFICIENTNET_V2_S,
                filter_type=FilterType.RGB,
                num_classes=2,
                pretrained=True,
                freeze_weights=False,
            ),
            trainer_config=TrainerConfig(
                batch_size=16,
                num_epochs=25,
                learning_rate=0.0001,
                loss_type=LossType.CROSS_ENTROPY,
                pos_weight=1.0,
                class_weights=(1.0, 3.0),
                optimizer=AdamWConfig(weight_decay=0.0001),
                scheduler=CosineAnnealingLRConfig(t_max=25, eta_min=1e-05),
            ),
            dataset_loader=DatasetLoaderType.RGB,
            augmentation=AugmentationConfig(
                train=[
                    AugmentationType.RANDOM_RESIZE_CROP,
                    AugmentationType.RANDOM_HORIZONTAL_FLIP,
                ],
            ),
        ),

        # Branch 9: CE + class_weights, pretrained=False
        BranchConfig(
            branch_id="eff_ce_class_weights_no_pretrain",
            sampler_weights=None,
            branch_model_config=ModelConfig(
                model_type=ModelType.EFFICIENTNET_V2_S,
                filter_type=FilterType.RGB,
                num_classes=2,
                pretrained=False,
                freeze_weights=False,
            ),
            trainer_config=TrainerConfig(
                batch_size=16,
                num_epochs=35,
                learning_rate=0.0001,
                loss_type=LossType.CROSS_ENTROPY,
                pos_weight=1.0,
                class_weights=(1.0, 7.0),
                optimizer=AdamWConfig(weight_decay=0.001),
                scheduler=CosineAnnealingLRConfig(t_max=35, eta_min=1e-05),
            ),
            dataset_loader=DatasetLoaderType.RGB,
            augmentation=AugmentationConfig(
                train=[
                    AugmentationType.RANDOM_RESIZE_CROP,
                    AugmentationType.RANDOM_HORIZONTAL_FLIP,
                    AugmentationType.RANDOM_VERTICAL_FLIP,
                    AugmentationType.RANDOM_ROTATION,
                    AugmentationType.COLOR_JITTER,
                ],
            ),
        ),
    ],
)

pipeline_runner = PipelineOrchestrator(
    pipeline_config=pipeline_config,
    project_root_path=proj_dir,
)

run = pipeline_runner.run()