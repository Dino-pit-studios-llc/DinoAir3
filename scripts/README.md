#!/usr/bin/env python3
"""
README for Automation Scripts

This directory contains automation scripts for fixing code quality issues.
All scripts include validation to ensure files remain syntactically correct.

## Available Scripts

### 1. fix_powershell_writehost.py

Fixes 1000+ PowerShell Write-Host usage issues.

**What it does:**

- Replaces `Write-Host` with appropriate cmdlets:
  - `Write-Error` for error messages (red color)
  - `Write-Warning` for warnings (yellow/orange)
  - `Write-Output` for general output
- Validates PowerShell syntax before and after changes
- Creates backups automatically

**Usage:**

```powershell
# Dry run (see what would change)
python scripts/fix_powershell_writehost.py --dry-run

# Fix all PowerShell files
python scripts/fix_powershell_writehost.py

# Fix single file
python scripts/fix_powershell_writehost.py --file path/to/script.ps1
```

**Expected Impact:** Fixes ~1000 low-priority issues

---

### 2. fix_naming_conventions.py

Fixes Python naming convention issues (PascalCase/camelCase to snake_case).

**What it does:**

- Renames PascalCase fields to snake_case (AppState → app_state)
- Renames camelCase methods to snake_case (setSingleShot → set_single_shot)
- Renames camelCase parameters to snake_case (singleShot → single_shot)
- Validates Python syntax before and after changes
- Creates backups automatically

**Usage:**

```bash
# Dry run
python scripts/fix_naming_conventions.py --dry-run

# Fix all Python files
python scripts/fix_naming_conventions.py

# Fix single file
python scripts/fix_naming_conventions.py --file path/to/file.py
```

**Expected Impact:** Fixes ~82 low-priority issues

---

## Safety Features

All scripts include:

✅ **Syntax Validation**

- Validates original file before changes
- Validates fixed file after changes
- Skips files with syntax errors
- Rolls back if validation fails

✅ **Automatic Backups**

- Creates .bak files before modifying
- Easy to restore if needed

✅ **Dry Run Mode**

- See exactly what would change
- No files modified
- Safe to test

✅ **Detailed Reporting**

- Shows each change made
- Summary statistics
- Error reporting with file paths

---

## Recommended Workflow

### Step 1: Dry Run First

Always test with `--dry-run` to see what would change:

```bash
python scripts/fix_powershell_writehost.py --dry-run
python scripts/fix_naming_conventions.py --dry-run
```

### Step 2: Test on Single File

Pick a non-critical file and test:

```bash
python scripts/fix_powershell_writehost.py --file activate-env.ps1
# Review the changes
# If good, proceed to full run
```

### Step 3: Run Full Automation

```bash
# Fix all PowerShell issues
python scripts/fix_powershell_writehost.py

# Fix naming conventions
python scripts/fix_naming_conventions.py
```

### Step 4: Verify Changes

```bash
# Run tests
pytest

# Run Codacy analysis
# (Per instructions: analyze each modified file)

# If issues found, restore from backups:
# Get-ChildItem -Recurse -Filter "*.bak" | ForEach-Object {
#     Copy-Item $_.FullName ($_.FullName -replace '\.bak$','') -Force
# }
```

---

## Expected Results

| Script                      | Issues Fixed | Time        | Risk    |
| --------------------------- | ------------ | ----------- | ------- |
| fix_powershell_writehost.py | ~1000        | 2-5 min     | Low     |
| fix_naming_conventions.py   | ~82          | 1-2 min     | Low     |
| **TOTAL**                   | **~1082**    | **3-7 min** | **Low** |

This automated approach fixes 78.7% of all issues (1082 out of 1374)!

---

## Troubleshooting

### Script fails with "PowerShell not found"

**Solution:** Ensure `pwsh` is in your PATH. Install PowerShell 7+ if needed.

### "Syntax error" in original file

**Solution:** The script will skip files with existing syntax errors. Fix those manually first.

### "Validation failed" after changes

**Solution:** The script will not apply changes. Backups are preserved. File an issue with details.

### Too many changes at once

**Solution:** Use `--file` option to process files one at a time.

---

## Next Steps After Automation

After running these scripts, proceed to manual fixes:

1. **Phase 1: Critical Issues** (10 issues, ~4 hours)
   - Fix 3 critical bugs
   - Fix 7 bug risks

2. **Phase 2: High Priority** (155 issues, ~55-75 hours)
   - Fix 2 security vulnerabilities (URGENT!)
   - Reduce cognitive complexity (70+ functions)
   - Extract string constants (40+ duplicates)

3. **Phase 3: Medium Priority** (127 issues, ~19-27 hours)
   - Fix 18 bugs
   - Resolve 109 code smells

---

## Support

For issues or questions:

1. Check script output for error messages
2. Review the backup files (\*.bak)
3. Refer to ISSUE_RESOLUTION_PLAN.md for details
4. Test with --dry-run first

**Remember:** Always commit your changes to git before running automation scripts!
