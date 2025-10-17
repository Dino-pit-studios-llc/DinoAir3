# Setup environment for Flutter development
# This adds Git and Flutter to the current session's PATH

Write-Output "Setting up Flutter development environment..."

# Add necessary paths
# Dynamically detect Git and Flutter installation paths
$gitExe = Get-Command git -ErrorAction SilentlyContinue
if ($null -eq $gitExe) {
    Write-Error "Git executable not found in PATH. Please install Git or add it to your PATH."
    exit 1
}
$gitPath = Split-Path $gitExe.Path

$flutterExe = Get-Command flutter -ErrorAction SilentlyContinue
if ($null -eq $flutterExe) {
    Write-Error "Flutter executable not found in PATH. Please install Flutter or add it to your PATH."
    exit 1
}
$flutterPath = Split-Path $flutterExe.Path

$system32Path = "$env:windir\System32"
# Update PATH for current session
$env:PATH = "$system32Path;$gitPath;$flutterPath;$env:PATH"

Write-Output "✓ Git added to PATH: " -NoNewline
Write-Host (git --version) -ForegroundColor White

Write-Output "✓ Flutter added to PATH: " -NoNewline
$flutterVersion = flutter --version 2>&1 | Select-String "Flutter" | Select-Object -First 1
Write-Host $flutterVersion -ForegroundColor White

Write-Host "`nEnvironment ready! You can now use 'flutter' commands.`n" -ForegroundColor Green
