# CodeQL Security Analysis Script for DinoAir
# Analyzes Python and JavaScript code for security vulnerabilities

Write-Output "CodeQL Security Analysis"
Write-Output "======================="

# Configuration
$projectPath = Get-Location
$databaseDir = "codeql-databases"
$resultsDir = "codeql-results"
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"

# Directories to exclude from analysis (library/vendor code)
$excludeDirs = @(".venv", "venv", "node_modules", "__pycache__", ".git", "build", "dist")
$excludePattern = ($excludeDirs | ForEach-Object { "*$_*" }) -join ","

# Ensure CodeQL is in PATH
$codeqlPath = "C:\Users\DinoP\Documents\codeql-bundle-win64\codeql"
if (-not ($env:PATH -like "*$codeqlPath*")) {
    $env:PATH = "$codeqlPath;$env:PATH"
}

# Create directories
New-Item -ItemType Directory -Force -Path $databaseDir | Out-Null
New-Item -ItemType Directory -Force -Path $resultsDir | Out-Null

# Prepare query suites directory and duplicate-code suites
$suitesDir = "codeql-suites"
New-Item -ItemType Directory -Force -Path $suitesDir | Out-Null

# Define comprehensive duplicate-code query suites for Python and JavaScript/TypeScript
# Include both structural duplicates and similarity-based detection
$pythonSuite = @"
- from: codeql/python-queries
  query: external/DuplicateFunction.ql
- from: codeql/python-queries
  query: external/DuplicateBlock.ql
- from: codeql/python-queries
  query: external/MostlyDuplicateClass.ql
- from: codeql/python-queries
  query: external/MostlyDuplicateFile.ql
- from: codeql/python-queries
  query: Metrics/FLinesOfDuplicatedCode.ql
- from: codeql/python-queries
  query: Expressions/DuplicateKeyInDictionaryLiteral.ql
"@

$jsSuite = @"
- from: codeql/javascript-queries
  query: external/DuplicateFunction.ql
- from: codeql/javascript-queries
  query: external/DuplicateToplevel.ql
- from: codeql/javascript-queries
  query: Metrics/FLinesOfDuplicatedCode.ql
- from: codeql/javascript-queries
  query: Expressions/DuplicateCondition.ql
- from: codeql/javascript-queries
  query: Expressions/DuplicateSwitchCase.ql
- from: codeql/javascript-queries
  query: Declarations/DuplicateVarDecl.ql
- from: codeql/javascript-queries
  query: DOM/DuplicateAttributes.ql
- from: codeql/javascript-queries
  query: AngularJS/DuplicateDependency.ql
- from: codeql/javascript-queries
  query: RegExp/DuplicateCharacterInCharacterClass.ql
"@

$pythonSuitePath = Join-Path $suitesDir "python-duplicates.qls"
$jsSuitePath    = Join-Path $suitesDir "javascript-duplicates.qls"

$pythonSuite | Set-Content -Path $pythonSuitePath -Encoding UTF8
$jsSuite     | Set-Content -Path $jsSuitePath -Encoding UTF8

Write-Output "Project: $projectPath"
Write-Output "Database directory: $databaseDir"
Write-Output "Results directory: $resultsDir"
Write-Output "Suites directory: $suitesDir"

# Function to run CodeQL analysis for a language
function Invoke-CodeQLAnalysis {
    param($Language, $DatabaseName)

    Write-Warning "`nAnalyzing $Language code..."

    try {
        # Create database with exclusions for library directories
        Write-Output "Creating $Language database..."
        & codeql database create "$databaseDir\$DatabaseName" --language="$Language" --source-root="$projectPath" --overwrite

        if ($LASTEXITCODE -eq 0) {
            Write-Output "Database created successfully"

            # Run analysis with security suite
            Write-Output "Running security analysis..."
            & codeql database analyze "$databaseDir\$DatabaseName" "codeql/$Language-queries" --format=sarif-latest --output="$resultsDir\$DatabaseName-security-$timestamp.sarif"

            if ($LASTEXITCODE -eq 0) {
                Write-Output "Analysis completed successfully"

                # Run additional code scanning queries
                Write-Output "Running code scanning queries..."
                & codeql database analyze "$databaseDir\$DatabaseName" "codeql/$Language-queries" --format=csv --output="$resultsDir\$DatabaseName-scanning-$timestamp.csv"

                if ($LASTEXITCODE -eq 0) {
                    Write-Output "Code scanning completed"
                } else {
                    Write-Warning "Code scanning failed (non-critical)"
                }

                # Run duplicate-code detection using custom suites
                try {
                    Write-Output "Running duplicate code detection..."
                    $suitePath = if ($Language -eq "python") { "$suitesDir\python-duplicates.qls" } else { "$suitesDir\javascript-duplicates.qls" }
                    & codeql database analyze "$databaseDir\$DatabaseName" $suitePath --format=sarif-latest --output="$resultsDir\$DatabaseName-duplicates-$timestamp.sarif"

                    if ($LASTEXITCODE -eq 0) {
                        Write-Output "Duplicate code detection completed"
                    } else {
                        Write-Warning "Duplicate code detection failed (non-critical)"
                    }
                } catch {
                    Write-Warning "Error during duplicate code detection: $_"
                }

                # Run additional manual duplicate detection for better coverage
                try {
                    Write-Output "Running enhanced duplicate detection with lower thresholds..."

                    # Create custom query for similarity-based duplicates with lower thresholds
                    $customQueryDir = "custom-queries"
                    New-Item -ItemType Directory -Force -Path $customQueryDir | Out-Null

                    if ($Language -eq "python") {
                        $customPythonQuery = @"
/**
 * @name Similar functions (relaxed threshold)
 * @description Find functions that are very similar to each other
 * @kind problem
 * @problem.severity recommendation
 * @precision medium
 * @id py/similar-function-relaxed
 * @tags maintainability
 *       duplicate-code
 */

import python

from Function f1, Function f2
where f1 != f2
  and f1.getLocation().getFile() = f2.getLocation().getFile()
  and f1.getNumLines() > 5
  and f2.getNumLines() > 5
  and f1.getName() != f2.getName()
  and exists(string s1, string s2 |
    s1 = f1.getABodyStmt().toString() and
    s2 = f2.getABodyStmt().toString() and
    s1 = s2
  )
select f1, "This function appears very similar to $@.", f2, f2.getName()
"@
                        $customPythonQuery | Set-Content -Path "$customQueryDir\similar-functions.ql" -Encoding UTF8

                        Write-Output "Running custom similarity query for Python..."
                        & codeql database analyze "$databaseDir\$DatabaseName" "$customQueryDir\similar-functions.ql" --format=sarif-latest --output="$resultsDir\$DatabaseName-similar-$timestamp.sarif" 2>$null
                    }

                    if ($LASTEXITCODE -eq 0) {
                        Write-Output "Enhanced duplicate detection completed"
                    } else {
                        Write-Warning "Enhanced duplicate detection had issues (non-critical)"
                    }
                } catch {
                    Write-Warning "Error during enhanced duplicate detection: $_"
                }

                return $true
            } else {
                Write-Error "Analysis failed"
                return $false
            }
        } else {
            Write-Error "Database creation failed"
            return $false
        }
    } catch {
        Write-Error "Error during $Language analysis: $_"
        return $false
    }
}

# Test CodeQL
Write-Output "`nTesting CodeQL installation..."
try {
    $version = & codeql version 2>&1
    Write-Output "CodeQL Version: $($version[0])"
} catch {
    Write-Host "CodeQL not found! Please ensure it's installed and in PATH" -ForegroundColor Red
    exit 1
}

# Languages to analyze
$languages = @(
    @{Language="python"; DatabaseName="dinoair-python"},
    @{Language="javascript"; DatabaseName="dinoair-javascript"}
)

$successCount = 0
$totalCount = $languages.Count

# Run analysis for each language
foreach ($config in $languages) {
    if (Invoke-CodeQLAnalysis -Language $config.Language -DatabaseName $config.DatabaseName) {
        $successCount++
    }
}

# Summary
Write-Output "`nAnalysis Summary"
Write-Output "================"
Write-Output "Successful analyses: $successCount/$totalCount"
Write-Output "Results saved to: $resultsDir"

if ($successCount -gt 0) {
    Write-Warning "`nGenerated files:"
    Get-ChildItem $resultsDir -Name | ForEach-Object {
        Write-Output "  - $_"
    }

    Write-Warning "`nTo view SARIF results:"
    Write-Output "1. Install SARIF Viewer extension in VS Code"
    Write-Output "2. Open .sarif files to view security findings"
    Write-Output "3. Check .csv files for detailed code scanning results"

    # Generate concise Markdown report for duplicate-code findings across languages
    try {
        $dupSarifs = Get-ChildItem $resultsDir -Filter "*-duplicates-$timestamp.sarif" -File -ErrorAction SilentlyContinue
        if ($dupSarifs -and $dupSarifs.Count -gt 0) {
            $mdPath = Join-Path $resultsDir "duplicate-code-summary-$timestamp.md"
            $lines = @(
                "# Duplicate Code Findings ($timestamp)",
                "",
                "| Language | File | Line | Rule | Message |",
                "|---|---|---:|---|---|"
            )
            foreach ($file in $dupSarifs) {
                $lang = if ($file.Name -like "*python*") { "Python" } else { "JavaScript/TypeScript" }
                $sarif = Get-Content $file.FullName -Raw | ConvertFrom-Json
                if ($sarif.runs -and $sarif.runs.Count -gt 0 -and $sarif.runs[0].results) {
                    foreach ($r in $sarif.runs[0].results) {
                        $ruleId = $r.ruleId
                        $msg = ($r.message.text | Out-String).Trim() -replace "\r?\n"," " -replace "\|","/"
                        if ($r.locations -and $r.locations.Count -gt 0) {
                            $loc = $r.locations[0]
                            $uri = $loc.physicalLocation.artifactLocation.uri
                            $line = $loc.physicalLocation.region.startLine
                            $lines += "| $lang | $uri | $line | $ruleId | $msg |"
                        } else {
                            $lines += "| $lang | - | - | $ruleId | $msg |"
                        }
                    }
                } else {
                    $lines += "| $lang | - | - | - | No duplicate code findings |"
                }
            }
            $lines | Set-Content -Path $mdPath -Encoding UTF8
            Write-Warning "`nDuplicate code summary written to: $mdPath"
        } else {
            Write-Warning "`nNo duplicate-code SARIF files found to summarize."
        }
    } catch {
        Write-Warning "Failed to generate duplicate code Markdown summary: $_"
    }
} else {
    Write-Error "No successful analyses completed"
}

Write-Output "`nDone!"
