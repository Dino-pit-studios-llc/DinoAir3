# Code Coverage Configuration for SonarCloud

This document describes the code coverage setup for DinoAir3 using pytest-cov and Codacy Coverage Reporter.

## Overview

Code coverage is measured using `pytest-cov` and reported to both SonarCloud and Codacy for comprehensive analysis.

## Tools Used

1. **pytest-cov**: Generates coverage data during test execution
2. **Codacy Coverage Reporter**: Uploads coverage to Codacy
3. **SonarCloud**: Analyzes coverage reports

## Configuration Files

### 1. `.coveragerc` - Coverage Configuration

Located at project root, configures coverage.py behavior.

### 2. `pyproject.toml` - Alternative Configuration

Coverage settings can also be in `[tool.coverage.*]` sections.

### 3. GitHub Actions Workflow

Automated coverage generation and reporting in CI/CD.

## Local Coverage Generation

### Run Tests with Coverage

```bash
# Run all tests with coverage
pytest --cov=. --cov-report=xml --cov-report=html --cov-report=term

# Run specific module with coverage
pytest tests/test_module.py --cov=module_name --cov-report=xml

# Run with verbose coverage report
pytest --cov=. --cov-report=term-missing
```

### Coverage Report Formats

- **XML**: For SonarCloud/Codacy (`coverage.xml`)
- **HTML**: For local browsing (`htmlcov/index.html`)
- **Terminal**: Quick overview in console

## CI/CD Coverage Workflow

### GitHub Actions Integration

```yaml
- name: Run tests with coverage
  run: |
    pytest --cov=. --cov-report=xml --cov-report=term

- name: Upload coverage to Codacy
  run: |
    bash <(curl -Ls https://coverage.codacy.com/get.sh) report -r coverage.xml
  env:
    CODACY_PROJECT_TOKEN: ${{ secrets.CODACY_PROJECT_TOKEN }}

- name: SonarCloud Scan with Coverage
  uses: SonarSource/sonarcloud-github-action@master
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
    SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
```

## Coverage Thresholds

### Recommended Thresholds

- **Overall Coverage**: ≥ 80%
- **New Code Coverage**: ≥ 90%
- **Critical Files**: ≥ 95%
- **Utility Modules**: ≥ 85%

### Enforce Thresholds

Add to `pytest.ini` or `pyproject.toml`:

```ini
[tool.coverage.report]
fail_under = 80
precision = 2
show_missing = true
skip_covered = false
```

## Exclusions

### Files to Exclude from Coverage

1. **Test Files**: `tests/`, `test_*.py`
2. **Configuration**: `**/config.py`, `settings.py`
3. **Migrations**: `**/migrations/`
4. **Generated Code**: `**/*_pb2.py`
5. **Virtual Environments**: `.venv/`, `venv/`
6. **Cache**: `__pycache__/`, `.pytest_cache/`

## Codacy Integration

### Required GitHub Secrets Setup

Before setting up Codacy integration, you need to configure the project token as a GitHub secret:

**Step 1: Get Codacy Project Token**

1. Go to [Codacy Dashboard](https://app.codacy.com/gh/DinoPitStudios-org/DinoAir3)
2. Click on your project name
3. Navigate to **Settings** → **Integrations**
4. Look for **Add Integration** and select **Project API**
5. Copy the **Project Token** (starts with a long alphanumeric string)

**Step 2: Add Token to GitHub**

1. Go to your GitHub repository: https://github.com/DinoPitStudios-org/DinoAir3
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Name: `CODACY_PROJECT_TOKEN`
5. Value: Paste the token from Step 1
6. Click **Add secret**

**Step 3: Verify Secret**

- The secret should now appear in the list (value will be hidden)
- The GitHub Actions workflow will use this automatically

### Setup Codacy Coverage Reporter

1. **For CI/CD** (GitHub Actions):
   The workflow file (`.github/workflows/coverage.yml`) already includes Codacy upload:

   ```bash
   bash <(curl -Ls https://coverage.codacy.com/get.sh) report -r coverage.xml
   ```

2. **For Local Testing** (optional):

   ```bash
   # Download and install
   curl -Ls https://coverage.codacy.com/get.sh > codacy-coverage.sh
   chmod +x codacy-coverage.sh

   # Upload coverage
   ./codacy-coverage.sh report -r coverage.xml
   ```

### Codacy Configuration

Create `.codacy.yml` in project root:

```yaml
---
engines:
  coverage:
    enabled: true

exclude_paths:
  - "tests/**"
  - "**/__pycache__/**"
  - "**/.venv/**"
  - "**/migrations/**"
```

## SonarCloud Integration

### Required GitHub Secrets Setup

The GitHub Actions workflow requires a SonarCloud token to upload coverage and analysis results:

**Step 1: Generate SonarCloud Token**

1. Go to [SonarCloud Security Settings](https://sonarcloud.io/account/security)
2. Under **Generate Tokens**, enter a token name (e.g., "DinoAir3-GitHub-Actions")
3. Click **Generate**
4. Copy the token immediately (you won't be able to see it again)

**Step 2: Add Token to GitHub**

1. Go to your GitHub repository: [DinoAir3 Settings](https://github.com/DinoPitStudios-org/DinoAir3/settings/secrets/actions)
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Name: `SONAR_TOKEN`
5. Value: Paste the token from Step 1
6. Click **Add secret**

**Step 3: Verify Integration**

- The secret should now appear in the secrets list
- The GitHub Actions workflow will automatically use this token
- After the next commit, check SonarCloud for coverage data

### Configure Coverage in sonar-project.properties

```properties
# Coverage reports
sonar.python.coverage.reportPaths=coverage.xml

# Test execution reports (optional)
sonar.python.xunit.reportPath=test-results.xml
```

### View Coverage in SonarCloud

1. Navigate to project on SonarCloud
2. Go to "Coverage" tab
3. Review overall and file-level coverage
4. Check coverage on new code

## Troubleshooting

### Coverage File Not Found

**Issue**: SonarCloud/Codacy can't find coverage.xml

**Solution**:

```bash
# Verify coverage.xml exists
ls -la coverage.xml

# Check file path in config
cat sonar-project.properties | grep coverage
```

### Low Coverage Reported

**Issue**: Coverage seems lower than expected

**Solutions**:

1. Check `.coveragerc` exclusions
2. Verify all source directories are included
3. Run coverage locally to debug: `pytest --cov=. --cov-report=term-missing`

### Multiple Coverage Files

**Issue**: Different tools generating different coverage files

**Solution**: Standardize on single format:

```bash
# Generate once, use everywhere
pytest --cov=. --cov-report=xml:coverage.xml

# Upload same file to all services
```

## Best Practices

### 1. Run Coverage Locally First

Always generate and review coverage locally before pushing:

```bash
pytest --cov=. --cov-report=html
open htmlcov/index.html  # or start htmlcov/index.html on Windows
```

### 2. Focus on Meaningful Coverage

- Don't chase 100% coverage for the sake of it
- Focus on business logic and critical paths
- Skip coverage for trivial getters/setters

### 3. Review Coverage in PRs

- Set up GitHub Actions to comment coverage changes
- Block PRs that decrease coverage significantly
- Review which new lines aren't covered

### 4. Incremental Improvement

- Set achievable coverage goals
- Gradually increase thresholds
- Celebrate coverage improvements

## Coverage Badges

### Add Coverage Badge to README

**Codacy**:

```markdown
[![Codacy Badge](https://app.codacy.com/project/badge/Coverage/{project-id})](https://app.codacy.com/gh/DinoPitStudios-org/DinoAir3)
```

**SonarCloud**:

```markdown
[![Coverage](https://sonarcloud.io/api/project_badges/measure?project=DinoPitStudios-org_DinoAir3&metric=coverage)](https://sonarcloud.io/dashboard?id=DinoPitStudios-org_DinoAir3)
```

## Monitoring Coverage Trends

### Key Metrics to Track

1. **Overall Coverage %**: Total lines covered
2. **Branch Coverage**: All code paths tested
3. **Coverage Delta**: Change from previous version
4. **Uncovered Lines**: Specific lines missing tests
5. **Coverage by Module**: Identify weak areas

### Tools for Monitoring

- **Codacy Dashboard**: Trends over time
- **SonarCloud Quality Gate**: Pass/fail criteria
- **GitHub PR Comments**: Immediate feedback
- **Local HTML Reports**: Detailed file-level view

## Advanced Configuration

### Branch Coverage

Enable in `.coveragerc`:

```ini
[run]
branch = True
```

### Parallel Coverage

For concurrent test execution:

```ini
[run]
parallel = True
concurrency = multiprocessing
```

Then combine results:

```bash
coverage combine
coverage xml
```

### Plugins

Add coverage plugins for specific frameworks:

```ini
[run]
plugins =
    django_coverage_plugin
    covdefaults
```

## Resources

- [Coverage.py Documentation](https://coverage.readthedocs.io/)
- [pytest-cov Documentation](https://pytest-cov.readthedocs.io/)
- [Codacy Coverage Reporter](https://docs.codacy.com/coverage-reporter/)
- [SonarCloud Python Coverage](https://docs.sonarcloud.io/enriching/test-coverage/python/)

## Quick Reference

```bash
# Generate coverage
pytest --cov=. --cov-report=xml --cov-report=html

# View HTML report
open htmlcov/index.html

# Upload to Codacy
bash <(curl -Ls https://coverage.codacy.com/get.sh) report -r coverage.xml

# Check coverage threshold
pytest --cov=. --cov-fail-under=80

# Coverage with specific tests
pytest tests/unit/ --cov=src --cov-report=term-missing
```
