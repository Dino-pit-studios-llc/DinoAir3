# Code Coverage Quick Start Guide

## 🚀 Quick Setup (5 minutes)

### 1. Install Dependencies

```bash
pip install pytest pytest-cov pytest-asyncio pytest-mock
```

### 2. Configure GitHub Secrets

#### Add CODACY_PROJECT_TOKEN

1. Go to [Codacy Project Settings](https://app.codacy.com/gh/DinoPitStudios-org/DinoAir3/settings)
2. Navigate to **Integrations** → **Project API**
3. Copy the project token
4. Add to GitHub: [Repository Secrets](https://github.com/DinoPitStudios-org/DinoAir3/settings/secrets/actions)
   - Name: `CODACY_PROJECT_TOKEN`
   - Value: [paste token]

#### Add SONAR_TOKEN

1. Go to [SonarCloud Security](https://sonarcloud.io/account/security)
2. Generate new token
3. Copy the token
4. Add to GitHub: [Repository Secrets](https://github.com/DinoPitStudios-org/DinoAir3/settings/secrets/actions)
   - Name: `SONAR_TOKEN`
   - Value: [paste token]

### 3. Run Coverage Locally

**Windows (PowerShell):**

```powershell
.\run-coverage.ps1
```

**Linux/Mac:**

```bash
chmod +x run-coverage.sh
./run-coverage.sh
```

**Manual:**

```bash
pytest --cov --cov-report=html --cov-report=term
```

### 4. View Results

**Local HTML Report:**

```bash
# Windows
start htmlcov\index.html

# Mac
open htmlcov/index.html

# Linux
xdg-open htmlcov/index.html
```

**Online Dashboards:**

- **Codacy**: https://app.codacy.com/gh/DinoPitStudios-org/DinoAir3
- **SonarCloud**: https://sonarcloud.io/project/overview?id=DinoPitStudios-org_DinoAir3

## 📊 What Gets Analyzed

### Included in Coverage

✅ All Python files in project root
✅ `API/`, `core_router/`, `database/`, `models/`
✅ `rag/`, `routing/`, `tools/`, `utils/`
✅ Custom business logic and services

### Excluded from Coverage

❌ `tests/` - Test files themselves
❌ `**/migrations/` - Database migrations
❌ `**/__pycache__/` - Python cache
❌ `**/venv/`, `**/.venv/` - Virtual environments
❌ `scripts/setup/` - Setup scripts
❌ `docs/` - Documentation

## 🔄 Workflow Automation

The GitHub Actions workflow (`.github/workflows/coverage.yml`) automatically:

1. **Runs on**: Push to main/master/features, Pull Requests
2. **Executes**: All tests with coverage
3. **Generates**: XML and HTML coverage reports
4. **Uploads to**: Codacy and SonarCloud
5. **Comments**: Coverage summary on PRs
6. **Stores**: Coverage artifacts for 30 days

### Manual Trigger

1. Go to [Actions Tab](https://github.com/DinoPitStudios-org/DinoAir3/actions/workflows/coverage.yml)
2. Click **Run workflow**
3. Select branch
4. Click **Run workflow** button

## 📈 Coverage Goals

| Component      | Target | Current |
| -------------- | ------ | ------- |
| Overall        | 80%    | TBD     |
| New Code       | 90%    | TBD     |
| Critical Paths | 95%    | TBD     |
| API Routes     | 85%    | TBD     |
| Database       | 85%    | TBD     |
| Utilities      | 85%    | TBD     |

## 🛠️ Configuration Files

| File                             | Purpose                                         |
| -------------------------------- | ----------------------------------------------- |
| `.coveragerc`                    | Coverage.py settings (what to measure, exclude) |
| `.codacy.yml`                    | Codacy integration (engines, quality gates)     |
| `sonar-project.properties`       | SonarCloud config (coverage paths)              |
| `.github/workflows/coverage.yml` | GitHub Actions automation                       |

## 🐛 Troubleshooting

### Coverage Report Not Generated

```bash
# Check if pytest-cov is installed
pip list | grep pytest-cov

# Install if missing
pip install pytest-cov
```

### Coverage Seems Too Low

```bash
# Check what files are being excluded
cat .coveragerc

# Verify tests are running
pytest -v

# Check for test discovery issues
pytest --collect-only
```

### GitHub Actions Failing

1. Check [Actions Tab](https://github.com/DinoPitStudios-org/DinoAir3/actions) for error logs
2. Verify both secrets are set correctly
3. Check workflow syntax in `.github/workflows/coverage.yml`
4. Ensure dependencies in workflow match `requirements.txt`

### Coverage Upload Fails

- **Codacy**: Verify `CODACY_PROJECT_TOKEN` is set
- **SonarCloud**: Verify `SONAR_TOKEN` is set
- Check that `coverage.xml` was generated
- Review upload logs in GitHub Actions output

## 📚 Resources

- **Full Documentation**: [docs/CODE_COVERAGE_SETUP.md](./CODE_COVERAGE_SETUP.md)
- **pytest-cov docs**: https://pytest-cov.readthedocs.io/
- **Codacy Coverage**: https://docs.codacy.com/coverage-reporter/
- **SonarCloud**: https://docs.sonarcloud.io/enriching/test-coverage/python/

## ✅ Checklist

- [ ] Install pytest and pytest-cov
- [ ] Add CODACY_PROJECT_TOKEN to GitHub secrets
- [ ] Add SONAR_TOKEN to GitHub secrets
- [ ] Run coverage locally and verify it works
- [ ] Push changes and verify GitHub Actions workflow runs
- [ ] Check Codacy dashboard for coverage data
- [ ] Check SonarCloud dashboard for coverage data
- [ ] Review coverage report and identify gaps
- [ ] Set coverage thresholds in `.coveragerc`

## 🎯 Next Steps

1. **Run Initial Coverage**: Execute `run-coverage.ps1` or `run-coverage.sh`
2. **Review Report**: Open `htmlcov/index.html` in browser
3. **Identify Gaps**: Find files/functions with <80% coverage
4. **Write Tests**: Add tests for uncovered code paths
5. **Verify**: Re-run coverage to see improvements
6. **Commit**: Push changes to trigger automated workflow
7. **Monitor**: Check Codacy/SonarCloud dashboards regularly
