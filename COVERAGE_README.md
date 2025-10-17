# Code Coverage Setup - README

This directory now has **complete code coverage analysis** configured for SonarCloud and Codacy.

## 🚀 Quick Start

### 1. Run Coverage Locally

**Windows (PowerShell):**

```powershell
.\run-coverage.ps1
```

**Linux/Mac:**

```bash
chmod +x run-coverage.sh
./run-coverage.sh
```

### 2. View Results

Open `htmlcov/index.html` in your browser to see detailed coverage report.

### 3. Before First Push

⚠️ **Add these GitHub secrets** (required for CI/CD):

1. **CODACY_PROJECT_TOKEN**: Get from [Codacy Settings](https://app.codacy.com/gh/DinoPitStudios-org/DinoAir3/settings)
2. **SONAR_TOKEN**: Get from [SonarCloud Security](https://sonarcloud.io/account/security)

Add them at: [Repository Secrets](https://github.com/DinoPitStudios-org/DinoAir3/settings/secrets/actions)

## 📊 Dashboards

- **Codacy**: https://app.codacy.com/gh/DinoPitStudios-org/DinoAir3
- **SonarCloud**: https://sonarcloud.io/project/overview?id=DinoPitStudios-org_DinoAir3

## 📚 Documentation

| Document                                                        | Purpose                          |
| --------------------------------------------------------------- | -------------------------------- |
| **[COVERAGE_QUICK_START.md](docs/COVERAGE_QUICK_START.md)**     | 5-minute setup guide             |
| **[CODE_COVERAGE_SETUP.md](docs/CODE_COVERAGE_SETUP.md)**       | Complete technical documentation |
| **[COVERAGE_SETUP_SUMMARY.md](docs/COVERAGE_SETUP_SUMMARY.md)** | Implementation summary           |

## 🔧 Configuration Files

- `.coveragerc` - Coverage measurement settings
- `.codacy.yml` - Codacy quality gates and engines
- `sonar-project.properties` - SonarCloud integration
- `.github/workflows/coverage.yml` - GitHub Actions automation

## ✅ What's Automated

On every push and PR, GitHub Actions will automatically:

- ✅ Run all tests with coverage
- ✅ Generate coverage reports (XML + HTML)
- ✅ Upload to Codacy
- ✅ Send to SonarCloud
- ✅ Comment on PRs with coverage summary
- ✅ Store artifacts for 30 days

## 🎯 Coverage Goals

Start at current baseline and gradually increase thresholds in `.coveragerc`:

```ini
[coverage:report]
fail_under = 0  # Increase to 60, then 70, then 80
```

## 🐛 Troubleshooting

**"pytest not found"**

```bash
pip install pytest pytest-cov pytest-asyncio pytest-mock
```

**"GitHub Actions failing"**

- Verify GitHub secrets are set (CODACY_PROJECT_TOKEN, SONAR_TOKEN)
- Check workflow logs in Actions tab

**"Coverage seems low"**

- Review HTML report: `htmlcov/index.html`
- Write tests for uncovered lines
- Check `.coveragerc` exclusions

## 💡 Tips

1. Run coverage before committing: `.\run-coverage.ps1`
2. Review HTML report to find gaps
3. Write tests for uncovered code
4. Gradually increase thresholds
5. Monitor dashboards for trends

---

**Need help?** See full documentation in `docs/CODE_COVERAGE_SETUP.md`
