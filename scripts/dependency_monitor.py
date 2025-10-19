#!/usr/bin/env python3
"""
Dependency Graph Monitoring System for DinoAir
============================================

This script monitors dependency relationships, import performance, and maintains
health metrics for the import organization system.

Features:
- Real-time circular dependency detection
- Import performance monitoring
- Dependency graph visualization
- Health metrics and alerting
- Historical trend analysis

Usage:
    python scripts/dependency_monitor.py [command] [options]

Commands:
    monitor     - Run continuous monitoring
    analyze     - Generate dependency analysis report
    alert       - Check for alert conditions
    visualize   - Generate dependency graph visualization
    performance - Track import performance metrics
"""

import argparse
import importlib
import json
import logging

# removed: import subprocess
import sys
import time
from dataclasses import asdict, dataclass
from datetime import datetime
from pathlib import Path
from typing import Any

from utils.process import safe_run

# Try to import visualization libraries
plt = None
nx = None
try:
    plt = importlib.import_module("matplotlib.pyplot")
except ImportError:
    plt = None
try:
    nx = importlib.import_module("networkx")
except ImportError:
    nx = None
HAS_VISUALIZATION = plt is not None and nx is not None


@dataclass
class ImportMetrics:
    """Metrics for import performance and health."""

    module_name: str
    import_time_estimate: float
    import_size: int
    dependency_count: int
    circular_dependencies: list[str]
    last_modified: datetime
    health_score: float


@dataclass
class AlertCondition:
    """Represents an alert condition."""

    severity: str  # critical, warning, info
    message: str
    module: str
    metric_value: float
    threshold: float
    timestamp: datetime


class DependencyMonitor:
    """Monitors dependency health and import organization."""

    def __init__(self, root_path: Path, config: dict[str, Any] | None = None):
        self.root_path = root_path
        self.config = config or self._load_default_config()
        self.metrics_history: list[ImportMetrics] = []
        self.alerts: list[AlertCondition] = []
        self.logger = self._setup_logging()
        self._dependency_cache: dict[Path, tuple[int, list[str]]] = {}

    @staticmethod
    def _load_default_config() -> dict[str, Any]:
        """Load default monitoring configuration."""
        return {
            "monitoring": {
                "import_time_threshold": 0.1,  # seconds
                "dependency_count_threshold": 10,
                "health_score_threshold": 0.8,
                "circular_dependency_tolerance": 0,
            },
            "alerts": {"enabled": True, "email_recipients": [], "webhook_url": None},
            "visualization": {
                "enabled": HAS_VISUALIZATION,
                "output_dir": "dependency_graphs",
                "formats": ["png", "svg"],
            },
            "performance": {
                "track_imports": True,
                "sample_rate": 1.0,
                "retention_days": 30,
            },
        }

    def _setup_logging(self) -> logging.Logger:
        """Set up logging for dependency monitoring."""
        logger = logging.getLogger("dependency_monitor")
        logger.setLevel(logging.INFO)

        if not logger.handlers:
            handler = logging.StreamHandler()
            formatter = logging.Formatter("%(asctime)s - %(name)s - %(levelname)s - %(message)s")
            handler.setFormatter(formatter)
            logger.addHandler(handler)

        return logger

    def measure_import_performance(self) -> dict[str, ImportMetrics]:
        """Measure import performance for all modules."""
        self.logger.info("Starting import performance measurement...")
        metrics = {}

        # Find all Python modules
        python_files = list(self.root_path.rglob("*.py"))
        python_files = [
            f
            for f in python_files
            if not any(
                part in str(f)
                for part in [
                    "__pycache__",
                    ".git",
                    "test",
                    "venv",
                    ".venv",
                    "build",
                    "dist",
                    "site-packages",
                ]
            )
        ]

        for file_path in python_files:
            try:
                module_name = self._path_to_module(file_path)
                metrics[module_name] = self._measure_module_import(file_path, module_name)
            except Exception as e:
                self.logger.warning("Failed to measure %s: %s", file_path, e)

        return metrics

    def _path_to_module(self, file_path: Path) -> str:
        """Convert file path to module name."""
        relative_path = file_path.relative_to(self.root_path)
        parts = list(relative_path.parts)

        if parts[-1] == "__init__.py":
            parts = parts[:-1]
        else:
            parts[-1] = relative_path.stem

        return ".".join(parts) if parts else "__main__"

    def _measure_module_import(self, file_path: Path, module_name: str) -> ImportMetrics:
        """Measure import performance for a single module."""
        # Get file stats
        stat = file_path.stat()
        import_size = stat.st_size
        last_modified = datetime.fromtimestamp(stat.st_mtime)

        # Analyze dependencies
        dependency_count, circular_deps = self._analyze_module_dependencies(file_path)

        # Measure actual import time using importlib and time.perf_counter for accuracy
        actual_import_time = self._measure_actual_import_time(file_path, module_name)

        # Calculate health score using actual import time
        health_score = self._calculate_health_score(actual_import_time, dependency_count, len(circular_deps))

        return ImportMetrics(
            module_name=module_name,
            import_time_estimate=actual_import_time,
            import_size=import_size,
            dependency_count=dependency_count,
            circular_dependencies=circular_deps,
            last_modified=last_modified,
            health_score=health_score,
        )

    def _measure_actual_import_time(self, file_path: Path, module_name: str) -> float:
        """
        Measure actual import time using importlib and time.perf_counter.

        Args:
            file_path: Path to the module file
            module_name: Module name for import

        Returns:
            Actual import time in seconds
        """
        script = self._build_measurement_script(file_path, module_name)
        temp_path = self._write_temp_script(script)
        try:
            result = self._run_script(temp_path)
            import_time = self._parse_result(result, module_name)
            if import_time is not None and 0 <= import_time <= 30:
                return import_time
        except (OSError, ValueError, TypeError) as e:
            self.logger.debug("Failed to measure import time for %s: %s", module_name, e)
        finally:
            Path(temp_path).unlink(missing_ok=True)
        return self._fallback_time(file_path)

    @staticmethod
    def _build_measurement_script(file_path: Path, module_name: str) -> str:
        """Constructs and returns a standalone script to measure import time of a module."""
        import textwrap

        return textwrap.dedent(
            f'''
import sys as _script_sys
import time
import importlib
import importlib.util
from pathlib import Path

 def measure_import():
     """Measure import time safely."""
     module_path = Path(r"{file_path}")
     module_name = "{module_name}"
     if module_name in _script_sys.modules:
         del _script_sys.modules[module_name]
     spec = importlib.util.spec_from_file_location(module_name, module_path)
     if spec is None:
         return 0.001  # Default fallback time
     start_time = time.perf_counter()
     module = importlib.util.module_from_spec(spec)
     _script_sys.modules[module_name] = module
     spec.loader.exec_module(module)
     end_time = time.perf_counter()
     if module_name in _script_sys.modules:
         del _script_sys.modules[module_name]
     return end_time - start_time

if __name__ == "__main__":
    print(measure_import())
'''
        )

    def _write_temp_script(self, script: str) -> str:
        """Write the provided script string to a temporary Python file and return its file path."""
        import tempfile

        with tempfile.NamedTemporaryFile(mode="w", suffix=".py", delete=False) as temp_file:
            temp_file.write(script)
            temp_file.flush()
            return temp_file.name

    @staticmethod
    def _run_script(script_path: str):
        """Execute the Python script at the specified path and return its output or result."""
        return safe_run(
            [sys.executable, script_path],
            allowed_binaries={
                Path(sys.executable).name,
                "python",
                sys.executable,
            },
            text=True,
            timeout=10,
            check=False,
        )

    def _parse_result(self, result, module_name: str) -> float | None:
        """
        Parse the CompletedProcess result to extract a float value for the given module.

        result: The CompletedProcess returned by safe_run.
        module_name: The name of the module to parse the result for.
        Returns a float if the module value is found, otherwise None.
        """
        if result.returncode != 0 or not result.stdout.strip():
            self.logger.debug(
                "Measurement script failed for %s: returncode %s",
                module_name,
                result.returncode,
            )
            return None
        try:
            return float(result.stdout.strip())
        except ValueError as e:
            self.logger.debug("Failed to parse import time for %s: %s", module_name, e)
            return None

    @staticmethod
    def _fallback_time(module_path: Path) -> float:
        """Estimate fallback import time based on module file size."""
        try:
            file_size = module_path.stat().st_size
            return max(0.001, (file_size / 1000000) * 0.001)
        except OSError:
            return 0.001

    def _benchmark_import_performance(self, sample_modules: list[tuple[Path, str]] | None = None) -> dict[str, float]:
        """
        Benchmark import performance for a sample of modules to improve estimation accuracy.

        Args:
            sample_modules: Optional list of (file_path, module_name) tuples to benchmark

        Returns:
            Dictionary mapping module names to actual import times
        """
        if sample_modules is None:
            # Select a representative sample of modules
            all_files = list(self.root_path.rglob("*.py"))
            sample_size = min(20, len(all_files))  # Benchmark up to 20 modules
            sample_files = all_files[:: max(1, len(all_files) // sample_size)]
            sample_modules = [(f, self._path_to_module(f)) for f in sample_files]

        benchmark_results = {}

        for file_path, module_name in sample_modules:
            try:
                actual_time = self._measure_actual_import_time(file_path, module_name)
                benchmark_results[module_name] = actual_time
                self.logger.debug("Benchmarked %s: %.4fs", module_name, actual_time)
            except Exception as e:
                self.logger.warning("Failed to benchmark %s: %s", module_name, e)

        return benchmark_results

    def run_import_performance_analysis(self) -> dict[str, Any]:
        """
        Run comprehensive import performance analysis using actual timing measurements

        Returns:
            Performance analysis report with timing statistics and recommendations
        """
        self.logger.info("Starting import performance analysis with actual timing measurements")

        # Get all Python files
        python_files = list(self.root_path.rglob("*.py"))

        # Sample modules for benchmarking (limit to avoid excessive runtime)
        sample_size = min(50, len(python_files))
        if len(python_files) > sample_size:
            # Select a diverse sample
            step = len(python_files) // sample_size
            sample_files = python_files[::step]
        else:
            sample_files = python_files

        sample_modules = [(f, self._path_to_module(f)) for f in sample_files]

        # Benchmark import performance
        benchmark_results = self._benchmark_import_performance(sample_modules)

        if not benchmark_results:
            self.logger.warning("No benchmark results obtained")
            return {"error": "No performance data available"}

        # Analyze timing statistics
        import_times = list(benchmark_results.values())

        performance_stats = {
            "total_modules_tested": len(benchmark_results),
            "mean_import_time": sum(import_times) / len(import_times),
            "max_import_time": max(import_times),
            "min_import_time": min(import_times),
            "median_import_time": sorted(import_times)[len(import_times) // 2],
        }

        # Identify slow imports
        slow_threshold = performance_stats["mean_import_time"] * 3  # 3x mean
        slow_imports = {module: time_val for module, time_val in benchmark_results.items() if time_val > slow_threshold}

        # Performance recommendations
        recommendations = []

        if performance_stats["max_import_time"] > 1.0:
            recommendations.append("Consider lazy imports for modules taking >1s to import")

        if len(slow_imports) > len(benchmark_results) * 0.1:  # >10% slow imports
            recommendations.append("High number of slow imports detected - review import structure")

        if performance_stats["mean_import_time"] > 0.1:
            recommendations.append("Average import time is high - consider import optimization")

        return {
            "performance_statistics": performance_stats,
            "slow_imports": slow_imports,
            "benchmark_results": benchmark_results,
            "recommendations": recommendations,
            "analysis_timestamp": datetime.now().isoformat(),
        }

    def compare_estimation_accuracy(self, sample_size: int = 20) -> dict[str, Any]:
        """
        Compare accuracy of size-based estimation vs actual import timing.

        Args:
            sample_size: Number of modules to test

        Returns:
            Comparison report showing estimation accuracy
        """
        python_files = list(self.root_path.rglob("*.py"))
        sample_size = min(sample_size, len(python_files))

        # Select random sample
        import random

        sample_files = random.sample(python_files, sample_size)

        comparison_results: list[dict[str, Any]] = []

        # Define accuracy thresholds as constants
        excellent_threshold = 10.0
        good_threshold = 25.0

        for file_path in sample_files:
            module_name = self._path_to_module(file_path)

            try:
                # Get actual import time
                actual_time = self._measure_actual_import_time(file_path, module_name)

                # Get size-based estimate
                file_size = file_path.stat().st_size
                estimated_time = self._estimate_import_time_from_size(file_size, file_path)

                # Calculate accuracy metrics
                error = abs(actual_time - estimated_time)
                relative_error = error / max(actual_time, 0.001) * 100  # Percentage

                comparison_results.append(
                    {
                        "module": module_name,
                        "actual_time": actual_time,
                        "estimated_time": estimated_time,
                        "absolute_error": error,
                        "relative_error_percent": relative_error,
                        "file_size": float(file_size),
                    }
                )

            except Exception as e:
                self.logger.warning("Failed to compare timing for %s: %s", module_name, e)

        if not comparison_results:
            return {"error": "No comparison data available"}

        # Calculate overall accuracy metrics - now with proper typing
        total_error = sum(result["absolute_error"] for result in comparison_results)
        mean_relative_error = sum(result["relative_error_percent"] for result in comparison_results) / len(
            comparison_results
        )

        accuracy_report = {
            "sample_size": len(comparison_results),
            "mean_absolute_error": total_error / len(comparison_results),
            "mean_relative_error_percent": mean_relative_error,
            "detailed_results": comparison_results,
            "accuracy_distribution": {
                "excellent": sum(1 for r in comparison_results if r["relative_error_percent"] < excellent_threshold),
                "good": sum(
                    1 for r in comparison_results if excellent_threshold <= r["relative_error_percent"] < good_threshold
                ),
                "poor": sum(1 for r in comparison_results if r["relative_error_percent"] >= good_threshold),
            },
        }

        return accuracy_report

    def _analyze_module_dependencies(self, file_path: Path) -> tuple[int, list[str]]:
        """Analyze dependencies for a module using directory-based caching."""
        directory = file_path.parent

        # Check if we have cached results for this directory
        if directory in self._dependency_cache:
            return self._dependency_cache[directory]

        try:
            # Use the existing circular dependency detector once per directory
            result = safe_run(
                [
                    sys.executable,
                    "scripts/check_circular_dependencies.py",
                    "--path",
                    str(directory),
                    "--format",
                    "json",
                ],
                allowed_binaries={Path(sys.executable).name, "python"},
                text=True,
                timeout=30,
                check=False,
            )

            if result.returncode == 0:
                data = json.loads(result.stdout)
                circular_deps = [" -> ".join(cycle["cycle"]) for cycle in data.get("circular_dependencies", [])]
                # Cache results for this directory
                cache_result = (
                    len(data.get("circular_dependencies", [])),
                    circular_deps,
                )
                self._dependency_cache[directory] = cache_result
                return cache_result

            # Cache empty result for failed analysis
            cache_result = (0, [])
            self._dependency_cache[directory] = cache_result
            return cache_result

        except Exception as e:
            self.logger.warning("Failed to analyze dependencies for %s: %s", file_path, e)
            # Cache empty result for failed analysis
            cache_result = (0, [])
            self._dependency_cache[directory] = cache_result
            return cache_result

    def _calculate_health_score(self, import_time_estimate: float, dependency_count: int, circular_count: int) -> float:
        """Calculate health score for a module."""
        score = 1.0

        # Penalize slow imports
        if import_time_estimate > self.config["monitoring"]["import_time_threshold"]:
            score -= 0.3

        # Penalize high dependency count
        if dependency_count > self.config["monitoring"]["dependency_count_threshold"]:
            score -= 0.2

        # Heavily penalize circular dependencies
        if circular_count > 0:
            score -= 0.5 * circular_count

        return max(0.0, score)

    def check_alert_conditions(self, metrics: dict[str, ImportMetrics]) -> list[AlertCondition]:
        """Check for alert conditions in current metrics."""
        alerts = []

        for module_name, metric in metrics.items():
            # Check import time threshold
            if metric.import_time_estimate > self.config["monitoring"]["import_time_threshold"]:
                alerts.append(
                    AlertCondition(
                        severity="warning",
                        message=f"Slow import detected in {module_name}",
                        module=module_name,
                        metric_value=metric.import_time_estimate,
                        threshold=self.config["monitoring"]["import_time_threshold"],
                        timestamp=datetime.now(),
                    )
                )

            # Check health score threshold
            if metric.health_score < self.config["monitoring"]["health_score_threshold"]:
                alerts.append(
                    AlertCondition(
                        severity="critical" if metric.health_score < 0.5 else "warning",
                        message=f"Low health score for {module_name}",
                        module=module_name,
                        metric_value=metric.health_score,
                        threshold=self.config["monitoring"]["health_score_threshold"],
                        timestamp=datetime.now(),
                    )
                )

            # Check circular dependencies
            if metric.circular_dependencies:
                alerts.append(
                    AlertCondition(
                        severity="critical",
                        message=f"Circular dependencies detected in {module_name}",
                        module=module_name,
                        metric_value=len(metric.circular_dependencies),
                        threshold=0,
                        timestamp=datetime.now(),
                    )
                )

        return alerts

    def generate_dependency_graph(self, metrics: dict[str, ImportMetrics], output_path: Path) -> bool:
        """Generate dependency graph visualization."""
        if not HAS_VISUALIZATION:
            self.logger.warning("Visualization libraries not available")
            return False

        try:
            G = nx.DiGraph()

            # Add nodes with health score as attribute
            for module_name, metric in metrics.items():
                G.add_node(module_name, health_score=metric.health_score)

            # Add edges for dependencies (simplified)
            for module_name, metric in metrics.items():
                for dep in metric.circular_dependencies:
                    if " -> " in dep:
                        parts = dep.split(" -> ")
                        for i in range(len(parts) - 1):
                            if parts[i] in G.nodes and parts[i + 1] in G.nodes:
                                G.add_edge(parts[i], parts[i + 1], style="circular")

            return self._create_dependency_visualization(G, metrics, output_path)

        except Exception as e:
            self.logger.error("Failed to generate dependency graph: %s", e)
            return False

    def run_monitoring_cycle(self) -> dict[str, Any]:
        """Run a complete monitoring cycle."""
        self.logger.info("Starting monitoring cycle...")

        cycle_start = time.time()

        # Measure current performance
        metrics = self.measure_import_performance()

        # Check for alerts
        alerts = self.check_alert_conditions(metrics)

        # Generate reports
        report = {
            "timestamp": datetime.now().isoformat(),
            "cycle_duration": time.time() - cycle_start,
            "total_modules": len(metrics),
            "healthy_modules": sum(1 for m in metrics.values() if m.health_score >= 0.8),
            "warning_modules": sum(1 for m in metrics.values() if 0.5 <= m.health_score < 0.8),
            "critical_modules": sum(1 for m in metrics.values() if m.health_score < 0.5),
            "total_alerts": len(alerts),
            "critical_alerts": sum(1 for a in alerts if a.severity == "critical"),
            "average_health_score": (sum(m.health_score for m in metrics.values()) / len(metrics) if metrics else 0),
            "total_circular_dependencies": sum(len(m.circular_dependencies) for m in metrics.values()),
        }

        # Store metrics and alerts
        self.metrics_history.extend(metrics.values())
        self.alerts.extend(alerts)

        # Generate visualization if enabled
        if self.config["visualization"]["enabled"]:
            output_dir = Path(self.config["visualization"]["output_dir"])
            output_dir.mkdir(exist_ok=True)

            graph_path = output_dir / f"dependency_graph_{datetime.now().strftime('%Y%m%d_%H%M%S')}.png"
            self.generate_dependency_graph(metrics, graph_path)

        self.logger.info("Monitoring cycle completed: %s", report)
        return report


def handle_monitor(monitor: DependencyMonitor, continuous: bool, interval: int) -> None:
    """Handle Monitor function."""
    if continuous:
        print(f"Starting continuous monitoring (interval: {interval}s)")
        try:
            while True:
                report = monitor.run_monitoring_cycle()
                if report["critical_alerts"] > 0:
                    print(report)
                time.sleep(interval)
        except KeyboardInterrupt:
            pass
    else:
        report = monitor.run_monitoring_cycle()
        print(report)


def parse_args() -> argparse.Namespace:
    """Parse Args function."""
    parser = argparse.ArgumentParser(
        description="Dependency monitoring for DinoAir",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    parser.add_argument(
        "command",
        choices=["monitor", "analyze", "alert", "visualize", "performance"],
        help="Monitoring command to execute",
    )
    parser.add_argument(
        "--path",
        type=Path,
        default=Path(),
        help="Path to analyze (default: current directory)",
    )
    parser.add_argument("--output", type=Path, help="Output file/directory for results")
    parser.add_argument(
        "--format",
        choices=["json", "text", "html"],
        default="text",
        help="Output format",
    )
    parser.add_argument("--continuous", action="store_true", help="Run in continuous monitoring mode")
    parser.add_argument(
        "--interval",
        type=int,
        default=300,
        help="Monitoring interval in seconds (default: 300)",
    )
    return parser.parse_args()


def validate_path(path: Path) -> None:
    """Validate path function."""
    if not path.exists():
        raise FileNotFoundError(f"Path not found: {path}")


def execute_monitor(monitor: DependencyMonitor, args: argparse.Namespace) -> None:
    """Execute Monitor function."""
    if args.continuous:
        handle_monitor(monitor, args.continuous, args.interval)
    else:
        report = monitor.run_monitoring_cycle()
        output = format_output(report, args.format)
        print(output)


def execute_analyze(monitor: DependencyMonitor, args: argparse.Namespace) -> None:
    """Handle the analyze command."""
    metrics = monitor.measure_import_performance()
    analysis = {
        "total_modules": len(metrics),
        "modules": {name: asdict(metric) for name, metric in metrics.items()},
        "summary": {
            "average_import_time_estimate": (
                sum(m.import_time_estimate for m in metrics.values()) / len(metrics) if metrics else 0
            ),
            "average_health_score": (sum(m.health_score for m in metrics.values()) / len(metrics) if metrics else 0),
            "modules_with_circular_deps": sum(1 for m in metrics.values() if m.circular_dependencies),
        },
    }

    if args.output:
        with open(args.output, "w") as f:
            json.dump(analysis, f, indent=2, default=str)
    else:
        print(json.dumps(analysis, indent=2, default=str))


def execute_alert(_monitor: DependencyMonitor, _args: argparse.Namespace) -> None:
    """Execute Alert function."""
    # Placeholder for alert implementation


def execute_visualize(monitor: DependencyMonitor, args: argparse.Namespace) -> None:
    """Handle the visualize command."""
    if not HAS_VISUALIZATION:
        print("Error: Visualization requires matplotlib and networkx", file=sys.stderr)
        sys.exit(1)

    metrics = monitor.measure_import_performance()
    output_path = args.output or Path("dependency_graph.png")

    if monitor.generate_dependency_graph(metrics, output_path):
        print(f"Dependency graph saved to {output_path}")
    else:
        print("Failed to generate dependency graph", file=sys.stderr)
        sys.exit(1)


def execute_performance(_monitor: DependencyMonitor, _args: argparse.Namespace) -> None:
    """Execute Performance function."""


def execute_command(args: argparse.Namespace) -> None:
    """Execute Command function."""
    monitor = DependencyMonitor(args.path)
    commands = {
        "monitor": execute_monitor,
        "analyze": execute_analyze,
        "alert": execute_alert,
        "visualize": execute_visualize,
        "performance": execute_performance,
    }
    func = commands.get(args.command)
    if not func:
        print(f"Unknown command {args.command}", file=sys.stderr)
        sys.exit(1)
    func(monitor, args)


def format_output(report: Any, fmt: str) -> str:
    """Format Output function."""
    if fmt == "json":
        return json.dumps(report, indent=2)
    if fmt == "html":
        # Placeholder for html formatting
        return f"<html><body><pre>{report}</pre></body></html>"
    # text format
    return str(report)


def main() -> None:
    """Main entry point for dependency monitoring."""
    args = parse_args()
    validate_path(args.path)
    execute_command(args)


if __name__ == "__main__":
    main()
