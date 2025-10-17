# Helper script to run Flutter with proper PATH
. .\setup-env.ps1

Write-Output "Environment configured:"
Write-Output "  Git: $(git --version)"
Write-Output "  Flutter: $(flutter --version --suppress-analytics | Select-Object -First 1)"
Write-Output ""

# Pass all arguments to flutter
& flutter $args
