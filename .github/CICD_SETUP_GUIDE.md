# CI/CD Pipeline Setup Guide

## Overview

This repository uses a unified, comprehensive CI/CD pipeline defined in `.github/workflows/ci.yml`. The pipeline includes:

1. **Linting & Code Quality** - Ruff, Black
2. **Unit Tests & Coverage** - Pytest with coverage reporting
3. **Security Analysis** - Bandit, Semgrep
4. **SonarCloud Integration** - Cloud-based code analysis
5. **Self-Hosted SonarQube** (Optional) - On-premise code quality
6. **Docker Image Build** - Container image creation and push
7. **Deployment** - Placeholder for production deployment

## Quick Setup

### 1. Configure SonarCloud (Required for Cloud Analysis)

#### Step 1a: Create SonarCloud Account
- Go to https://sonarcloud.io and sign up
- Log in with your GitHub account
- Authorize SonarCloud to access your repositories

#### Step 1b: Add Repository to SonarCloud
- Click "+" in SonarCloud to add a new organization
- Select "GitHub" as the provider
- Import the `Dino-pit-studios-llc` organization
- Select the `DinoAir3` repository

#### Step 1c: Generate SonarCloud Token
1. Go to https://sonarcloud.io/account/security
2. Click "Generate Tokens"
3. Create a new token with name "GitHub Actions" (or similar)
4. **Copy the token** (you'll need it in the next step)

#### Step 1d: Add Secret to GitHub Repository
1. Go to your repository on GitHub
2. Navigate to **Settings > Secrets and variables > Actions**
3. Click **New repository secret**
4. Create secret named: `SONAR_TOKEN`
5. Paste the token you generated in Step 1c
6. Click **Add secret**

#### Step 1e: Verify sonar-project.properties
The file `.github/sonar-project.properties` should have:
```properties
sonar.projectKey=Dino-pit-studios-llc_DinoAir3
sonar.organization=dino-pit-studios-llc
```

### 2. Configure Self-Hosted SonarQube (Optional)

**Skip this section if you don't have a self-hosted SonarQube instance.**

#### Step 2a: Set Up SonarQube Server
- Install SonarQube on your internal server (Docker, K8s, or standalone)
- Start the SonarQube service and verify it's accessible
- Default URL: `http://localhost:9000`

#### Step 2b: Create Project in SonarQube
1. Log in to your SonarQube instance
2. Go to **Administration > Projects**
3. Click **Create project**
4. Project key: `dinoair3` (must match GitHub variable below)
5. Project name: `DinoAir3`
6. Finish setup

#### Step 2c: Generate SonarQube Token
1. Log in to SonarQube
2. Go to **My Account > Security**
3. Click **Generate Tokens**
4. Create token named "GitHub Actions"
5. **Copy the token**

#### Step 2d: Add Secrets to GitHub
1. Go to **Settings > Secrets and variables > Actions**
2. Create two secrets:
   - Name: `SONARQUBE_HOST_URL` → Value: `http://your-sonarqube-server:9000`
   - Name: `SONARQUBE_TOKEN` → Value: `paste-your-token-here`

#### Step 2e: Add Repository Variable
1. Go to **Settings > Secrets and variables > Actions > Variables**
2. Click **New repository variable**
3. Name: `SONARQUBE_ENABLED` → Value: `true`
4. Also add: `SONARQUBE_PROJECT_KEY` → Value: `dinoair3`

### 3. Configure Docker Registry (Optional)

The pipeline builds and pushes Docker images to GitHub Container Registry (GHCR).

#### Step 3a: Verify GHCR Access
The workflow uses `${{ secrets.GITHUB_TOKEN }}` (automatically available) to push to GHCR.

#### Step 3b: Check Dockerfile
Ensure `Dockerfile.mcp` exists in repository root:
```dockerfile
FROM python:3.11-slim
WORKDIR /app
# ... rest of Dockerfile
```

### 4. Configure Additional Tools (Optional)

#### Codecov Integration
- Add `CODECOV_TOKEN` secret if you want Codecov.io coverage reporting
- Leave empty or undefined to skip

#### GitHub Actions Tokens
- `GITHUB_TOKEN` is automatically provided by GitHub Actions
- No configuration needed

## Workflow Triggers

The CI/CD pipeline runs on:

| Event | Branches | Jobs Run |
|-------|----------|----------|
| `push` | `main`, `develop` | All jobs |
| `pull_request` | `main`, `develop` | All jobs except `build` and `deploy` |

### Conditional Jobs

- **build**: Only runs on `push` to `main` after all quality checks pass
- **deploy**: Only runs on `push` to `main` after successful build
- **sonarqube-selfhosted**: Only runs if `SONARQUBE_ENABLED` variable = `true`

## Job Details

### 1. Lint (15 min timeout)
Runs code formatting and linting checks:
- `ruff check .` - Python linter
- `ruff format . --check` - Format check
- `black . --check` - Alternative formatter
- Caches pip dependencies for faster execution

### 2. Test (30 min timeout)
Runs unit tests with PostgreSQL service:
- Sets up Python 3.11 environment
- Starts PostgreSQL 15 container on port 5432
- Runs `pytest` with coverage collection
- Generates: `coverage.xml`, `test-results.xml`, HTML coverage report
- Uploads results to Codecov (if token configured)

**Database Credentials for Tests:**
- User: `dinoair`
- Password: `testpass`
- Database: `dinoair_test`
- Host: `localhost:5432`

### 3. Security (15 min timeout)
Runs security scanning tools:
- **Bandit** - Scans for Python security vulnerabilities
- **Semgrep** - Pattern-based static analysis (SAST)
- Excludes: `venv`, `.venv`, `migrations`
- Artifacts: `bandit-report.json`, `semgrep-report.json`

### 4. SonarCloud (20 min timeout)
Uploads code analysis to SonarCloud:
- Generates coverage and security reports
- Sends to SonarCloud for cloud analysis
- **Requires**: `SONAR_TOKEN` secret
- Waits for quality gate decision (if configured)

### 5. SonarQube Self-Hosted (20 min timeout)
Optional analysis on self-hosted SonarQube:
- Downloads sonar-scanner CLI
- Scans project and uploads to internal SonarQube
- Maps branches correctly for PR analysis
- **Requires**: `SONARQUBE_ENABLED=true` variable
- **Requires**: `SONARQUBE_HOST_URL` and `SONARQUBE_TOKEN` secrets

### 6. Build (30 min timeout)
Builds and pushes Docker image (main push only):
- Uses Docker Buildx for multi-platform support
- Logs into GitHub Container Registry (GHCR)
- Tags: branch, semver, commit SHA
- Caches layers via GitHub Actions cache
- Destination: `ghcr.io/Dino-pit-studios-llc/DinoAir3`

### 7. Deploy (15 min timeout)
Placeholder for production deployment:
- Add your deployment steps here
- Runs after successful build on main push
- Configure your target: AWS, GCP, Heroku, Kubernetes, etc.

## Configuration Files

### `.github/workflows/ci.yml`
Main workflow file - defines all jobs and stages.

### `sonar-project.properties`
SonarQube/SonarCloud configuration:
```properties
sonar.projectKey=Dino-pit-studios-llc_DinoAir3
sonar.organization=dino-pit-studios-llc
sonar.python.version=3.11
sonar.python.coverage.reportPaths=coverage.xml
sonar.python.xunit.reportPath=test-results.xml
sonar.python.bandit.reportPaths=bandit-report.json
```

### `pyproject.toml`
Python project configuration (Ruff, Pytest):
```toml
[tool.ruff]
line-length = 120
src = ["API", "core_router", "database", ...]

[tool.pytest.ini_options]
addopts = "-ra -q --cov --cov-report=term-missing"
```

## Secrets Reference

| Secret | Purpose | Where to Get |
|--------|---------|--------------|
| `SONAR_TOKEN` | SonarCloud authentication | SonarCloud → Account → Security |
| `SONARQUBE_HOST_URL` | Self-hosted SonarQube URL | Your admin |
| `SONARQUBE_TOKEN` | Self-hosted SonarQube token | SonarQube → My Account → Security |
| `CODECOV_TOKEN` | Codecov.io integration | Codecov → Settings |
| `GITHUB_TOKEN` | GitHub API (auto-provided) | Automatic |

## Variables Reference

| Variable | Purpose | Example |
|----------|---------|---------|
| `SONARQUBE_ENABLED` | Enable self-hosted SonarQube job | `true` or `false` |
| `SONARQUBE_PROJECT_KEY` | SonarQube project identifier | `dinoair3` |

## Troubleshooting

### SonarCloud Analysis Not Running
- **Check**: Is `SONAR_TOKEN` secret configured?
- **Check**: Does `sonar-project.properties` have correct org/key?
- **Fix**: Re-generate token and update secret

### Tests Failing in CI
- **Check**: Does `DATABASE_URL` need adjustment?
- **Check**: Are all dependencies in `requirements-dev.txt`?
- **Fix**: Run locally first: `pytest --cov`

### Docker Build Fails
- **Check**: Does `Dockerfile.mcp` exist?
- **Check**: Are all COPY paths correct?
- **Fix**: Test locally: `docker build -f Dockerfile.mcp .`

### SonarQube Server Unreachable
- **Check**: Is your SonarQube server running?
- **Check**: Is the URL correct in secret?
- **Check**: Can GitHub Actions reach the server (firewall)?
- **Fix**: Verify URL with `curl` from runner

## Best Practices

1. **Caching**: All jobs use action caching for pip, sonar-scanner
2. **Parallelization**: Jobs run in parallel (except build/deploy which need previous jobs)
3. **Fail-Safe**: Non-critical jobs have `continue-on-error: true`
4. **Secrets**: All tokens use `${{ secrets.* }}` - never hardcode
5. **Branches**: Only build/deploy on main; PR checks run on all branches

## Maintenance

### Weekly
- Check workflow run status: **Actions** tab in GitHub
- Review SonarCloud quality gate results

### Monthly
- Rotate tokens (Sonar, Codecov, etc.)
- Update GitHub Actions versions (e.g., `v4`, `v5`)
- Review and update Python dependencies

### Quarterly
- Audit workflow permissions (currently: `contents: read`, `packages: write`)
- Review and update exclusion patterns
- Update docker base image versions

## Support

- **GitHub Actions Docs**: https://docs.github.com/en/actions
- **SonarCloud Docs**: https://docs.sonarcloud.io
- **SonarQube Docs**: https://docs.sonarqube.org
- **Pytest Coverage**: https://pytest-cov.readthedocs.io

---

**Last Updated**: October 2024  
**Maintained By**: DevOps Team  
**Status**: ✅ Production Ready
