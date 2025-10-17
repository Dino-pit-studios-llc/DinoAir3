# Archived Tools

This directory contains scanning, analysis, and utility tools that have been archived to reduce clutter in the main `tools/` directory. These tools are kept for reference but are not actively maintained.

## Archived Content

### Security & Vulnerability Scanning (`security/`)

The following tools were moved from `tools/security/` and are archived here:

- **vulnerability_scanner.py** - DinoAir-specific vulnerability scanner (custom OWASP testing)
- **github_security_loader.py** - GitHub security API client for loading security issues
- **simple_github_security.py** - Simplified GitHub security data loader
- **github_security_diagnostic.py** - GitHub security feature diagnostic tool
- **security_summary.py** - Security issues summary analyzer
- **live_security_assessment.py** - Live security assessment tool
- **security_validation.py** - Security validation utilities
- **setup_github_security.py** - GitHub security setup helper
- **setup_small_team_security.py** - Small team security configuration
- **security_issues_list.py** - Security issues listing utility

### Analysis & Inspection Tools

- **import_time_budget_estimator.py** - Import performance analysis tool
- **setup_deepsource_coverage.py** - DeepSource coverage configuration setup
- **setup_deepsource_simple.py** - Simplified DeepSource setup

## Active Code Analysis Tools

The following code analysis and security tools are **actively maintained and NOT archived**:

### Primary Code Analysis
- **CodeQL** - Static analysis via GitHub Actions (configured in CI/CD)
- **DeepSource** - Code quality and security analysis (`.deepsource.toml` in root)
- **Codacy** - Code quality metrics (`.codacy.yml` equivalent in CI config)

### CI/CD Integration
Code analysis is primarily configured in:
- `.gitlab-ci.yml` or GitHub Actions workflows (SAST, Dependency Scanning, Secret Detection)
- `.deepsource.toml` for DeepSource configuration
- `.codacy.yml` (if using Codacy)

## Why These Tools Were Archived

1. **Redundancy** - Primary code analysis is handled by CodeQL, DeepSource, and Codacy
2. **Maintenance Burden** - Custom security scanners require ongoing updates as vulnerabilities evolve
3. **False Positives** - Custom scanners often produce low-signal results compared to industry-standard tools
4. **Cloud Solutions** - GitHub, DeepSource, and Codacy provide managed solutions with expert maintenance

## If You Need These Tools

To use any archived tool:

```bash
# Copy the tool back to tools/ directory
cp -r archived_tools/security tools/

# Or run directly from archived_tools/
python archived_tools/security/vulnerability_scanner.py
```

## Recommended Approach

For security and code quality:

1. **Use GitHub Actions** with CodeQL for static analysis
2. **Configure DeepSource** for continuous code quality monitoring
3. **Use Codacy** for metrics and quality gates
4. **Run `pre-commit`** hooks locally for formatting and linting
5. **Execute `pytest`** with coverage for unit testing

This combination provides comprehensive coverage without maintenance overhead.

## Related Files

- `.deepsource.toml` - DeepSource configuration (root)
- `comp_ci.yml` - GitLab CI configuration with SAST/Dependency scanning
- `.pre-commit-config.yaml` - Pre-commit hooks configuration
- `pytest.ini` - Pytest configuration
- `pyproject.toml` - Ruff and testing configuration
