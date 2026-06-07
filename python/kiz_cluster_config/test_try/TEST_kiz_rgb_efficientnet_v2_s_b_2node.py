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
    pipeline_id="kiz_rgb_efficientnet_v2_s_b_2node",
    data_path=data_dir,
    split_config=CustomSplitConfig(
        train_csv_path=Path(data_dir / "custom" / "train_df.csv"),
        val_csv_path=Path(data_dir / "custom" / "val_df.csv"),
        test_csv_path=Path(data_dir / "custom" / "test_df.csv"),
    ),
    seed=42,
    branches=[
        BranchConfig(
            branch_id="efficientnet_v2_s",
            sampler_weights=None,
            branch_model_config=ModelConfig(
                model_type=ModelType.EFFICIENTNET_V2_S,
                filter_type=FilterType.RGB,
                num_classes=2,
                pretrained=True,
                freeze_weights=False
            ),
            trainer_config=TrainerConfig(
                batch_size=16,
                num_epochs=1,
                learning_rate=0.0003,
                loss_type=LossType.CROSS_ENTROPY,
                pos_weight=1.0,
                class_weights=None,
                optimizer=AdamWConfig(weight_decay=0.0001),
                scheduler=CosineAnnealingLRConfig(t_max=30, eta_min=0.00001),
            ),
            dataset_loader=DatasetLoaderType.RGB,
            augmentation=AugmentationConfig(
                train=[
                    AugmentationType.RANDOM_RESIZE_CROP,
                ],
                val=[
                    AugmentationType.RESIZE
                ]
            ),
        ),
    ]
)

pipeline_runner = PipelineOrchestrator(
    pipeline_config=pipeline_config,
    project_root_path=proj_dir,
)

run = pipeline_runner.run()