# GitHub Secrets Configuration Guide

This guide provides step-by-step instructions for configuring GitHub secrets for the DinoAir3 CI/CD pipeline.

## Method 1: Using GitHub Web UI (Easiest)

### Step 1: Access Repository Settings
1. Go to your GitHub repository: https://github.com/Dino-pit-studios-llc/DinoAir3
2. Click **Settings** tab (top right)
3. In the left sidebar, click **Secrets and variables** > **Actions**

### Step 2: Add CODACY_PROJECT_TOKEN

1. Click **New repository secret** button
2. Enter the secret name: `CODACY_PROJECT_TOKEN`
3. **Get your actual token from Codacy:**
   - Log in to [Codacy](https://app.codacy.com)
   - Navigate to your DinoAir3 project
   - Go to **Settings → Coverage → Project API token**
   - Copy your project token
4. Enter the secret value with your actual token (NOT the placeholder):
   ```
   YOUR_ACTUAL_CODACY_TOKEN_HERE
   ```
   ⚠️ **Note:** The value `57bf25909dcf40a7b25b5177de1436e9` is a PLACEHOLDER example. You must use your actual Codacy token.
5. Click **Add secret**

### Step 3: Add DEEPSOURCE_DSN

1. Click **New repository secret** button
2. Enter the secret name: `DEEPSOURCE_DSN`
3. **Get your actual DSN from DeepSource:**
   - Log in to [DeepSource](https://deepsource.io)
   - Navigate to your DinoAir3 repository
   - Go to **Settings → Code Coverage**
   - Copy your repository DSN (starts with `dsp_`)
4. Enter the secret value with your actual DSN (NOT the placeholder):
   ```
   YOUR_ACTUAL_DEEPSOURCE_DSN_HERE
   ```
   ⚠️ **Note:** The value `dsp_bbee27baf1dfad854b491f14005cdb58939e` is a PLACEHOLDER example. You must use your actual DeepSource DSN.
5. Click **Add secret**

### Verification

You should now see both secrets listed on the Secrets page (values will be masked).

## Method 2: Using GitHub CLI

If you have the GitHub CLI installed, you can use the automated script:

```bash
# Navigate to repository directory
cd /home/kevin/Documents/DinoAir3

# Make the script executable
chmod +x .github/configure-secrets.sh

# Run the script
.github/configure-secrets.sh
```

The script will:
- Check that GitHub CLI is installed and authenticated
- Add both secrets to your repository
- Verify successful configuration

## Method 3: Manual GitHub CLI Commands

If you prefer to run commands manually:

```bash
# Authenticate with GitHub (if not already done)
gh auth login

# Set CODACY_PROJECT_TOKEN
# ⚠️ Replace YOUR_ACTUAL_CODACY_TOKEN_HERE with your real token from Codacy dashboard
gh secret set CODACY_PROJECT_TOKEN \
  --repo Dino-pit-studios-llc/DinoAir3 \
  --body "YOUR_ACTUAL_CODACY_TOKEN_HERE"

# Set DEEPSOURCE_DSN
# ⚠️ Replace YOUR_ACTUAL_DEEPSOURCE_DSN_HERE with your real DSN from DeepSource dashboard
gh secret set DEEPSOURCE_DSN \
  --repo Dino-pit-studios-llc/DinoAir3 \
  --body "YOUR_ACTUAL_DEEPSOURCE_DSN_HERE"

# Verify secrets were added
gh secret list --repo Dino-pit-studios-llc/DinoAir3
```

## Verifying Secrets Are Configured

After adding secrets, verify they're accessible in the Actions workflow:

1. Go to **Actions** tab in your repository
2. Look for any workflow runs
3. If you see "Secrets loaded" in the logs, secrets are configured correctly

## Security Notes

⚠️ **Important Security Considerations:**

1. **Never commit secrets to repository** - GitHub Secrets are never exposed in logs or artifacts
2. **Rotate tokens periodically** - Consider rotating Codacy and DeepSource tokens every 90 days
3. **Limit scope** - These tokens should only have necessary permissions
4. **Monitor usage** - Check Codacy and DeepSource dashboards for suspicious activity

## Troubleshooting

### Secrets not showing in Actions logs
- This is normal and expected - secrets are always masked in logs
- Check the Actions workflow logs for environment variable usage

### Workflow fails with "undefined secret"
- Verify secret names match exactly (case-sensitive):
  - `CODACY_PROJECT_TOKEN` (uppercase)
  - `DEEPSOURCE_DSN` (uppercase)
- Ensure secrets are added to the correct repository

### Token rejected by Codacy/DeepSource
- Log in to Codacy/DeepSource dashboard
- Verify the token is valid and not expired
- Check that the project is registered in their systems
- Generate a new token if the old one is compromised

### Workflow triggers but secrets not used
- Check that the workflow file references the correct secret names
- Format in workflow: `${{ secrets.CODACY_PROJECT_TOKEN }}`
- Wait for workflow to complete - secrets are loaded at runtime

## Next Steps

1. ✅ Configure secrets using one of the methods above
2. Push the `.github/workflows/ci.yml` file:
   ```bash
   git add .github/workflows/ci.yml .github/CI_CD_SETUP.md .github/configure-secrets.sh
   git commit -m "ci: Add GitHub Actions CI/CD pipeline with Codacy and DeepSource integration"
   git push origin main
   ```
3. Monitor first workflow run in **Actions** tab
4. Review Codacy and DeepSource dashboards for results
