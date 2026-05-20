from datetime import datetime
from pathlib import Path
import gc
import torch
import mlflow

from pipeline.dataclasses.pipeline_config import PipelineConfig
from pipeline.dataclasses.pipeline_runtime import BranchResult

from pipeline.datasets.dataset_loaders.data_loader_factory import DataLoaderFactory
from pipeline.branch_runner import BranchRunner
from pipeline.datasets.split_provider import SplitProvider


class   PipelineOrchestrator:
    """
    PipelineOrchestrator class responsible for orchestrating the entire pipeline execution, including data splitting, branch execution, and result aggregation.
    It handles:
    - Data splitting based on the specified configuration
    - Executing each branch in the pipeline and collecting results
    - Saving results and generating plots for each branch
    - Managing the overall pipeline run and output paths
    """

    def __init__(
        self,
        pipeline_config: PipelineConfig,
        project_root_path: Path,
    ):
        self.pipeline_config = pipeline_config
        self.pipeline_run_path = self._get_pipeline_output_path(self.pipeline_config.pipeline_id, project_root_path)
        self._set_seeds(self.pipeline_config.seed)
        mlflow.set_tracking_uri(f"sqlite:///{project_root_path}/results/mlflow.db")

    def run(self) -> list[BranchResult]:
        """
        Runs the entire pipeline execution, including data splitting, branch execution, and result aggregation.
        Returns:
            list[BranchResult]: A list of results for each branch executed in the pipeline.
        """
        print(f"Starting pipeline run: {self.pipeline_config.pipeline_id}")
        print(f"Pipeline run path: {self.pipeline_run_path}")
        print("-" * 10)

        mlflow.set_experiment(self.pipeline_config.pipeline_id)
        with mlflow.start_run(run_name=self.pipeline_config.pipeline_id):

            train_val_test_split = SplitProvider.get_split(
                self.pipeline_config.data_path, self.pipeline_config.split_config, seed=self.pipeline_config.seed
            )

            mlflow.log_params({
                "split_type": self.pipeline_config.split_config.split_type.value,
                "num_branches": len(self.pipeline_config.branches),
            })

            results = []
            for branch_config in self.pipeline_config.branches:
                self._set_seeds(self.pipeline_config.seed)
                data_loaders = DataLoaderFactory.build(
                    branch_config.dataset_loader,
                    branch_config.branch_model_config.filter_type,
                    branch_config.branch_model_config.model_type,
                    train_val_test_split,
                    self.pipeline_config.data_path,
                    branch_config.trainer_config.batch_size,
                    branch_config.sampler_weights,
                    branch_config.augmentation,
                    seed=self.pipeline_config.seed,
                )

                branch_runner = BranchRunner(branch_config, data_loaders, self.pipeline_run_path, seed=self.pipeline_config.seed)

                branch_result = branch_runner.run()
                results.append(branch_result)

                del branch_runner
                del data_loaders
                gc.collect()
                if torch.cuda.is_available():
                    torch.cuda.empty_cache()

            return results

    def _load_config(self, config_path: Path, data_path: Path) -> PipelineConfig:
        """
        Loads the pipeline configuration from a JSON file.

        Args:
            config_path (Path): The path to the pipeline configuration JSON file.
            data_path (Path): The path to the data directory.
        Returns:
            PipelineConfig: The loaded pipeline configuration.
        """
        config_path = config_path.resolve()
        if not config_path.is_file():
            raise FileNotFoundError(f"Pipeline configuration file not found: {config_path}")

        raw = config_path.read_text()
        pipeline_config = PipelineConfig.model_validate_json(raw)
        return pipeline_config.model_copy(update={"data_path": data_path})

    def _get_pipeline_output_path(self, pipeline_id: str, project_root_path: Path) -> Path:
        """
        Generates the output path for the pipeline run and creates the directory if it doesn't exist.

        Args:
            pipeline_id (str): The identifier for the pipeline run.
            project_root_path (Path): The root path of the project where results should be saved.
        Returns:
            Path: The path where the pipeline results will be saved.
        """
        timestamp = datetime.now().strftime("%Y-%m-%d_%H-%M")  # e.g. 2024-06-01_14-30
        pipeline_run_path = project_root_path / "results" / (pipeline_id + "_" + timestamp)
        pipeline_run_path.mkdir(parents=True, exist_ok=True)
        return pipeline_run_path

    def _set_seeds(self, seed: int) -> None:
        """
        Sets the seed for reproducibility if any was provided.

        Args:
            seed (int): The seed value to be set for random number generators.
        """
        if seed is not None:
            import random
            import numpy as np

            torch.backends.cudnn.deterministic = True
            torch.backends.cudnn.benchmark = False

            random.seed(seed)
            np.random.seed(seed)
            torch.manual_seed(seed)
            if torch.cuda.is_available():
                torch.cuda.manual_seed_all(seed)