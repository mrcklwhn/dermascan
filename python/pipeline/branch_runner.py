import json

from pipeline.metrics_calculator import MetricsCalculator
from pipeline.json_dataclasses import BranchConfig, MetricsType
from pipeline.pipeline_dataclasses import MetricsResult, BranchResult, TrainingHistory, TrainValTestDataLoaders
import torch

from pathlib import Path

from pipeline.model_factory import ModelFactory
from pipeline.trainer import Trainer
from python.pipeline.plotter import Plotter


class BranchRunner:

    def __init__(self,
                 branch_config: BranchConfig,
                 data_loaders: TrainValTestDataLoaders,
                 pipeline_run_path: Path,
                 eval_metrics: list[MetricsType]
                 ):
        self.branch_config = branch_config
        self.data = data_loaders
        self.branch_run_path = self._get_branch_run_path(pipeline_run_path,
                                                               branch_config.branch_model_config.filter_type.filter_name)
        self.device = self._get_device()
        self.model = ModelFactory.build(branch_config.branch_model_config).to(self.device)
        self.trainer = Trainer(
            self.model,
            self.branch_config.trainer_config,
            self.device,
            self.branch_run_path)
        self.eval_metrics = eval_metrics

    def run(self) -> BranchResult:
        training_history = self.trainer.train(self.data.train_loader, self.data.val_loader)
        self._save_training_history(training_history)
        Plotter.plot_training_history(training_history, self.branch_run_path)
        
        eval_results = self.trainer.test(self.data.test_loader)

        metrics_calculator = MetricsCalculator()
        metrics_result = metrics_calculator.calculate(self.eval_metrics, eval_results)
        self._save_metrics(metrics_result)

        Plotter.plot_confusion_matrix(eval_results, self.branch_run_path)

        return BranchResult(
            branch_id=self.branch_config.branch_id,
            training_history=training_history,
            metrics_result=metrics_result
        )

    def _get_branch_run_path(self, pipeline_run_path: Path, filter_name: str) -> Path:
        branch_run_path = pipeline_run_path / filter_name
        branch_run_path.mkdir(parents=True, exist_ok=True)
        return branch_run_path
    
    def _save_training_history(self, history: TrainingHistory) -> None:
        with open(self.branch_run_path / "training_history.json", "w") as f:
            f.write(history.model_dump_json(indent=2))

    def _save_metrics(self, metrics: MetricsResult) -> None:
        with open(self.branch_run_path / "metrics.json", "w") as f:
            f.write(metrics.model_dump_json(indent=2))

    @staticmethod
    def _get_device() -> torch.device:
        device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
        print(f"[BranchRunner] Using device: {device}")
        return device