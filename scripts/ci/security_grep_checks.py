#!/usr/bin/env python3
import argparse
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]

NOSEC_MARKERS = ("# nosec", "# noqa", "# security: allow")
"""Module module."""
# Compile-time regex patterns (Python re supports lookaheads, \s, etc.)
PATTERNS = {
    "shell_true_subprocess": re.compile(
        r"subprocess\.(run|Popen|call|check_call|check_output)\([^)]*shell\s*=\s*True",
        re.S,
    ),
    "dynamic_import_non_literal": re.compile(
        r"importlib\.import_module\(\s*(?!['\"]).+",
        re.S,
    ),
    "xml_etree_usage": re.compile(
        r"(^|\s)(from|import)\s+xml\.etree",
        re.M,
    ),
    "direct_subprocess": re.compile(
        r"(^|\s)subprocess\.(run|Popen|call|check_call|check_output)\(",
        re.M | re.S,
    ),
    "interpolated_sql": re.compile(
        r"(?i)f['\"]\s*(SELECT|UPDATE|INSERT|DELETE)[^\n]*\{",
        re.S,
    ),
}


def read_text(p: Path) -> str:
    """Read Text function."""
    try:
        return p.read_text(encoding="utf-8", errors="replace")
    except Exception:
        return ""


def is_python_file(p: Path) -> bool:
    """Is Python File function."""
    return p.suffix == ".py"


def is_in_tests(p: Path) -> bool:
    """Is In Tests function."""
    parts = p.parts
    return "tests" in parts


def is_utils_process(p: Path) -> bool:
    """Is Utils Process function."""
    # Only the wrapper module is allowed to use subprocess directly or with shell=True.
    try:
        rel = p.relative_to(REPO_ROOT).as_posix()
    except Exception:
        rel = p.as_posix()
    return rel == "utils/process.py"


def is_in_database(p: Path) -> bool:
    """Is In Database function."""
    return "database" in p.parts


def line_and_col_for(text: str, idx: int) -> tuple[int, int]:
    """Line And Col For function."""
    # Compute line (1-based) and column (0-based)
    line = text.count("\n", 0, idx) + 1
    last_nl = text.rfind("\n", 0, idx)
    col = idx if last_nl == -1 else idx - last_nl - 1
    return line, col


def has_nosec_on_line(text: str, line_no: int) -> bool:
    """Has Nosec On Line function."""
    lines = text.splitlines()
    if 1 <= line_no <= len(lines):
        line = lines[line_no - 1]
        return any(marker in line for marker in NOSEC_MARKERS)
    return False


def is_safe_import_wrapper(p: Path) -> bool:
    """Allow dynamic import inside known, reviewed wrappers."""
    try:
        posix = p.relative_to(REPO_ROOT).as_posix()
    except Exception:
        posix = p.as_posix()
    return posix in (
        "utils/safe_imports.py",
        "tools/pseudocode_translator/models/safe_imports.py",
    )


def report(file: Path, line: int, col: int, rule: str, message: str):
    """Report function."""
    # Standard "path:line:col: message" format for pre-commit CI consumption
    print(f"{file.as_posix()}:{line}:{col}: {rule}: {message}")


def _parse_args():
    parser = argparse.ArgumentParser(add_help=False)
    parser.add_argument(
        "--warn-sql",
        action="store_true",
        dest="warn_sql",
        help="Downgrade SQL heuristic to warnings (non-fatal)",
    )
    args, _ = parser.parse_known_args()
    return args


def _check_shell_true_subprocess(p: Path, text: str):
    findings = []
    shell_locations = set()
    if not is_in_tests(p) and not is_utils_process(p):
        for m in PATTERNS["shell_true_subprocess"].finditer(text):
            line, col = line_and_col_for(text, m.start())
            if has_nosec_on_line(text, line):
                continue
            shell_locations.add((line, col))
            findings.append(
                (
                    p,
                    line,
                    col,
                    "shell_true_subprocess",
                    "Disallowed shell=True in subprocess call; use safe wrappers from utils.process.",
                )
            )
    return findings, shell_locations


def _check_dynamic_import_non_literal(p: Path, text: str):
    findings = []
    for m in PATTERNS["dynamic_import_non_literal"].finditer(text):
        line, col = line_and_col_for(text, m.start())
        if has_nosec_on_line(text, line):
            continue
        if is_safe_import_wrapper(p):
            continue
        findings.append(
            (
                p,
                line,
                col,
                "dynamic_import_non_literal",
                "Non-literal importlib.import_module usage is blocked; only literal module names allowed.",
            )
        )
    return findings


def _check_xml_etree_usage(p: Path, text: str):
    findings = []
    for m in PATTERNS["xml_etree_usage"].finditer(text):
        line, col = line_and_col_for(text, m.start())
        if has_nosec_on_line(text, line):
            continue
        findings.append(
            (
                p,
                line,
                col,
                "xml_etree_usage",
                "xml.etree usage is banned; prefer defusedxml alternatives.",
            )
        )
    return findings


def _check_direct_subprocess(p: Path, text: str, shell_locations: set[tuple[int, int]]):
    findings = []
    if not is_in_tests(p) and not is_utils_process(p):
        for m in PATTERNS["direct_subprocess"].finditer(text):
            line, col = line_and_col_for(text, m.start())
            if has_nosec_on_line(text, line):
                continue
            if (line, col) in shell_locations:
                continue
            findings.append(
                (
                    p,
                    line,
                    col,
                    "direct_subprocess",
                    "Direct subprocess usage is disallowed; use approved wrappers in utils.process.",
                )
            )
    return findings


def _check_interpolated_sql(p: Path, text: str):
    findings = []
    for m in PATTERNS["interpolated_sql"].finditer(text):
        line, col = line_and_col_for(text, m.start())
        if has_nosec_on_line(text, line):
            continue
        findings.append(
            (
                p,
                line,
                col,
                "interpolated_sql",
                "Possible interpolated SQL detected; use parameterized queries only.",
            )
        )
    return findings


def check_file(p: Path) -> list[tuple[Path, int, int, str, str]]:
    """
    Returns list of findings as tuples:
      (path, line, col, rule_id, message)
    """
    findings = []
    text = read_text(p)
    if not text:
        return findings

    shell_findings, shell_true_locations = _check_shell_true_subprocess(p, text)
    findings.extend(shell_findings)
    findings.extend(_check_dynamic_import_non_literal(p, text))
    findings.extend(_check_xml_etree_usage(p, text))
    findings.extend(_check_direct_subprocess(p, text, shell_true_locations))
    if is_in_database(p):
        findings.extend(_check_interpolated_sql(p, text))

    return findings


def main() -> int:
        """Main function."""
    args = _parse_args()
    warn_sql = bool(getattr(args, "warn_sql", False))
    all_findings = []
    for p in REPO_ROOT.rglob("*.py"):
        # Skip .venv, virtualenvs, build caches, etc.
        if (
            any(part.startswith(".") and part not in {".github"} for part in p.parts)
            and ".github" not in p.parts
        ):
            continue

        # Only scan real project files
        if not is_python_file(p):
            continue

        # Exclude tests globally only for the rules that specify; we still scan tests for other rules,
        # but those rules themselves gate via is_in_tests().
        findings = check_file(p)
        all_findings.extend(findings)

    for path, line, col, rule, message in all_findings:
        report(path, line, col, rule, message)

    # Determine exit code: SQL heuristic can be downgraded to warnings
    if warn_sql:
        fatal_findings = [f for f in all_findings if f[3] != "interpolated_sql"]
    else:
        fatal_findings = all_findings
    return 1 if fatal_findings else 0


if __name__ == "__main__":
    sys.exit(main())