# Quick Virtual Environment Activation Script
# Run this script to activate the DinoAir virtual environment

Write-Output "🐍 Activating DinoAir Virtual Environment..."

# Change to the DinoAir directory
$dinoAirPath = "C:\Users\DinoP\Documents\DinoAirNew\DinoAir"
Set-Location $dinoAirPath

# Check if virtual environment exists
if (Test-Path ".\.venv\Scripts\Activate.ps1") {
    # Activate the virtual environment
    & ".\.venv\Scripts\Activate.ps1"

    Write-Output "✅ Virtual environment activated!"
    Write-Output "📁 Current directory: $(Get-Location)"
    Write-Output "🐍 Python version: $((& python --version))"
    Write-Output "📦 Pip location: $((& where.exe pip))"

    Write-Warning "`n💡 Tips:"
    Write-Host "   - Use 'deactivate' to exit the virtual environment" -ForegroundColor White
    Write-Host "   - Run 'python -m pip list' to see installed packages" -ForegroundColor White
    Write-Output "   - VS Code should now use this Python interpreter automatically"

} else {
    Write-Error "❌ Virtual environment not found at $dinoAirPath\.venv"
    Write-Host "   Please ensure you're in the correct directory." -ForegroundColor Yellow
}
