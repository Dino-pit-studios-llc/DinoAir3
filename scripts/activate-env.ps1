# DinoAir Virtual Environment Activation Script
# Run this script to activate the virtual environment with all dependencies

Write-Output "Activating DinoAir Virtual Environment..."
Write-Output ""

# Activate the virtual environment
& "$PSScriptRoot\.venv\Scripts\Activate.ps1"

Write-Output "DinoAir Virtual Environment Activated!"
Write-Output "Python version: $(python --version)"
Write-Output "Virtual env path: $env:VIRTUAL_ENV"
Write-Output ""
Write-Warning "Key packages installed:"
Write-Output "   - FastAPI and Uvicorn (API framework)"
Write-Output "   - Pytest and Coverage (Testing)"
Write-Output "   - Black, Ruff, MyPy (Code quality)"
Write-Output "   - Pydantic (Data validation)"
Write-Output "   - HTTPX, aiofiles (Async utilities)"
Write-Output "   - Sphinx (Documentation)"
Write-Output "   - Safety, Bandit (Security)"
Write-Output ""
Write-Warning "Common commands:"
Write-Output "   - Run tests: pytest"
Write-Output "   - Format code: black ."
Write-Output "   - Lint code: ruff check ."
Write-Output "   - Type check: mypy ."
Write-Output "   - Start API: uvicorn API_files.app:app --reload"
Write-Output ""
