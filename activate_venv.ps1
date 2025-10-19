#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Activates the DinoAir3 virtual environment
.DESCRIPTION
    This script activates the project's virtual environment and ensures
    you're using the isolated dependencies instead of global packages.
.EXAMPLE
    .\activate_venv.ps1
#>

$VenvPath = Join-Path $PSScriptRoot ".venv"
$ActivateScript = Join-Path $VenvPath "Scripts\Activate.ps1"

if (Test-Path $ActivateScript) {
    Write-Host "🐍 Activating DinoAir3 virtual environment..." -ForegroundColor Green
    & $ActivateScript
    
    # Verify activation
    $PythonPath = (Get-Command python).Source
    if ($PythonPath -like "*\.venv\*") {
        Write-Host "✅ Virtual environment activated successfully!" -ForegroundColor Green
        Write-Host "📦 Python: $PythonPath" -ForegroundColor Cyan
        
        # Show key installed packages
        Write-Host "`n📚 Key packages in venv:" -ForegroundColor Yellow
        python -m pip list | Select-String "pytest|ruff|fastapi|httpx|aiofiles"
    } else {
        Write-Host "⚠️  Warning: Virtual environment may not have activated correctly" -ForegroundColor Yellow
        Write-Host "   Currently using: $PythonPath" -ForegroundColor Yellow
    }
} else {
    Write-Host "❌ Virtual environment not found at: $VenvPath" -ForegroundColor Red
    Write-Host "   Run: python -m venv .venv" -ForegroundColor Yellow
    exit 1
}
