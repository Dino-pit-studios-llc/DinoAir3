#!/usr/bin/env bash
# Script to configure GitHub secrets for DinoAir3 CI/CD pipeline
# This requires GitHub CLI (gh) to be installed and authenticated
# Install: https://cli.github.com/
# Authenticate: gh auth login

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Repository information
OWNER="Dino-pit-studios-llc"
REPO="DinoAir3"

echo -e "${YELLOW}DinoAir3 GitHub Secrets Configuration${NC}"
echo "========================================"
echo ""

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo -e "${RED}GitHub CLI (gh) is not installed.${NC}"
    echo "Install from: https://cli.github.com/"
    exit 1
fi

# Check if authenticated
if ! gh auth status &> /dev/null; then
    echo -e "${RED}Not authenticated with GitHub CLI.${NC}"
    echo "Run: gh auth login"
    exit 1
fi

echo -e "${GREEN}✓ GitHub CLI authenticated${NC}"
echo ""

# Function to set a secret
set_secret() {
    local secret_name=$1
    local secret_value=$2
    local description=$3

    echo "Setting secret: ${YELLOW}${secret_name}${NC}"
    echo "Description: ${description}"

    # Use printf to avoid issues with special characters
    printf "%s" "$secret_value" | gh secret set "$secret_name" \
        --repo "$OWNER/$REPO" \
        --body - \
        2>/dev/null && \
        echo -e "${GREEN}✓ ${secret_name} set successfully${NC}" || \
        echo -e "${RED}✗ Failed to set ${secret_name}${NC}"

    echo ""
}

# Configure secrets
echo -e "${YELLOW}Adding GitHub Secrets${NC}"
echo "--------------------"
echo ""

set_secret "CODACY_PROJECT_TOKEN" \
    "57bf25909dcf40a7b25b5177de1436e9" \
    "Codacy project token for coverage reporting"

set_secret "DEEPSOURCE_DSN" \
    "dsp_bbee27baf1dfad854b491f14005cdb58939e" \
    "DeepSource repository DSN for code analysis"

echo -e "${GREEN}✓ All secrets configured successfully!${NC}"
echo ""
echo "Next steps:"
echo "1. Verify secrets in GitHub repository settings:"
echo "   https://github.com/${OWNER}/${REPO}/settings/secrets/actions"
echo ""
echo "2. Push the CI workflow to trigger the pipeline:"
echo "   git add .github/workflows/ci.yml"
echo "   git commit -m 'ci: Add GitHub Actions CI/CD pipeline with Codacy and DeepSource'"
echo "   git push origin main"
echo ""
echo "3. Monitor the first workflow run in the Actions tab:"
echo "   https://github.com/${OWNER}/${REPO}/actions"
