# SonarCloud Setup Documentation

## Overview

This project uses SonarCloud for continuous code quality and security analysis.

## Configuration Files

### 1. `.github/workflows/build.yml`

The GitHub Actions workflow that runs SonarCloud analysis on every push to main and on pull requests.

**Key Configuration:**

- **Action**: `SonarSource/sonarcloud-github-action@master` (correct for SonarCloud)
- **Environment Variables**:
  - `GITHUB_TOKEN`: Automatically provided by GitHub Actions
  - `SONAR_TOKEN`: Must be set in repository secrets

### 2. `sonar-project.properties`

The SonarCloud configuration file.

**Key Settings:**

- `sonar.projectKey`: `DinoPitStudios-org_DinoAir3`
- `sonar.organization`: `dinopitstudios-llc`
- `sonar.python.version`: `3.11`
- Exclusions for test files, cache, and build artifacts

## Setup Instructions

### 1. SonarCloud Token

1. Go to [SonarCloud](https://sonarcloud.io/)
2. Navigate to your account settings
3. Generate a new token under Security tab
4. Add the token to GitHub repository secrets as `SONAR_TOKEN`:
   - Go to repository Settings → Secrets and variables → Actions
   - Click "New repository secret"
   - Name: `SONAR_TOKEN`
   - Value: Your SonarCloud token

### 2. Project Configuration

The project is already configured with:

- Project Key: `DinoPitStudios-org_DinoAir3`
- Organization: `dinopitstudios-llc`

Verify these match your SonarCloud project settings.

## Common Issues & Solutions

### Issue 1: Wrong Action Used

**Problem**: Using `SonarSource/sonarqube-scan-action` instead of `SonarSource/sonarcloud-github-action`

**Solution**: Use the correct action for SonarCloud:

```yaml
- uses: SonarSource/sonarcloud-github-action@master
```

### Issue 2: Missing GITHUB_TOKEN

**Problem**: PR analysis doesn't work properly

**Solution**: Add GITHUB_TOKEN to env:

```yaml
env:
  GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
  SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
```

### Issue 3: Too Many Files Analyzed

**Problem**: SonarCloud analyzing test files, cache, etc.

**Solution**: Configure exclusions in `sonar-project.properties`:

```properties
sonar.exclusions=**/tests/**,**/__pycache__/**,**/venv/**
```

## Differences: SonarQube vs SonarCloud

| Feature       | SonarQube (On-Premise)      | SonarCloud (Cloud)              |
| ------------- | --------------------------- | ------------------------------- |
| GitHub Action | `sonarqube-scan-action`     | `sonarcloud-github-action`      |
| Host URL      | Required (`SONAR_HOST_URL`) | Not needed (uses sonarcloud.io) |
| Token         | Required                    | Required                        |
| GitHub Token  | Optional                    | Recommended (for PR analysis)   |

## Testing the Setup

1. Push code to main branch or create a pull request
2. Check GitHub Actions tab for workflow execution
3. Visit [SonarCloud Dashboard](https://sonarcloud.io/organizations/dinopitstudios-llc)
4. Verify analysis results appear for your project

## Additional Resources

- [SonarCloud Documentation](https://docs.sonarcloud.io/)
- [GitHub Action for SonarCloud](https://github.com/SonarSource/sonarcloud-github-action)
- [Python Analysis Parameters](https://docs.sonarcloud.io/enriching/languages/python/)
