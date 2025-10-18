# Permanent CodeQL PATH Setup Script
# Run this script as Administrator to permanently add CodeQL to Windows PATH

$codeqlPath = "C:\Users\DinoP\Documents\codeql-bundle-win64\codeql"

Write-Output "CodeQL PATH Configuration"
Write-Output "========================="

# Check if CodeQL executable exists
if (Test-Path "$codeqlPath\codeql.exe") {
    Write-Output "CodeQL found at: $codeqlPath"
} else {
    Write-Error "CodeQL not found at: $codeqlPath"
    Write-Warning "Please verify the installation path"
    exit 1
}

# Get current system PATH
$currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")

# Check if CodeQL is already in PATH
if ($currentPath -like "*$codeqlPath*") {
    Write-Warning "CodeQL is already in your PATH"
} else {
    try {
        # Add CodeQL to user PATH
        $newPath = "$codeqlPath;$currentPath"
        [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")

        Write-Output "Successfully added CodeQL to PATH"
        Write-Warning "Please restart your terminal for changes to take effect"

    } catch {
        Write-Error "Failed to add CodeQL to PATH"
        Write-Error "Error: $_"
        Write-Warning "Try running this script as Administrator"
    }
}

# Test CodeQL in current session
Write-Output "`nTesting CodeQL in current session..."
try {
    # Add to current session PATH if not already there
    if (-not ($env:PATH -like "*$codeqlPath*")) {
        $env:PATH = "$codeqlPath;$env:PATH"
    }

    $version = & codeql version 2>&1
    Write-Output "CodeQL is working!"
    Write-Output "Version: $($version[0])"

    # Show available languages
    Write-Output "`nAvailable languages:"
    $languages = & codeql resolve languages 2>&1
    $languages | ForEach-Object {
        if ($_ -match '^(\w+) \(') {
            Write-Output "  - $($matches[1])"
        }
    }

} catch {
    Write-Error "Error testing CodeQL"
    Write-Error "Error: $_"
}

Write-Warning "`nNext Steps:"
Write-Output "1. Restart your PowerShell terminal"
Write-Output "2. Run: codeql version"
Write-Output "3. Use: .\run-codeql-analysis.ps1 to analyze DinoAir"
