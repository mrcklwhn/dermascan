from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Callable, Dict, List, Optional, Sequence, Tuple
from abc import ABC, abstractmethod


class EnsembleBaseModel(ABC):
    """
    Abstract base class that encapsulates the model weights, image loading,
    and a general method to do inference for ensemble voting.
    """
    def __init__(self, model_id: str, model_path: str):
        self.model_id = model_id
        self.model_path = model_path
        self.model = self.load_model()

    @abstractmethod
    def load_model(self) -> Any:
        pass

    @abstractmethod
    def load_image(self, image_info: Any) -> Any:
        pass

    @abstractmethod
    def predict_proba(self, image_tensor: Any) -> Sequence[float]:
        pass

    def run_inference(self, image_info: Any) -> Sequence[float]:
        """Loads the specific image format and runs inference."""
        image_tensor = self.load_image(image_info)
        return self.predict_proba(image_tensor)


@dataclass(frozen=True)
class BranchResult:
    """
    Represents the result of a single model's inference branch.
    
    Args:
        model_id: The unique identifier of the model.
        probs: The list of probabilities for each class.
        label: The predicted label index.
        confidence: The confidence score of the prediction.
    """
    model_id: str
    probs: List[float]
    label: int
    confidence: float


@dataclass(frozen=True)
class EnsembleOutput:
    """
    Represents the aggregated output of the ensemble voting process.
    
    Args:
        strategy: The voting strategy used ("soft" or "hard").
        label: The final predicted label index.
        confidence: The confidence score of the final prediction. 
            For soft voting, this is the sum of the weighted probabilities for 
            the predicted class. For hard voting, this is derived from the votes.
        probs: The aggregated probabilities for each class.
        branch_results: The list of individual model inference results.
    """
    strategy: str
    label: int
    confidence: float
    probs: List[float]
    branch_results: List[BranchResult]


class EnsembleVoter:
    """
    Sequentially loads models, runs inference, and aggregates via voting.
    
    Args:
        model_specs: A sequence of EnsembleBaseModel instances defining the models to use.
        strategy: The voting strategy to use ("soft" or "hard").
        weights: Optional dict mapping model_id to a weight for soft voting.
        tie_breaker: The method to resolve ties in hard voting ("max_prob", "avg_prob", "first").
        label_names: Optional list of label names for more readable output.
        verbose: If True, prints a summary of the voting process and results.
    """

    def __init__(
        self,
        model_specs: Sequence[EnsembleBaseModel],
        strategy: str = "soft",
        weights: Optional[Dict[str, float]] = None,
        tie_breaker: str = "max_prob",
        label_names: Optional[Sequence[str]] = None,
        verbose: bool = True,
    ) -> None:
        self.model_specs = list(model_specs)
        self.strategy = strategy.lower()
        self.weights = weights or {}
        self.tie_breaker = tie_breaker.lower()
        self.label_names = list(label_names) if label_names else None
        self.verbose = verbose

        if self.strategy not in {"soft", "hard"}:
            raise ValueError("strategy must be 'soft' or 'hard'")
        if self.tie_breaker not in {"max_prob", "avg_prob", "first"}:
            raise ValueError("tie_breaker must be 'max_prob', 'avg_prob', or 'first'")

    def run(self, image: Any) -> EnsembleOutput:
        """
        Runs inference on the given image using all models and aggregates the results.

        Args:
            image: The input image to classify. The format is determined by the models' predict_proba functions.
        Returns:
            An EnsembleOutput containing the final prediction and details of the voting process.
        """

        branch_results: List[BranchResult] = []

        for spec in self.model_specs:
            probs_seq = spec.run_inference(image)
            probs = self._normalize_probs(list(probs_seq))
            label = int(max(range(len(probs)), key=lambda i: probs[i]))
            confidence = float(probs[label])
            branch_results.append(
                BranchResult(
                    model_id=spec.model_id,
                    probs=probs,
                    label=label,
                    confidence=confidence,
                )
            )

        if not branch_results:
            raise ValueError("No models provided")

        if self.strategy == "soft":
            probs = self._soft_vote(branch_results)
            label = int(max(range(len(probs)), key=lambda i: probs[i]))
            confidence = float(probs[label])
        else:
            label, confidence, probs = self._hard_vote(branch_results)

        output = EnsembleOutput(
            strategy=self.strategy,
            label=label,
            confidence=confidence,
            probs=probs,
            branch_results=branch_results,
        )

        if self.verbose:
            self._print_summary(output)

        return output

    def _soft_vote(self, results: Sequence[BranchResult]) -> List[float]:
        """
        Helper function that averages the probabilities from each model, weighted if specified.
        
        Args:
            results: A sequence of BranchResult instances from each model.
        Returns:
            A list of aggregated probabilities for each class.
        """

        num_classes = self._get_num_classes(results)
        totals = [0.0 for _ in range(num_classes)]
        weight_total = 0.0

        for result in results:
            w = self._get_weight(result.model_id)
            for i in range(num_classes):
                totals[i] += result.probs[i] * w
            weight_total += w

        if weight_total == 0:
            weight_total = float(len(results))

        return [t / weight_total for t in totals]

    def _hard_vote(self, results: Sequence[BranchResult]) -> Tuple[int, float, List[float]]:
        """
        Helper function that aggregates the majority vote across models, weighted if specified.

        Args:
            results: A sequence of BranchResult instances from each model.
        Returns:
            - Predicted label index.
            - Confidence score derived from the votes.
            - A list of vote counts (or weighted votes) for each class.
        """

        num_classes = self._get_num_classes(results)
        votes = [0.0 for _ in range(num_classes)]

        for result in results:
            votes[result.label] += self._get_weight(result.model_id)

        max_vote = max(votes)
        tied_labels = [i for i, v in enumerate(votes) if v == max_vote]

        if len(tied_labels) == 1:
            label = tied_labels[0]
        else:
            label = self._resolve_tie(tied_labels, results)

        # Derive a probability-like vector for transparency
        total_votes = sum(votes) or 1.0
        probs = [v / total_votes for v in votes]

        confidence = self._confidence_from_results(label, results)
        return label, confidence, probs

    def _resolve_tie(self, tied_labels: Sequence[int], results: Sequence[BranchResult]) -> int:
        """
        Helper function to resolve ties in hard voting based on the specified tie-breaking strategy.

        Args:
            tied_labels: A sequence of label indices that are tied for the most votes.
            results: The original BranchResult instances to use for tie-breaking.
        Returns:
            The resolved label index after applying the tie-breaking strategy.
        """

        if self.tie_breaker == "first":
            return tied_labels[0]

        if self.tie_breaker == "max_prob":
            best_label = tied_labels[0]
            best_conf = -1.0
            for result in results:
                if result.label in tied_labels and result.confidence > best_conf:
                    best_label = result.label
                    best_conf = result.confidence
            return best_label

        # avg_prob
        averages: Dict[int, float] = {label: 0.0 for label in tied_labels}
        counts: Dict[int, int] = {label: 0 for label in tied_labels}
        for result in results:
            for label in tied_labels:
                averages[label] += result.probs[label]
                counts[label] += 1
        for label in tied_labels:
            averages[label] /= counts[label] or 1
        return max(averages, key=averages.get)

    def _confidence_from_results(self, label: int, results: Sequence[BranchResult]) -> float:
        """
        Helper function to derive a confidence score for the final predicted label in hard voting.

        Args:
            label: The final predicted label index.
            results: The original BranchResult instances to use for deriving confidence.
        Returns:
            The proportion of models that predicted the final label.
        """
        vote_count = sum(1 for result in results if result.label == label)
        return float(vote_count) / float(len(results))

    def _get_weight(self, model_id: str) -> float:
        """
        Helper function to get the weight for a given model ID.
        Args:
            model_id: The unique identifier of the model.
        Returns:
            The weight for the model defined in the initial configuration, 
            defaulting to 1.0 if not specified.
        """

        return float(self.weights.get(model_id, 1.0))

    def _get_num_classes(self, results: Sequence[BranchResult]) -> int:
        """
        Helper function to determine the number of classes from the model outputs, ensuring consistency across models.
        
        Args:
            results: A sequence of BranchResult instances from each model.
        Returns:            
            The number of classes as determined from the first model's output, after validating that all models return
        """

        num_classes = len(results[0].probs)
        for result in results[1:]:
            if len(result.probs) != num_classes:
                raise ValueError("All models must return the same number of classes")
        return num_classes

    def _normalize_probs(self, probs: List[float]) -> List[float]:
        """
        Helper function to normalize a list of probabilities ensuring they sum to 1. 
        This is important when models don't return per class probabilities or when they return unnormalized scores.
        
        Args:
            probs: A list of probabilities or scores for each class.
        Returns:
            A normalized list of probabilities that sum to 1.
        """

        total = sum(probs)
        if total <= 0:
            raise ValueError("Model returned non-positive probabilities")
        return [p / total for p in probs]

    def _label_name(self, label: int) -> str:
        """
        Helper function to get the human-readable label name for a given label index, if label names are provided.
        
        Args:
            label: The label index to convert to a name.
        Returns:
            The human-readable label name if available, otherwise the string representation of the label index.
        """
        if self.label_names and 0 <= label < len(self.label_names):
            return self.label_names[label]
        return str(label)

    def _print_summary(self, output: EnsembleOutput) -> None:
        """
        Helper function to print a summary of the ensemble voting process and results in a human-readable format.
        - The voting strategy used.
        - The output of each branch (model), including the predicted label, confidence, and probabilities.
        - The final predicted label, confidence, and probabilities after aggregation.

        Args:
            output: The EnsembleOutput instance containing the results to summarize.
        """

        print("Ensemble voting summary")
        print(f"Strategy: {output.strategy}")
        
        final_label = output.label
        final_label_name = self._label_name(final_label)

        print(f"{'Model':<15} | {'Predicted':<15} | {'Match?':<6} | {'Confidence':<10} | {'Prob(Final)':<11}")
        print("-" * 66)
        
        for result in output.branch_results:
            pred_name = self._label_name(result.label)
            match = "Yes" if result.label == final_label else "No"
            prob_final = result.probs[final_label]
            
            print(
                f"{result.model_id:<15} | {pred_name:<15} | {match:<6} | {result.confidence:<10.4f} | {prob_final:<11.4f}"
            )

        match = "Yes" if output.label == final_label else "No"
        print("-" * 66)
        print(
            f"{'Ensemble':<15} | {final_label_name:<15} | {match:<6} | {output.confidence:<10.4f} | {output.probs[final_label]:<11.4f}"
        )
