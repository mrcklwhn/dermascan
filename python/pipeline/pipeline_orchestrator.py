from datetime import datetime
from pathlib import Path

from pandas import DataFrame

from pipeline.branch_runner import BranchRunner
from pipeline.data_loader_factory import DataLoaderFactory
from pipeline.json_dataclasses import PipelineConfig
from pipeline.pipeline_dataclasses import BranchResult
from pipeline.split_provider import SplitProvider


class PipelineOrchestrator:
    def __init__(
        self,
        pipeline_config: PipelineConfig,
        project_root_path: Path,
    ):
        self.pipeline_config = pipeline_config
        self.pipeline_run_path = self._get_pipeline_output_path(
            pipeline_config.pipeline_id, project_root_path
        )

    def run(self) -> list[BranchResult]:
        print(f"Starting pipeline run: {self.pipeline_config.pipeline_id}")
        print(f"Pipeline run path: {self.pipeline_run_path}")
        print("-" * 10)
        train_val_test_split = SplitProvider.get_split(
            self.pipeline_config.data_path, self.pipeline_config.split_config
        )

        results = []
        for branch_config in self.pipeline_config.branches:
            data_loaders = DataLoaderFactory.build(
                branch_config.dataset_loader,
                branch_config.branch_model_config.filter_type,
                train_val_test_split,
                self.pipeline_config.data_path,
                branch_config.trainer_config.batch_size,
                branch_config.augmentation,
            )

            branch_runner = BranchRunner(
                branch_config, data_loaders, self.pipeline_run_path, self.pipeline_config.eval_metrics
            )

            results.append(branch_runner.run())

        return results

    def _get_pipeline_output_path(
        self, pipeline_id: str, project_root_path: Path
    ) -> Path:
        timestamp = datetime.now().strftime("%Y-%m-%d_%H-%M")  # e.g. 2024-06-01_14-30
        pipeline_run_path = project_root_path / "results" / (pipeline_id + "_" + timestamp)
        pipeline_run_path.mkdir(parents=True, exist_ok=True)
        return pipeline_run_path
