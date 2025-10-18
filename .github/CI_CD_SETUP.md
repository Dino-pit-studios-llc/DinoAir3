# GitHub Actions CI/CD Setup Guide

This guide explains how to configure GitHub Actions for the DinoAir3 project with Codacy and DeepSource integration.

## Overview

The CI/CD pipeline includes:
- **Lint & Format Check**: Ruff and Black formatting validation
- **Tests & Coverage**: pytest with coverage reporting
- **Security Checks**: Bandit security vulnerability scanning
- **Codacy Analysis**: Code quality and coverage analysis
- **DeepSource Analysis**: Automated code reviews and issue detection
- **Build Docker Image**: Build and push Docker images on main branch
- **Deploy**: Deployment placeholder for your infrastructure

## Setup Instructions

### 1. Create GitHub Secrets

Go to your GitHub repository settings at **Settings > Secrets and variables > Actions** and add the following secrets:

#### Required Secrets:

**CODACY_PROJECT_TOKEN**

⚠️ **The value below is a PLACEHOLDER. You must obtain your actual token from Codacy:**
1. Log in to [Codacy](https://app.codacy.com)
2. Navigate to your DinoAir3 project
3. Go to **Settings → Coverage → Project API token**
4. Copy your actual project token

```
YOUR_ACTUAL_CODACY_TOKEN_HERE
```
This token enables Codacy coverage reporting.

**DEEPSOURCE_DSN**

⚠️ **The value below is a PLACEHOLDER. You must obtain your actual DSN from DeepSource:**
1. Log in to [DeepSource](https://deepsource.io)
2. Navigate to your DinoAir3 repository
3. Go to **Settings → Code Coverage**
4. Copy your actual repository DSN (starts with `dsp_`)

```
YOUR_ACTUAL_DEEPSOURCE_DSN_HERE
```
This DSN enables DeepSource analysis reporting.

### 2. Configure Codacy

1. Go to [Codacy Dashboard](https://app.codacy.com)
2. Navigate to your DinoAir3 project
3. Go to **Settings > Integrations > Repository Token**
4. Copy your project token (the one provided above)
5. Verify that Python analysis is enabled in **Settings > Code Analysis > Analyzers**

### 3. Configure DeepSource

1. Go to [DeepSource Dashboard](https://deepsource.io)
2. Navigate to your DinoAir3 repository
3. In **Settings > Credentials**, you'll see your repository DSN
4. The DSN is already configured in your `.deepsource.toml` file

### 4. Verify Configuration Files

The following files are required for CI/CD:

- `.github/workflows/ci.yml` - Main CI workflow (created)
- `.deepsource.toml` - DeepSource configuration (existing)
- `pyproject.toml` - Ruff and tool configurations (existing)
- `pytest.ini` - pytest configuration (existing)

## Workflow Details

### Triggers

Workflows run on:
- Push to `main` or `develop` branches
- Pull requests to `main` or `develop` branches

### Job Stages

#### 1. Lint (5-15 min)
- Validates Python code formatting with Ruff and Black
- Runs on every push and PR

#### 2. Test & Coverage (15-30 min)
- Runs pytest with coverage reporting
- Uploads coverage to Codecov
- Services: PostgreSQL for database tests
- Runs on every push and PR

#### 3. Security (5-15 min)
- Runs Bandit security vulnerability scanner
- Uploads results as artifacts
- Runs on every push and PR

#### 4. Codacy Analysis (10-20 min)
- Generates coverage report
- Submits to Codacy for analysis
- Runs on every push and PR

#### 5. DeepSource Analysis (10-20 min)
- Analyzes Python code with DeepSource
- Scans for secrets
- Runs on every push and PR

#### 6. Build Docker (15-30 min)
- Builds and pushes Docker image
- Only runs on successful lint/test/security on main branch
- Requires: `GITHUB_TOKEN` (automatically available)

#### 7. Deploy (5-15 min)
- Placeholder for deployment steps
- Configure based on your infrastructure (AWS, GCP, Heroku, DigitalOcean)
- Only runs on successful build on main branch

## Expected Behavior

### On PR Creation
1. All jobs run (lint, test, security, codacy, deepsource)
2. Check status appears on PR
3. Codacy and DeepSource post PR comments with findings

### On Merge to Main
1. All jobs run
2. Docker image builds and pushes to container registry
3. Deployment workflow runs (currently placeholder)

### On Push to Main
- Same as merge to main

## Monitoring & Troubleshooting

### View Workflow Runs
1. Go to your repository
2. Click **Actions** tab
3. Select the workflow run to see detailed logs

### Common Issues

**Codacy token rejected**
- Verify token is correct in GitHub Secrets
- Ensure token is not expired in Codacy dashboard
- Check that project is registered in Codacy

**DeepSource not reporting**
- Verify DSN is correct in GitHub Secrets
- Check `.deepsource.toml` configuration
- Review DeepSource dashboard for repository status

**Docker push fails**
- Ensure `GITHUB_TOKEN` has write access to packages
- Verify Dockerfile path is correct: `./Dockerfile.mcp`
- Check container registry settings

**Test database connection fails**
- Verify PostgreSQL service is running
- Check `DATABASE_URL` environment variable format
- Review test database credentials

## Environment Variables

Key environment variables used in workflows:

- `PYTHON_VERSION`: 3.11 (specified in env)
- `DATABASE_URL`: PostgreSQL connection string (test jobs)
- `REGISTRY`: ghcr.io (GitHub Container Registry)

## Cost Considerations

GitHub Actions provides free tier usage:
- **Public repos**: Unlimited minutes
- **Private repos**: 2,000 minutes/month

Current workflow roughly uses:
- Lint: ~5 min per run
- Test: ~10-15 min per run
- Security: ~5 min per run
- Codacy: ~10 min per run
- DeepSource: ~10 min per run
- Build: ~15 min per run
- **Total per run**: ~55-60 minutes

Estimated monthly usage (assuming 10 PRs and 10 merges):
- PR runs: 10 × ~50 min = 500 min
- Merge runs: 10 × ~60 min = 600 min
- **Total**: ~1,100 min/month (well within free tier)

## Next Steps

1. Push the `.github/workflows/ci.yml` file to your repository
2. Add GitHub Secrets (`CODACY_PROJECT_TOKEN`, `DEEPSOURCE_DSN`)
3. Monitor first workflow run in Actions tab
4. Configure deployment steps based on your infrastructure
5. Set branch protection rules to require CI checks pass before merge

## Advanced Configuration

### Customize Job Conditions
Edit `ci.yml` to add conditions like:
```yaml
if: github.event_name == 'pull_request' || github.ref == 'refs/heads/main'
```

### Add Additional Analyzers
DeepSource supports additional analyzers. Configure in `.deepsource.toml`:
```toml
[[analyzers]]
name = "python"
```

### Integration with Other Tools
- **Slack Notifications**: Add slack-notify action
- **GitHub Issues**: Auto-create issues from security findings
- **Analytics**: Track CI metrics over time

## References

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Codacy GitHub Actions](https://github.com/codacy/codacy-coverage-reporter-action)
- [DeepSource GitHub Integration](https://deepsource.io/docs/github/)
- [Codecov Integration](https://github.com/codecov/codecov-action)
