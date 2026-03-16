from python.pipeline.json_dataclasses import BranchConfig, TrainValTestDataLoaders
import torch

from python.pipeline.model_factory import ModelFactory
from python.pipeline.trainer import Trainer


class BranchRunner:

    def __init__(self, branch_params: BranchConfig, data: TrainValTestDataLoaders):
        self.branch_params = branch_params
        self.data = data
        self.device = self._get_device()
        self.model = ModelFactory.build(branch_params.model).to(self.device)
        self.trainer = Trainer(self.model, self.branch_params.trainer, self.device)
        self.evaluator = Evaluator(self.model, self.device)

    @staticmethod
    def _get_device() -> torch.device:
        return torch.device("cuda" if torch.cuda.is_available() else "cpu")