# Quality of Life make targets

.PHONY: help setup venv install dev test lint format fix cov run api pre-commit hooks clean

PY?=python3
PIP?=pip3
VENV=.venv
ACTIVATE=. $(VENV)/bin/activate

help:
	@echo "Common targets:"
	@echo "  make setup      - Create venv and install deps"
	@echo "  make dev        - Install dev tooling"
	@echo "  make test       - Run pytest"
	@echo "  make lint       - Run ruff checks"
	@echo "  make format     - Format with ruff"
	@echo "  make fix        - Lint+format (autofix)"
	@echo "  make cov        - Run tests with coverage"
	@echo "  make run        - Run API with uvicorn"
	@echo "  make hooks      - Install pre-commit hooks"
	@echo "  make clean      - Remove caches and build artifacts"

$(VENV)/bin/python:
	$(PY) -m venv $(VENV)
	$(ACTIVATE) && python -m pip install --upgrade pip wheel setuptools

venv: $(VENV)/bin/python

install: venv
	$(ACTIVATE) && pip install -r API/requirements.txt
	$(ACTIVATE) && pip install -r API/requirements-dev.txt || true
	$(ACTIVATE) && pip install -r tests/requirements.txt || true
	$(ACTIVATE) && pip install ruff pre-commit pytest-cov

deV: dev

dev: install
	@echo "Dev tools installed"

test:
	$(ACTIVATE) && pytest

lint:
	$(ACTIVATE) && ruff check .

format:
	$(ACTIVATE) && ruff format .

fix: format lint

cov:
	$(ACTIVATE) && pytest --cov --cov-report=term-missing

run api:
	$(ACTIVATE) && uvicorn API.app:app --reload --host 127.0.0.1 --port 24801

hooks:
	$(ACTIVATE) && pre-commit install

clean:
	rm -rf .pytest_cache .ruff_cache .mypy_cache build dist **/__pycache__
