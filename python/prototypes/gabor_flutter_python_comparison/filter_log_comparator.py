"""
Comparison utility for Gabor and GLCM filter logs from Python and Flutter.
Reads JSON log files and generates a detailed comparison report.
"""

import json
from pathlib import Path
from typing import Dict, List, Any, Tuple
import numpy as np


class FilterLogComparator:
    """Compares filter logs from Python and Flutter implementations."""

    def __init__(self, python_log: Path, flutter_log: Path):
        """
        Initialize comparator with two log files.

        Args:
            python_log: Path to Python filter log JSON
            flutter_log: Path to Flutter filter log JSON
        """
        self.python_log = python_log
        self.flutter_log = flutter_log

        # Load logs
        with open(python_log) as f:
            self.python_data = json.load(f)

        with open(flutter_log) as f:
            self.flutter_data = json.load(f)

        self.report = []

    def compare_arrays(
        self,
        py_entry: Dict[str, Any],
        flutter_entry: Dict[str, Any],
        tolerance: float = 1e-5,
    ) -> Dict[str, Any]:
        """
        Compare two array entries with statistical analysis.
        Handles both full arrays (Python) and sampled arrays (Flutter with sample_indices).

        Args:
            py_entry: Python entry from log
            flutter_entry: Flutter entry from log
            tolerance: Tolerance for difference checking

        Returns:
            Comparison result dictionary
        """
        result = {
            "name": py_entry.get("name", "unknown"),
            "python": {
                "dtype": py_entry.get("dtype"),
                "shape": py_entry.get("shape"),
                "min": py_entry.get("min"),
                "max": py_entry.get("max"),
                "mean": py_entry.get("mean"),
                "std": py_entry.get("std"),
            },
            "flutter": {
                "dtype": flutter_entry.get("dtype"),
                "shape": flutter_entry.get("shape"),
                "min": flutter_entry.get("min"),
                "max": flutter_entry.get("max"),
                "mean": flutter_entry.get("mean"),
                "std": flutter_entry.get("std"),
            },
        }

        # Compare data arrays
        if "data" in py_entry and "data" in flutter_entry:
            py_data_full = np.array(py_entry["data"]).flatten()
            flutter_data = np.array(flutter_entry["data"]).flatten()
            
            # Check if Flutter data is sampled (has sample_indices)
            if "sample_indices" in flutter_entry:
                # Flutter has sampled data - extract same indices from Python full array
                sample_indices = flutter_entry["sample_indices"]
                py_data_sampled = py_data_full[sample_indices]
                
                result["comparison_mode"] = "sampled"
                result["sample_count"] = len(sample_indices)
                result["python_full_shape"] = py_data_full.shape
                result["flutter_sampled_shape"] = flutter_data.shape
                
                # Compare sampled data
                diff = np.abs(py_data_sampled - flutter_data)
                result["max_absolute_diff"] = float(np.max(diff))
                result["mean_absolute_diff"] = float(np.mean(diff))
                result["relative_diff_percent"] = float(
                    np.mean(diff / (np.abs(py_data_sampled) + 1e-10)) * 100
                )
                result["within_tolerance"] = bool(
                    np.allclose(
                        py_data_sampled,
                        flutter_data,
                        atol=tolerance,
                        rtol=1e-4,
                    )
                )
            else:
                # Both have full arrays - compare directly
                result["comparison_mode"] = "full"
                
                # Check shapes match
                if py_data_full.shape != flutter_data.shape:
                    result["shape_match"] = False
                    result["shape_mismatch"] = f"Python: {py_data_full.shape}, Flutter: {flutter_data.shape}"
                else:
                    result["shape_match"] = True

                    # Calculate differences
                    diff = np.abs(py_data_full - flutter_data)
                    result["max_absolute_diff"] = float(np.max(diff))
                    result["mean_absolute_diff"] = float(np.mean(diff))
                    result["relative_diff_percent"] = float(
                        np.mean(diff / (np.abs(py_data_full) + 1e-10)) * 100
                    )

                    # Check if within tolerance
                    result["within_tolerance"] = bool(
                        np.allclose(
                            py_data_full,
                            flutter_data,
                            atol=tolerance,
                            rtol=1e-4,
                        )
                    )

        return result

    def find_matching_entry(
        self,
        entries: List[Dict],
        name: str,
        entry_type: str = None,
    ) -> Dict[str, Any]:
        """
        Find an entry by name in a list of entries.

        Args:
            entries: List of log entries
            name: Name to search for
            entry_type: Optional type filter

        Returns:
            Matching entry or None
        """
        for entry in entries:
            if entry.get("name") == name:
                if entry_type is None or entry.get("type") == entry_type:
                    return entry
        return None

    def compare_step(self, step_name: str) -> Dict[str, Any]:
        """
        Compare entries from a specific processing step.

        Args:
            step_name: Name of the step to compare

        Returns:
            Step comparison results
        """
        py_entries = [e for e in self.python_data["entries"] if e.get("step") == step_name]
        flutter_entries = [e for e in self.flutter_data["entries"] if e.get("step") == step_name]

        return {
            "step": step_name,
            "python_count": len(py_entries),
            "flutter_count": len(flutter_entries),
            "python_entries": py_entries,
            "flutter_entries": flutter_entries,
        }

    def generate_report(self, output_file: Path = None) -> str:
        """
        Generate comprehensive comparison report.

        Args:
            output_file: Optional file to save report

        Returns:
            Report as string
        """
        lines = []
        lines.append("=" * 100)
        lines.append("GABOR FILTER COMPARISON REPORT - Python vs Flutter")
        lines.append("=" * 100)

        lines.append(f"\nPython log: {self.python_log}")
        lines.append(f"Flutter log: {self.flutter_log}")
        lines.append(f"Python timestamp: {self.python_data.get('timestamp')}")
        lines.append(f"Flutter timestamp: {self.flutter_data.get('timestamp')}")

        # Count entries by type
        py_array_entries = [e for e in self.python_data["entries"] if "data" in e]
        flutter_array_entries = [e for e in self.flutter_data["entries"] if "data" in e]

        lines.append(f"\nPython array entries: {len(py_array_entries)}")
        lines.append(f"Flutter array entries: {len(flutter_array_entries)}")

        # Compare input images
        lines.append("\n" + "-" * 100)
        lines.append("INPUT IMAGE COMPARISON")
        lines.append("-" * 100)

        py_input = self.find_matching_entry(
            self.python_data["entries"],
            "input_image_gray",
        )
        flutter_input = self.find_matching_entry(
            self.flutter_data["entries"],
            "input_image_gray_f32",
        )

        if py_input and flutter_input:
            comparison = self.compare_arrays(py_input, flutter_input)
            lines.append(f"Comparison mode: {comparison.get('comparison_mode', 'N/A')}")
            if comparison.get('comparison_mode') == 'sampled':
                lines.append(f"Sample count: {comparison.get('sample_count', 'N/A')}")
                lines.append(f"Python full shape: {comparison.get('python_full_shape', 'N/A')}")
            lines.append(json.dumps(comparison, indent=2))

        # Compare kernels
        lines.append("\n" + "-" * 100)
        lines.append("KERNEL COMPARISON (first 3 kernels)")
        lines.append("-" * 100)

        for idx in range(min(3, 40)):  # Compare first 3 kernels
            kernel_name = f"kernel_{idx:02d}_real"
            py_kernel = self.find_matching_entry(self.python_data["entries"], kernel_name)
            flutter_kernel = self.find_matching_entry(self.flutter_data["entries"], kernel_name)

            if py_kernel and flutter_kernel:
                comparison = self.compare_arrays(py_kernel, flutter_kernel)
                lines.append(f"\nKernel {idx}:")
                lines.append(f"  Comparison mode: {comparison.get('comparison_mode', 'N/A')}")
                if comparison.get('comparison_mode') == 'sampled':
                    lines.append(f"  Sample count: {comparison.get('sample_count', 'N/A')}")
                    lines.append(f"  Python full shape: {comparison.get('python_full_shape', 'N/A')}")
                lines.append(json.dumps(comparison, indent=2))

        # Compare response maps
        lines.append("\n" + "-" * 100)
        lines.append("RESPONSE MAP COMPARISON (first 3 kernels)")
        lines.append("-" * 100)

        for idx in range(min(3, 40)):  # Compare first 3 responses
            for component in ["filtered_real", "filtered_imag", "magnitude"]:
                response_name = f"response_{idx:02d}_{component}"
                py_response = self.find_matching_entry(
                    self.python_data["entries"],
                    response_name,
                )
                flutter_response = self.find_matching_entry(
                    self.flutter_data["entries"],
                    response_name,
                )

                if py_response and flutter_response:
                    comparison = self.compare_arrays(py_response, flutter_response)
                    lines.append(f"\nResponse {idx} - {component}:")
                    lines.append(f"  Comparison mode: {comparison.get('comparison_mode', 'N/A')}")
                    if comparison.get('comparison_mode') == 'sampled':
                        lines.append(f"  Sample count: {comparison.get('sample_count', 'N/A')}")
                        lines.append(f"  Python full shape: {comparison.get('python_full_shape', 'N/A')}")
                    lines.append(f"  Match: {comparison.get('within_tolerance', 'N/A')}")
                    lines.append(f"  Max diff: {comparison.get('max_absolute_diff', 'N/A')}")
                    lines.append(f"  Mean diff: {comparison.get('mean_absolute_diff', 'N/A')}")

        # Compare normalization
        lines.append("\n" + "-" * 100)
        lines.append("NORMALIZATION PARAMETERS")
        lines.append("-" * 100)

        py_norm_min = self.find_matching_entry(
            self.python_data["entries"],
            "normalization_global_min",
        )
        flutter_norm_min = self.find_matching_entry(
            self.flutter_data["entries"],
            "normalization_global_min",
        )

        if py_norm_min and flutter_norm_min:
            lines.append(f"Python global_min: {py_norm_min.get('value')}")
            lines.append(f"Flutter global_min: {flutter_norm_min.get('value')}")

        # Compare output
        lines.append("\n" + "-" * 100)
        lines.append("OUTPUT COMPARISON")
        lines.append("-" * 100)

        py_output = self.find_matching_entry(
            self.python_data["entries"],
            "gabor_map_normalized",
        )
        flutter_output = self.find_matching_entry(
            self.flutter_data["entries"],
            "gabor_map_normalized",
        )

        if py_output and flutter_output:
            comparison = self.compare_arrays(py_output, flutter_output)
            lines.append(json.dumps(comparison, indent=2))

        report = "\n".join(lines)

        if output_file:
            output_file.write_text(report)
            print(f"Report saved to: {output_file}")

        return report


def main():
    """Run comparison on latest log files."""
    log_dir = Path("data/logs")

    if not log_dir.exists():
        print(f"Log directory not found: {log_dir}")
        return 1

    # Find latest Python and Flutter logs
    python_logs = sorted(log_dir.glob("gabor_filter_python_*.json"), reverse=True)
    flutter_logs = sorted(log_dir.glob("gabor_filter_flutter_*.json"), reverse=True)

    if not python_logs:
        print("No Python Gabor filter logs found")
        return 1

    if not flutter_logs:
        print("No Flutter Gabor filter logs found")
        return 1

    python_log = python_logs[0]
    flutter_log = flutter_logs[0]

    print(f"Using Python log: {python_log}")
    print(f"Using Flutter log: {flutter_log}")

    # Generate comparison
    comparator = FilterLogComparator(python_log, flutter_log)
    report = comparator.generate_report(log_dir / "comparison_report.txt")
    print(report)

    return 0


if __name__ == "__main__":
    exit(main())
