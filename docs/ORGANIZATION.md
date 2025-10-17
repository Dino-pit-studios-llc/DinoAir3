# Repository Organization

## Recent Cleanup (October 15, 2025)

This document describes the organization of the DinoAir3 repository after cleanup.

### Directory Structure

#### `/docs/`

Main documentation folder containing:

- **`/docs/reports/`** - Analysis reports, CI/CD documentation, and task summaries
  - Code health reports
  - Security analysis summaries
  - SonarCloud setup and fix documentation
  - GitHub Actions related documentation
  - Issue resolution reports

#### `/scripts/`

Utility and setup scripts:

- **`/scripts/qdrant/`** - Qdrant MCP server setup and demo files
  - MCP server implementation
  - Setup and population scripts
  - Demo files
  - Configuration files
  - README with Qdrant-specific documentation
- Verification and scanning scripts

#### Root Directory

Configuration files only:

- `.coverage` - Test coverage data
- `.deepsource.toml` - DeepSource configuration
- `.env*` - Environment files
- `.gitattributes`, `.gitignore` - Git configuration
- `.pre-commit-config.yaml` - Pre-commit hooks
- `docker-compose.yml` - Docker composition
- `Dockerfile.mcp` - MCP server Docker image
- `sonar-project.properties` - SonarCloud configuration

### Files Moved

#### To `/docs/reports/`:

- CI_WORKFLOW_ENHANCEMENTS.md
- CODE_HEALTH_ANALYSIS_REPORT.md
- CODE_HEALTH_FIXES_MEDIUM.md
- CODE_HEALTH_RESOLUTION.md
- CODE_REVIEW_UPDATES_SUMMARY.md
- CODE_SYNTAX_FIXES_REPORT.md
- FINAL_SECURITY_SUMMARY.md
- GITHUB_ACTIONS_PERMISSIONS_UPDATE.md
- GITHUB_ACTIONS_SECURITY_FIX.md
- HIGH_ISSUES_RESOLUTION_REPORT.md
- ISSUE_RESOLUTION_SUMMARY.md
- LOW_ISSUES_RESOLUTION_REPORT.md
- README_CODE_HEALTH.md
- README_HIGH_ISSUES.md
- SONARCLOUD_ACTION_VERIFICATION.md
- SONARCLOUD_DOCUMENTATION_FIX.md
- SONARCLOUD_FIX_SUMMARY.md
- SONARCLOUD_IDENTIFIERS_FIX.md
- SONAR_HOST_URL_VERIFICATION.md
- SYNTAX_ERRORS_RESOLUTION.md
- TASK_COMPLETION_SUMMARY.md
- TASK_SUMMARY_CI_ENHANCEMENT.md

#### To `/scripts/qdrant/`:

- demo_qdrant_mcp.py
- mcp_qdrant_requirements.txt
- mcp_qdrant_server.py
- populate_qdrant_collections.py
- qdrant_mcp_config.yaml
- QDRANT_MCP_README.md → README.md
- run_qdrant_mcp_demo.py
- setup_and_populate_qdrant.py
- setup_qdrant_alternatives.py
- setup_qdrant_mcp.py
- simple_qdrant_demo.py
- start_qdrant_mcp.sh
- start_qdrant_server.py

#### To `/scripts/`:

- scan_unreachable_except.py
- verify_high_issues_resolved.py
- verify_syntax_fixes.py

## Maintenance

Keep the root directory clean by:

1. Moving documentation to `/docs/` or `/docs/reports/`
2. Moving scripts to appropriate `/scripts/` subdirectories
3. Keeping only essential configuration files in root
