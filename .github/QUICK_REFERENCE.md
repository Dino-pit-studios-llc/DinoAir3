# Quick Start: CI/CD Pipeline Reference

## 🚀 What Changed?

- **Before**: 3 separate workflows (ci.yml, sonarcloud.yml, Build.yml) with overlapping jobs
- **After**: 1 unified, comprehensive pipeline in ci.yml with 7 optimized jobs

## ⚡ Quick Setup (5 minutes)

### Step 1: Configure SonarCloud Token
```bash
# 1. Visit: https://sonarcloud.io/account/security
# 2. Click: Generate Tokens
# 3. Copy the token
# 4. GitHub: Settings > Secrets and variables > Actions
# 5. New secret: Name = SONAR_TOKEN, Value = <paste-token>
# 6. Done! ✅
```

### Step 2: (Optional) Enable Self-Hosted SonarQube
```bash
# Only do this if you have a SonarQube server
# GitHub Settings > Secrets and variables > Actions > Variables
# Add: SONARQUBE_ENABLED = true
# Add secrets:
#   - SONARQUBE_HOST_URL = http://your-server:9000
#   - SONARQUBE_TOKEN = <your-token>
```

### Step 3: Test It
```bash
# Push a commit to main or create a pull request
# Go to: GitHub Actions tab
# Watch: All jobs run automatically ✨
```

## 📊 Pipeline Stages

```
Code Quality → Testing → Security → SonarCloud → (Optional SonarQube) → Build → Deploy
   (2-3m)      (8-12m)   (3-5m)     (4-6m)                              (10-15m)
```

**Total Time**: 35-50 minutes (jobs run in parallel)

## 🔑 Secrets Needed

| Secret | Required? | Where to Get |
|--------|-----------|--------------|
| `SONAR_TOKEN` | Yes* | SonarCloud → Account → Security |
| `SONARQUBE_HOST_URL` | No | Your SonarQube admin |
| `SONARQUBE_TOKEN` | No | Your SonarQube → My Account → Security |
| `CODECOV_TOKEN` | No | Codecov.io → Settings |
| `GITHUB_TOKEN` | Auto | Provided automatically |

*Yes = Required for SonarCloud analysis  
No = Optional, only if using that feature

## 📋 Jobs in Pipeline

1. **lint** (15 min) - Format checks with Ruff + Black
2. **test** (30 min) - Unit tests with pytest + PostgreSQL
3. **security** (15 min) - Bandit + Semgrep scans
4. **sonarcloud** (20 min) - SonarCloud analysis
5. **sonarqube-selfhosted** (20 min) - Optional self-hosted analysis
6. **build** (30 min) - Docker image build + push to GHCR
7. **deploy** (15 min) - Deployment placeholder

## 🎯 When Do Jobs Run?

| Trigger | Jobs |
|---------|------|
| Pull Request | All except build & deploy |
| Push to main | All jobs (build & deploy on success) |
| Push to develop | All except build & deploy |

## 🛠️ Configuration Files

| File | What It Does |
|------|--------------|
| `.github/workflows/ci.yml` | Main workflow definition |
| `sonar-project.properties` | SonarCloud/SonarQube settings |
| `pyproject.toml` | Ruff, Black, Pytest config |
| `.github/CICD_SETUP_GUIDE.md` | Detailed setup guide |

## ❓ FAQ

**Q: How long does the pipeline take?**  
A: 35-50 minutes total. Jobs run in parallel, so it's not sequential.

**Q: Can I skip security scans?**  
A: Yes, but not recommended. They have `continue-on-error: true` anyway.

**Q: What if SonarCloud token is missing?**  
A: SonarCloud job will skip automatically (no error).

**Q: How do I see the results?**  
A: 
- GitHub: Actions tab in your repo
- SonarCloud: https://sonarcloud.io/ (dashboard)
- SonarQube: http://your-server:9000 (if enabled)

**Q: Can I manually trigger the workflow?**  
A: Yes! GitHub Actions tab → "CI Pipeline" → "Run workflow"

**Q: What databases does it use?**  
A: PostgreSQL 15 (for tests only, runs in container)

**Q: Can I disable the Docker build?**  
A: It only runs on push to `main`, not on PRs.

## 📞 Troubleshooting

### Tests failing in CI but passing locally?
- Check Python version: `python --version` (should be 3.11)
- Check database: Tests use PostgreSQL 15 in CI, maybe SQLite locally
- Run: `DATABASE_URL=sqlite:///test.db pytest`

### SonarCloud not analyzing?
- Verify: `SONAR_TOKEN` secret is set (Settings → Secrets → Actions)
- Check: Job logs for "SonarCloud Scan" step (Actions tab)
- Ensure: `sonar-project.properties` has correct org/key

### Docker build failing?
- Verify: `Dockerfile.mcp` exists in repo root
- Check: All COPY paths are correct
- Try locally: `docker build -f Dockerfile.mcp .`

### SonarQube not running?
- Ensure: `SONARQUBE_ENABLED=true` variable is set
- Verify: Secrets are configured (SONARQUBE_HOST_URL, SONARQUBE_TOKEN)
- Check: SonarQube server is reachable from GitHub Actions

See `.github/CICD_SETUP_GUIDE.md` for more details.

## 📚 Full Documentation

See **`.github/CICD_SETUP_GUIDE.md`** for:
- Step-by-step setup instructions
- Detailed job descriptions
- Troubleshooting section
- Best practices
- Maintenance schedule

## 💬 Key Commands (For Your Reference)

```bash
# Run tests locally before pushing
pytest --cov

# Check formatting
ruff check . && black --check .

# Run security scans
bandit -r . -ll -f json -o bandit-report.json

# Build Docker image
docker build -f Dockerfile.mcp -t dinoair:latest .

# View workflow status
# GitHub: Settings > Actions > "CI Pipeline"
```

## 🎉 You're All Set!

1. ✅ Added SonarCloud token
2. ✅ (Optional) Added SonarQube config
3. ✅ Committed code
4. ✅ Watch Actions tab

**Pipeline is live and ready to roll! 🚀**

---

**Questions?** See `.github/CICD_SETUP_GUIDE.md` or create a GitHub Issue.
