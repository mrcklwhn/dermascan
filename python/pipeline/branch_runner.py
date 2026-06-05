from pathlib import Path
import torch
import mlflow

from pipeline.dataclasses.pipeline_config import BranchConfig
from pipeline.dataclasses.pipeline_runtime import BranchResult, MetricsResult, TrainingHistory, TrainValTestDataLoaders
from pipeline.utils.metrics_calculator import MetricsCalculator
from pipeline.utils.plotter import Plotter
from pipeline.utils.mlflow_logger import MLFlowLogger
from pipeline.training.model_factory import ModelFactory
from pipeline.training.trainer import Trainer


class BranchRunner:
    """
    BranchRunner class responsible for executing the training and evaluation of a single branch in the pipeline.
    It handles:
    - Model initialization based on the branch configuration
    - Training the model and saving training history
    - Evaluating the model on the test set and calculating metrics
    - Saving metrics results and generating plots
    - Logging all relevant information to MLflow for experiment tracking
    The BranchRunner is designed to be modular and reusable for different branches with varying configurations.
    """
    def __init__(self,
                 branch_config: BranchConfig,
                 data_loaders: TrainValTestDataLoaders,
                 pipeline_run_path: Path,
                 seed: int | None = None
                 ):
        """
        Initializes the BranchRunner with the given branch configuration, data loaders, and pipeline run path.

        Args:
            branch_config (BranchConfig): Configuration for the branch, including model and training settings.
            data_loaders (TrainValTestDataLoaders): Data loaders for training, validation, and testing.
            pipeline_run_path (Path): Path to save the results of this branch run.
            seed (int | None): The seed for reproducibility.
        """
        self.branch_config = branch_config
        self.data = data_loaders
        self.branch_run_path = self._get_branch_run_path(pipeline_run_path,
                                                         branch_config.branch_id,
                                                         branch_config.branch_model_config.filter_type.filter_name)
        self.device = self._get_device()
        self.model = ModelFactory.build(branch_config.branch_model_config, seed=seed).to(self.device)
        self.trainer = Trainer(
            self.model,
            self.branch_config.trainer_config,
            self.device,
            self.branch_run_path
            )

    def run(self) -> BranchResult:
        """
        Runs the training and evaluation process for the branch.

        Returns:
            BranchResult: The result of the branch execution, including training history and metrics.
        """
        with mlflow.start_run(run_name=self.branch_config.branch_id, nested=True):
            print(f"[BranchRunner] Starting run for branch: {self.branch_config.branch_id}")

            self._save_branch_config()
            MLFlowLogger.log_branch_params(self.branch_config)
            
            training_history = self.trainer.train(self.data.train_loader, self.data.val_loader)
            self._save_training_history(training_history)
            Plotter.plot_training_history(training_history, self.branch_run_path)

            val_result, _ = self.trainer.test(self.data.val_loader, threshold=0.5)

            metrics_calculator = MetricsCalculator()
            optimal_threshold = metrics_calculator.get_threshold(val_result.y_true.numpy(), val_result.y_prob.numpy())
            print(f"Optimal threshold found: {optimal_threshold}")
            MLFlowLogger.log_param("optimal_threshold", optimal_threshold)
            
            test_results, self.model = self.trainer.test(self.data.test_loader, threshold=optimal_threshold)

            metrics_result = metrics_calculator.get_eval_metrics(test_results)
            self._save_metrics(metrics_result)

            Plotter.plot_confusion_matrix(test_results, self.branch_run_path)
            Plotter.plot_precision_recall_curve(test_results, self.branch_run_path)
            Plotter.plot_roc_curve(test_results, self.branch_run_path)
            Plotter.plot_confidence_distribution(test_results, self.branch_run_path)

            MLFlowLogger.log_branch_results(self.branch_run_path, metrics_result)
            sample_input, _ = next(iter(self.data.test_loader))
            MLFlowLogger.log_model(self.model, self.branch_config.branch_id, sample_input[:1].cpu(), step=training_history.best_epoch)

            return BranchResult(
                branch_id=self.branch_config.branch_id,
                training_history=training_history,
                metrics_result=metrics_result
            )

    def _get_branch_run_path(self, pipeline_run_path: Path, branch_id: str, filter_name: str) -> Path:
        """
        Generates the path for the branch run and creates the directory if it doesn't exist.

        Args:
            pipeline_run_path (Path): The base path for the pipeline run.
            branch_id (str): The identifier for the branch.
            filter_name (str): The name of the filter used in the model.
        Returns:
            Path: The path for the branch run.
        """
        branch_run_path = pipeline_run_path / f"{branch_id}_{filter_name}"
        branch_run_path.mkdir(parents=True, exist_ok=True)
        return branch_run_path
    
    def _save_training_history(self, history: TrainingHistory) -> None:
        """
        Saves the training history to a JSON file in the branch run path.

        Args:
            history (TrainingHistory): The training history to be saved.
        """
        with open(self.branch_run_path / "training_history.json", "w") as f:
            f.write(history.model_dump_json(indent=2))

    def _save_branch_config(self) -> None:
        """
        Saves the branch configuration to a JSON file in the branch run path for auditing.
        """
        with open(self.branch_run_path / "branch_config.json", "w") as f:
            f.write(self.branch_config.model_dump_json(indent=2))

    def _save_metrics(self, metrics: MetricsResult) -> None:
        """
        Saves the evaluation metrics to a JSON file in the branch run path.

        Args:
            metrics (MetricsResult): The metrics to be saved.
        """
        with open(self.branch_run_path / "metrics.json", "w") as f:
            f.write(metrics.model_dump_json(indent=2))

    @staticmethod
    def _get_device() -> torch.device:
        """
        Determines the device to be used for training and evaluation.

        Returns:
            torch.device: The device to be used (CUDA if available, otherwise CPU).
        """
        device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
        if not torch.cuda.is_available():
            print("[BranchRunner] CUDA is not available. Using CPU for training and evaluation.")
        return device