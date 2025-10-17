# GitHub Actions Workflows

This directory contains CI/CD pipeline workflows for DinoAir3.

## Available Workflows

### ci.yml - Main CI Pipeline

**Trigger events:**
- Push to `main` or `develop` branches
- Pull requests to `main` or `develop` branches

**Jobs:**
1. **lint** - Code style and formatting validation
   - Ruff linter check
   - Ruff formatter check
   - Black formatter check
   - Duration: 5-15 minutes

2. **test** - Unit and integration tests
   - pytest with coverage reporting
   - PostgreSQL test database
   - Codecov integration
   - Duration: 15-30 minutes

3. **security** - Security vulnerability scanning
   - Bandit security scan
   - Artifact upload
   - Duration: 5-15 minutes

4. **codacy** - Codacy code quality analysis
   - Coverage report generation
   - Codacy API submission
   - Duration: 10-20 minutes
   - Requires: `CODACY_PROJECT_TOKEN` secret

5. **deepsource** - DeepSource code analysis
   - Python code analysis
   - Secret scanning
   - Duration: 10-20 minutes
   - Requires: `DEEPSOURCE_DSN` secret

6. **build** - Docker image build and push
   - Builds Docker image
   - Pushes to GitHub Container Registry (ghcr.io)
   - Triggers only on main branch after lint/test/security pass
   - Duration: 15-30 minutes
   - Requires: Default `GITHUB_TOKEN`

7. **deploy** - Deployment placeholder
   - Currently a placeholder
   - Add your deployment steps based on your infrastructure
   - Triggers only on main branch after build passes
   - Duration: 5-15 minutes

## Quick Start

### 1. Configure Secrets

See [SECRETS_SETUP.md](./SECRETS_SETUP.md) for detailed instructions.

Quick commands:
```bash
# Using GitHub CLI
gh secret set CODACY_PROJECT_TOKEN --repo Dino-pit-studios-llc/DinoAir3 -b "57bf25909dcf40a7b25b5177de1436e9"
gh secret set DEEPSOURCE_DSN --repo Dino-pit-studios-llc/DinoAir3 -b "dsp_bbee27baf1dfad854b491f14005cdb58939e"

# Using the automated script
chmod +x configure-secrets.sh
./configure-secrets.sh
```

Or manually through GitHub UI:
- Settings > Secrets and variables > Actions > New repository secret

### 2. Push Workflow File

```bash
git add .github/workflows/ci.yml
git commit -m "ci: Add GitHub Actions CI/CD pipeline"
git push origin main
```

### 3. Monitor First Run

1. Go to Actions tab: https://github.com/Dino-pit-studios-llc/DinoAir3/actions
2. Click on the workflow run to see job details
3. Review logs for any failures

## Configuration

### Environment Variables

Edit `ci.yml` to customize:

```yaml
env:
  PYTHON_VERSION: "3.11"        # Change Python version
  REGISTRY: ghcr.io              # Docker registry
```

### Job Conditions

Control when jobs run:
```yaml
if: github.event_name == 'pull_request'  # Only on PRs
if: github.ref == 'refs/heads/main'      # Only on main branch
if: success()                             # Only if previous jobs passed
```

### Timeouts

Each job has a timeout:
```yaml
timeout-minutes: 30  # Kill job if it takes longer
```

Adjust based on your system's performance.

### Dependencies

Jobs that depend on others:
```yaml
needs: [ lint, test, security ]  # This job waits for these to complete
```

This ensures lint/test pass before building Docker image.

## Monitoring & Logs

### GitHub Actions Dashboard

View workflow execution at: https://github.com/Dino-pit-studios-llc/DinoAir3/actions

### Job Logs

Click on a job to see:
- Step-by-step execution
- Console output
- Duration and status
- Environment information

### Artifacts

Some jobs upload artifacts:
- **bandit-report.json** - Security scan results (uploaded by security job)
- **test-results.xml** - JUnit test results (optional)

Access artifacts by:
1. Click workflow run
2. Scroll to "Artifacts" section
3. Download files

### Status Badge

Add workflow status to README.md:

```markdown
[![CI Pipeline](https://github.com/Dino-pit-studios-llc/DinoAir3/actions/workflows/ci.yml/badge.svg)](https://github.com/Dino-pit-studios-llc/DinoAir3/actions/workflows/ci.yml)
```

## Integration with Services

### Codacy

After secrets are configured:
1. Results appear in Codacy dashboard
2. Coverage reports are submitted
3. PR comments are posted with findings

Dashboard: https://app.codacy.com/organizations/github/repositories

### DeepSource

After secrets are configured:
1. Code analysis runs automatically
2. Issues are reported in DeepSource dashboard
3. PR suggestions are posted

Dashboard: https://deepsource.io/

### Codecov

Coverage reports are uploaded automatically:
- Codecov dashboard: https://codecov.io/
- Failing coverage can be configured to fail the build

### GitHub Container Registry

Docker images pushed to: `ghcr.io/dino-pit-studios-llc/dinoair3`

Pull images:
```bash
docker pull ghcr.io/dino-pit-studios-llc/dinoair3:main
docker pull ghcr.io/dino-pit-studios-llc/dinoair3:<git-sha>
```

## Customization Examples

### Add Slack Notifications

Add to `ci.yml`:
```yaml
  - name: Notify Slack on failure
    if: failure()
    uses: slackapi/slack-github-action@v1
    with:
      webhook-url: ${{ secrets.SLACK_WEBHOOK }}
      payload: |
        text: "CI Pipeline failed for ${{ github.repository }}"
```

### Add Branch Protection Rule

Go to Settings > Branches > Add Rule:
1. Apply to: `main` branch
2. Require status checks before merging: Select all workflow jobs
3. Dismiss stale PR approvals: Check
4. Require code reviews: Recommend 1

### Add Pull Request Labels

```yaml
  - name: Label based on test coverage
    if: github.event_name == 'pull_request'
    uses: actions/github-script@v6
    with:
      script: |
        if (coverage > 80) {
          github.rest.issues.addLabels({
            issue_number: context.issue.number,
            owner: context.repo.owner,
            repo: context.repo.repo,
            labels: ['good-coverage']
          })
        }
```

### Run Tests on Schedule

Add to `ci.yml` triggers:
```yaml
on:
  schedule:
    - cron: '0 0 * * *'  # Daily at midnight UTC
```

## Troubleshooting

### Workflow not triggering

1. Verify branch name (must be `main` or `develop`)
2. Check that workflow file is on the correct branch
3. Verify YAML syntax is valid

### Jobs failing

1. Click job in Actions tab
2. Review console output for error messages
3. Common issues:
   - Missing dependencies (pip install)
   - Database connection issues
   - Environment variable not set

### Secrets not working

See [SECRETS_SETUP.md](./SECRETS_SETUP.md) troubleshooting section.

### Docker build failing

1. Verify `Dockerfile.mcp` exists
2. Check file permissions
3. Review build context (current directory: `.`)
4. Check for syntax errors in Dockerfile

### Timeout errors

Increase timeout in `ci.yml`:
```yaml
timeout-minutes: 60  # Was 30
```

## Cost Analysis

### GitHub Actions Free Tier

- **Public repositories**: Unlimited minutes
- **Private repositories**: 2,000 free minutes/month
- **Storage**: 500 MB free

### Current Pipeline Cost

Estimated per run:
- Lint: ~5 min
- Test: ~15 min
- Security: ~5 min
- Codacy: ~10 min
- DeepSource: ~10 min
- Build: ~15 min
- **Total**: ~60 minutes per full run

Monthly estimate (assuming 20 runs):
- Development PRs: 10 × 50 min = 500 min
- Main branch merges: 10 × 60 min = 600 min
- **Total**: ~1,100 min/month (well under free tier)

## References

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Workflow Syntax](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions)
- [Codacy Integration](https://docs.codacy.com/organizations/integrations/)
- [DeepSource Integration](https://deepsource.io/docs/github/)
- [Docker Build Action](https://github.com/docker/build-push-action)

## Support

For issues or questions:
1. Check GitHub Actions logs for specific error messages
2. Review service dashboards (Codacy, DeepSource)
3. Consult service documentation links above
4. Open an issue in the repository
