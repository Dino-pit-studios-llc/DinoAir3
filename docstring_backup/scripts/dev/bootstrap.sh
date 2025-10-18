#!/usr/bin/env bash
set -euo pipefail

# Bootstrap a local dev environment
if [ ! -d .venv ]; then
  python3 -m venv .venv
fi

# shellcheck disable=SC1091
source .venv/bin/activate
python -m pip install --upgrade pip wheel setuptools

# Core deps
pip install -r API/requirements.txt

# Dev/test deps (best-effort if files exist)
if [ -f API/requirements-dev.txt ]; then
  pip install -r API/requirements-dev.txt || true
fi
if [ -f tests/requirements.txt ]; then
  pip install -r tests/requirements.txt || true
fi

# Local utils package and its dependencies
# Minimal extras used in tests/utilities
pip install aiofiles

# Tooling
pip install ruff pre-commit pytest-cov black

# Install pre-commit hooks (optional)
pre-commit install || true

echo "Bootstrap complete. Activate with: source .venv/bin/activate"
