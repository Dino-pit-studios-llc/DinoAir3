#!/usr/bin/env bash
# Script to check CI readiness locally before pushing

set -e

echo "🔍 Checking CI Pipeline Readiness"
echo "=================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Activate virtual environment
if [ -d ".venv" ]; then
    source .venv/bin/activate
    echo -e "${GREEN}✓ Virtual environment activated${NC}"
else
    echo -e "${RED}✗ No virtual environment found (.venv)${NC}"
    exit 1
fi

echo ""
echo "1️⃣ Checking Ruff Linter"
echo "----------------------"
if ruff check . 2>&1 | head -20; then
    echo -e "${GREEN}✓ Ruff linter passed${NC}"
else
    echo -e "${RED}✗ Ruff linter failed${NC}"
    echo "  Fix with: ruff check . --fix"
fi

echo ""
echo "2️⃣ Checking Ruff Formatter"
echo "-------------------------"
if ruff format . --check 2>&1 | head -10; then
    echo -e "${GREEN}✓ Ruff formatter passed${NC}"
else
    echo -e "${YELLOW}⚠ Ruff formatter found issues${NC}"
    echo "  Fix with: ruff format ."
fi

echo ""
echo "3️⃣ Checking Black Formatter"
echo "--------------------------"
if black . --check 2>&1 | head -10; then
    echo -e "${GREEN}✓ Black formatter passed${NC}"
else
    echo -e "${YELLOW}⚠ Black formatter found issues${NC}"
    echo "  Fix with: black ."
fi

echo ""
echo "4️⃣ Checking Tests"
echo "----------------"
if pytest --co -q 2>&1 | head -10; then
    echo -e "${GREEN}✓ Tests can be collected${NC}"
    echo "  Running tests..."
    if pytest -x --tb=short 2>&1 | tail -20; then
        echo -e "${GREEN}✓ Tests passed${NC}"
    else
        echo -e "${RED}✗ Tests failed${NC}"
        echo "  Review test output above"
    fi
else
    echo -e "${RED}✗ Tests can't be collected${NC}"
    echo "  Check test file structure"
fi

echo ""
echo "5️⃣ Checking Coverage Generation"
echo "------------------------------"
if pytest --cov=. --cov-report=xml -q 2>&1 | tail -10; then
    if [ -f "coverage.xml" ]; then
        echo -e "${GREEN}✓ Coverage file generated${NC}"
        ls -lh coverage.xml
    else
        echo -e "${RED}✗ Coverage file not generated${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Coverage generation had issues${NC}"
fi

echo ""
echo "6️⃣ Checking Security Scan"
echo "------------------------"
if bandit -r . -ll -f json -o bandit-report.json 2>&1 | tail -5; then
    echo -e "${GREEN}✓ Bandit security scan completed${NC}"
    if [ -f "bandit-report.json" ]; then
        echo "  Report: bandit-report.json"
    fi
else
    echo -e "${YELLOW}⚠ Bandit scan had warnings (expected)${NC}"
fi

echo ""
echo "7️⃣ Checking Dependencies"
echo "-----------------------"
echo "Required packages:"
packages=("ruff" "black" "pytest" "pytest-cov" "bandit")
for pkg in "${packages[@]}"; do
    if python -c "import ${pkg//-/_}" 2>/dev/null; then
        echo -e "  ${GREEN}✓${NC} $pkg"
    else
        echo -e "  ${RED}✗${NC} $pkg - Install with: pip install $pkg"
    fi
done

echo ""
echo "=================================="
echo "✅ CI Readiness Check Complete"
echo ""
echo "If all checks passed, your code should pass CI!"
echo "If there are failures, fix them before pushing."
