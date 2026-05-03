"""
Detailed logging utility for filter implementations to enable comparison
between Python and Flutter versions.
"""
import json
import numpy as np
from pathlib import Path
from datetime import datetime


class FilterLogger:
    """Logs filter computations with full precision for debugging and comparison."""
    
    def __init__(self, log_dir: Path = None, filter_name: str = "filter"):
        """
        Initialize the logger.
        
        Args:
            log_dir: Directory to save logs (default: data/logs)
            filter_name: Name of the filter being logged (e.g., 'gabor', 'glcm')
        """
        if log_dir is None:
            log_dir = Path.cwd().parent.parent / "data" / "logs"
        
        self.log_dir = Path(log_dir)
        self.log_dir.mkdir(parents=True, exist_ok=True)
        
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        self.log_file = self.log_dir / f"{filter_name}_{timestamp}.log"
        self.data_file = self.log_dir / f"{filter_name}_{timestamp}.json"
        
        self.log_data = {
            "timestamp": timestamp,
            "filter": filter_name,
            "entries": []
        }
    
    def log_array(self, name: str, array: np.ndarray, max_elements: int = None):
        """
        Log a numpy array with full precision.
        
        Args:
            name: Name/description of the array
            array: Numpy array to log
            max_elements: Max elements to include (None = all)
        """
        entry = {
            "name": name,
            "dtype": str(array.dtype),
            "shape": list(array.shape),
            "size": int(np.prod(array.shape)),
            "min": float(np.min(array)),
            "max": float(np.max(array)),
            "mean": float(np.mean(array)),
            "std": float(np.std(array)),
        }
        
        # Store full data with full precision
        if max_elements is None or np.prod(array.shape) <= max_elements:
            entry["data"] = array.tolist()
        else:
            # Sample if too large
            flat = array.flatten()
            indices = np.linspace(0, len(flat) - 1, max_elements, dtype=int)
            entry["data_sampled"] = flat[indices].tolist()
            entry["sampled_count"] = int(max_elements)
        
        self.log_data["entries"].append(entry)
        return entry
    
    def log_step(self, step_name: str, description: str = ""):
        """Log a processing step."""
        entry = {
            "step": step_name,
            "description": description,
            "type": "step_marker"
        }
        self.log_data["entries"].append(entry)
    
    def log_scalar(self, name: str, value: float):
        """Log a scalar value."""
        entry = {
            "name": name,
            "value": float(value),
            "type": "scalar"
        }
        self.log_data["entries"].append(entry)
    
    def log_text(self, name: str, text: str):
        """Log text information."""
        entry = {
            "name": name,
            "text": text,
            "type": "text"
        }
        self.log_data["entries"].append(entry)
    
    def save(self):
        """Save all logged data to JSON file."""
        with open(self.data_file, 'w') as f:
            json.dump(self.log_data, f, indent=2)
        
        print(f"Filter log saved: {self.data_file}")
        return self.data_file


def format_array_for_comparison(array: np.ndarray, precision: int = 6) -> str:
    """
    Format numpy array for human-readable comparison output.
    
    Args:
        array: Numpy array to format
        precision: Number of decimal places
    
    Returns:
        Formatted string representation
    """
    np.set_printoptions(precision=precision, suppress=True, threshold=np.inf)
    return str(array)
