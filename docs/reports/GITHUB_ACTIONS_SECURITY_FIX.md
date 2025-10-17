# GitHub Actions Security Fix - Third-Party Action Pinning

**Date:** October 15, 2025  
**Security Issue:** Third-party GitHub Actions not pinned to commit SHA  
**Severity:** Medium  
**Status:** ✅ RESOLVED

## Summary

Fixed security vulnerability where the SonarCloud GitHub Action was referenced using a branch name (`@master`) instead of being pinned to a specific commit SHA. This change follows GitHub's security best practices for using third-party actions.

## Security Risk

**Before Fix:**

```yaml
uses: SonarSource/sonarcloud-github-action@master
```

**Risk:** Using a branch reference like `@master` means the action can change at any time, potentially introducing:

- Malicious code if the upstream repository is compromised
- Breaking changes without notice
- Supply chain attacks via dependency injection

## Fix Applied

**After Fix:**

```yaml
uses: SonarSource/sonarcloud-github-action@ba3875ecf642b2129de2b589510c81a8b53dbf4e # master as of 2025-10-15
```

**File Changed:** `.github/workflows/build.yml` (line 38)

**Commit SHA:** `ba3875ecf642b2129de2b589510c81a8b53dbf4e` (master branch as of October 15, 2025)

## Security Benefits

✅ **Immutable Release:** Action version cannot change unexpectedly  
✅ **Supply Chain Protection:** Prevents backdoor injection via repository compromise  
✅ **Audit Trail:** Specific commit hash provides clear version tracking  
✅ **Best Practice Compliance:** Follows GitHub's security hardening guidelines

## Verification

- ✅ YAML syntax validated successfully
- ✅ CodeQL security scan passed (0 alerts)
- ✅ No other third-party actions requiring fixes found
- ✅ All GitHub official actions (`actions/*`) remain on version tags (acceptable practice)

## Actions Inventory

| Action                                 | Type        | Reference         | Status   |
| -------------------------------------- | ----------- | ----------------- | -------- |
| `actions/checkout@v4`                  | First-party | Tag               | ✅ OK    |
| `actions/setup-python@v4`              | First-party | Tag               | ✅ OK    |
| `actions/setup-python@v5`              | First-party | Tag               | ✅ OK    |
| `actions/cache@v4`                     | First-party | Tag               | ✅ OK    |
| `SonarSource/sonarcloud-github-action` | Third-party | SHA (was: master) | ✅ FIXED |

## Maintenance Notes

### Updating the Pinned Action

When updating the SonarCloud action in the future:

1. Check the latest commit on the master branch:

   ```bash
   git ls-remote https://github.com/SonarSource/sonarcloud-github-action.git master
   ```

2. Update the workflow with the new commit SHA:

   ```yaml
   uses: SonarSource/sonarcloud-github-action@<new-commit-sha> # master as of YYYY-MM-DD
   ```

3. Include the date in the comment for tracking purposes

### Why First-Party Actions Don't Need SHA Pinning

GitHub official actions (`actions/*`) are maintained by GitHub and have:

- Strong security controls
- Transparent update processes
- Version tags that are immutable
- Lower risk of compromise

Therefore, using version tags (e.g., `@v4`) for first-party actions is considered acceptable practice.

## References

- [GitHub Actions Security Hardening Guide](https://docs.github.com/en/actions/security-guides/security-hardening-for-github-actions#using-third-party-actions)
- [SonarCloud GitHub Action Repository](https://github.com/SonarSource/sonarcloud-github-action)
- Original Issue: security (yaml.github-actions.security.third-party-action-not-pinned-to-commit-sha)

---

**Resolution Date:** October 15, 2025  
**Branch:** copilot/fix-pinning-third-party-action  
**Commit:** 1fe3b48
