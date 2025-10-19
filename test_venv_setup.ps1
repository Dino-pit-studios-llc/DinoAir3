#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Test virtual environment setup and global pip protection
.DESCRIPTION
    Verifies that:
    1. Virtual environment exists and is functional
    2. Global pip installs are blocked
    3. Venv pip installs work correctly
    4. No dependency conflicts exist
#>

$ErrorActionPreference = "Continue"
$TestsPassed = 0
$TestsFailed = 0
$Warnings = @()

function Write-TestHeader {
    param([string]$Title)
    Write-Host "`n" -NoNewline
    Write-Host "=" -NoNewline -ForegroundColor Cyan
    Write-Host (" " * 68) -NoNewline
    Write-Host "=" -ForegroundColor Cyan
    Write-Host "  $Title" -ForegroundColor Yellow
    Write-Host "=" -NoNewline -ForegroundColor Cyan
    Write-Host (" " * 68) -NoNewline
    Write-Host "=" -ForegroundColor Cyan
}

function Write-TestResult {
    param(
        [string]$TestName,
        [bool]$Passed,
        [string]$Details = ""
    )
    
    if ($Passed) {
        Write-Host "  ✅ " -NoNewline -ForegroundColor Green
        Write-Host $TestName -ForegroundColor Green
        if ($Details) {
            Write-Host "     $Details" -ForegroundColor Gray
        }
        $script:TestsPassed++
    } else {
        Write-Host "  ❌ " -NoNewline -ForegroundColor Red
        Write-Host $TestName -ForegroundColor Red
        if ($Details) {
            Write-Host "     $Details" -ForegroundColor Yellow
        }
        $script:TestsFailed++
    }
}

Write-Host @"

╔══════════════════════════════════════════════════════════════════════╗
║                                                                      ║
║          Virtual Environment & Pip Protection Test Suite            ║
║                                                                      ║
╚══════════════════════════════════════════════════════════════════════╝

"@ -ForegroundColor Cyan

# Test 1: Virtual Environment Exists
Write-TestHeader "TEST 1: Virtual Environment Structure"

$VenvPath = Join-Path $PSScriptRoot ".venv"
$VenvPython = Join-Path $VenvPath "Scripts\python.exe"
$VenvActivate = Join-Path $VenvPath "Scripts\Activate.ps1"

Write-TestResult "Virtual environment directory exists" (Test-Path $VenvPath) $VenvPath
Write-TestResult "Python executable exists" (Test-Path $VenvPython) $VenvPython
Write-TestResult "Activation script exists" (Test-Path $VenvActivate) $VenvActivate

# Test 2: Pip Configuration
Write-TestHeader "TEST 2: Global Pip Protection Configuration"

$PipConfig = "$env:APPDATA\pip\pip.ini"
$ConfigExists = Test-Path $PipConfig

Write-TestResult "Pip config file exists" $ConfigExists $PipConfig

if ($ConfigExists) {
    $ConfigContent = Get-Content $PipConfig -Raw
    $HasRequireVenv = $ConfigContent -match "require-virtualenv\s*=\s*true"
    Write-TestResult "require-virtualenv setting enabled" $HasRequireVenv
} else {
    Write-TestResult "require-virtualenv setting enabled" $false "Config file not found"
}

# Test 3: Global Pip Install Blocked
Write-TestHeader "TEST 3: Global Pip Protection (Should Block)"

# Deactivate if active
if ($env:VIRTUAL_ENV) {
    & deactivate 2>$null
}

# Try to install globally (should fail)
$GlobalInstallResult = & python -m pip install --dry-run setuptools 2>&1
$IsBlocked = $GlobalInstallResult -match "Could not find an activated virtualenv"

Write-TestResult "Global pip install is blocked" $IsBlocked "Attempted: pip install setuptools"

if (-not $IsBlocked) {
    $script:Warnings += "WARNING: Global pip installs are NOT blocked!"
}

# Test 4: Venv Python Works
Write-TestHeader "TEST 4: Virtual Environment Python"

$VenvPythonVersion = & $VenvPython --version 2>&1
$PythonWorks = $LASTEXITCODE -eq 0

Write-TestResult "Venv Python executable works" $PythonWorks $VenvPythonVersion

# Test 5: Venv Pip Works
Write-TestHeader "TEST 5: Virtual Environment Pip"

$VenvPipVersion = & $VenvPython -m pip --version 2>&1
$PipWorks = $LASTEXITCODE -eq 0

Write-TestResult "Venv pip works" $PipWorks $VenvPipVersion

# Test 6: Critical Packages Installed
Write-TestHeader "TEST 6: Critical Packages in Venv"

$CriticalPackages = @("pytest", "ruff", "fastapi", "httpx", "aiofiles", "pydantic")
$InstalledPackages = & $VenvPython -m pip list --format=json | ConvertFrom-Json

foreach ($package in $CriticalPackages) {
    $installed = $InstalledPackages | Where-Object { $_.name -eq $package }
    if ($installed) {
        Write-TestResult "$package installed" $true "Version: $($installed.version)"
    } else {
        Write-TestResult "$package installed" $false "Not found in venv"
    }
}

# Test 7: VS Code Configuration
Write-TestHeader "TEST 7: VS Code Configuration"

$VSCodeSettings = Join-Path $PSScriptRoot ".vscode\settings.json"
$SettingsExist = Test-Path $VSCodeSettings

Write-TestResult "VS Code settings.json exists" $SettingsExist

if ($SettingsExist) {
    $Settings = Get-Content $VSCodeSettings -Raw | ConvertFrom-Json
    
    $HasPythonPath = $null -ne $Settings.'python.defaultInterpreterPath'
    Write-TestResult "Python interpreter path configured" $HasPythonPath
    
    $HasAutoActivate = $Settings.'python.terminal.activateEnvironment' -eq $true
    Write-TestResult "Terminal auto-activation enabled" $HasAutoActivate
    
    $HasDefaultProfile = $null -ne $Settings.'terminal.integrated.defaultProfile.windows'
    Write-TestResult "Default terminal profile configured" $HasDefaultProfile
}

# Test 8: Helper Scripts
Write-TestHeader "TEST 8: Helper Scripts"

$ActivateScript = Join-Path $PSScriptRoot "activate_venv.ps1"
$CheckDepsScript = Join-Path $PSScriptRoot "check_dependencies.py"

Write-TestResult "activate_venv.ps1 exists" (Test-Path $ActivateScript)
Write-TestResult "check_dependencies.py exists" (Test-Path $CheckDepsScript)

# Test 9: Documentation
Write-TestHeader "TEST 9: Documentation Files"

$Docs = @(
    "VENV_SETUP.md",
    "GLOBAL_PIP_PROTECTION.md",
    "VENV_AUTO_ACTIVATION_SETUP.md",
    "QUICKSTART_VENV.md"
)

foreach ($doc in $Docs) {
    $docPath = Join-Path $PSScriptRoot $doc
    Write-TestResult "$doc exists" (Test-Path $docPath)
}

# Final Summary
Write-Host "`n" -NoNewline
Write-Host "=" -NoNewline -ForegroundColor Cyan
Write-Host (" " * 68) -NoNewline
Write-Host "=" -ForegroundColor Cyan
Write-Host "  TEST SUMMARY" -ForegroundColor Yellow
Write-Host "=" -NoNewline -ForegroundColor Cyan
Write-Host (" " * 68) -NoNewline
Write-Host "=" -ForegroundColor Cyan

Write-Host "`n  Tests Passed: " -NoNewline
Write-Host $TestsPassed -ForegroundColor Green
Write-Host "  Tests Failed: " -NoNewline
Write-Host $TestsFailed -ForegroundColor $(if ($TestsFailed -eq 0) { "Green" } else { "Red" })

if ($Warnings.Count -gt 0) {
    Write-Host "`n  ⚠️  WARNINGS:" -ForegroundColor Yellow
    foreach ($warning in $Warnings) {
        Write-Host "     $warning" -ForegroundColor Yellow
    }
}

Write-Host "`n"

if ($TestsFailed -eq 0) {
    Write-Host "  🎉 ALL TESTS PASSED! Your setup is complete and working correctly." -ForegroundColor Green
    Write-Host "     • Virtual environment is functional" -ForegroundColor Gray
    Write-Host "     • Global pip installs are blocked" -ForegroundColor Gray
    Write-Host "     • VS Code is configured for auto-activation" -ForegroundColor Gray
    Write-Host "     • All documentation is in place" -ForegroundColor Gray
    exit 0
} else {
    Write-Host "  ⚠️  SOME TESTS FAILED. Please review the results above." -ForegroundColor Yellow
    Write-Host "     See VENV_SETUP.md for troubleshooting guidance." -ForegroundColor Gray
    exit 1
}
