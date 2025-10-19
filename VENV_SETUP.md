# Virtual Environment Setup Guide

## 🎯 Automatic Activation

Your VS Code workspace is now configured to **automatically activate** the Python virtual environment when you open a new terminal!

## 🔒 Global Pip Protection

**NEW:** Global pip installations are now **DISABLED** system-wide! You must have an active virtual environment to install packages. This prevents accidental global installations. See `GLOBAL_PIP_PROTECTION.md` for details.

### What Was Configured

1. **VS Code Settings** (`.vscode/settings.json`):
   - Default Python interpreter set to `.venv/Scripts/python.exe`
   - Terminal auto-activation enabled
   - Custom PowerShell profile that activates venv on startup

2. **Global Pip Protection** (`C:\Users\kevin\AppData\Roaming\pip\pip.ini`):
   - Requires active virtual environment for pip install/uninstall
   - Prevents accidental global package installations
   - Encourages best practices with isolated environments

3. **Helper Scripts Created**:
   - `activate_venv.ps1` - Convenient activation script with status info
   - `check_dependencies.py` - Checks for conflicts between global and venv packages

## ✅ Verification

Your venv is **properly isolated** with no dependency conflicts:
- ✅ All critical packages installed in venv
- ✅ No version mismatches between global and venv
- ✅ 31 packages in venv vs 87 global (isolation working correctly)

## 🚀 Usage

### Automatic (Recommended)
Just open a new terminal in VS Code - the venv will activate automatically!

### Manual Activation
If needed, you can manually activate:

**PowerShell (Recommended):**
```powershell
.\activate_venv.ps1
```

**Standard Activation:**
```powershell
.\.venv\Scripts\Activate.ps1
```

**CMD:**
```cmd
.venv\Scripts\activate.bat
```

### Installing Packages

**ALWAYS use the venv Python:**
```powershell
# Good - installs in venv
.venv\Scripts\python.exe -m pip install <package>

# Bad - installs globally
pip install <package>
```

### Check for Conflicts

Run the dependency checker anytime:
```powershell
.venv\Scripts\python.exe check_dependencies.py
```

## 🎨 Terminal Indicator

When the venv is active, you'll see `(.venv)` at the start of your prompt:
```
(.venv) PS C:\Users\kevin\DinoAir3>
```

## 🔧 Troubleshooting

### Venv Not Activating?

1. **Close and reopen VS Code** - Settings changes require restart
2. **Check execution policy:**
   ```powershell
   Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
   ```
3. **Manually activate once:**
   ```powershell
   .\activate_venv.ps1
   ```

### Wrong Python Being Used?

Check which Python is active:
```powershell
Get-Command python | Select-Object Source
```

Should show: `C:\Users\kevin\DinoAir3\.venv\Scripts\python.exe`

If not, run:
```powershell
.\activate_venv.ps1
```

### Package Not Found?

Make sure it's installed in the venv, not globally:
```powershell
.venv\Scripts\python.exe -m pip list | Select-String "<package>"
```

## 📦 Current Critical Packages (in venv)

| Package   | Version | Status |
|-----------|---------|--------|
| aiofiles  | 25.1.0  | ✅     |
| anyio     | 4.11.0  | ✅     |
| coverage  | 7.11.0  | ✅     |
| fastapi   | 0.119.0 | ✅     |
| httpx     | 0.28.1  | ✅     |
| pydantic  | 2.12.3  | ✅     |
| pytest    | 8.4.2   | ✅     |
| ruff      | 0.14.1  | ✅     |
| starlette | 0.48.0  | ✅     |

## 🎓 Best Practices

1. ✅ **Always activate venv** before working on the project
2. ✅ **Use venv Python** for all pip installs
3. ✅ **Never install project dependencies globally**
4. ✅ **Run `check_dependencies.py` regularly** to catch issues early
5. ✅ **Keep requirements.txt updated** when adding packages

## 📝 Adding New Dependencies

1. Activate venv (should be automatic)
2. Install package:
   ```powershell
   python -m pip install <package>
   ```
3. Update requirements:
   ```powershell
   python -m pip freeze > requirements.txt
   ```
4. Check for conflicts:
   ```powershell
   python check_dependencies.py
   ```

## 🔄 Recreating Venv

If you need to start fresh:

```powershell
# Remove old venv
Remove-Item -Recurse -Force .venv

# Create new venv
python -m venv .venv

# Activate
.\activate_venv.ps1

# Reinstall dependencies
python -m pip install -r requirements.txt
python -m pip install -r API/requirements-dev.txt
```

## 🆘 Need Help?

Run the dependency checker for diagnostics:
```powershell
.venv\Scripts\python.exe check_dependencies.py
```

This will show:
- Version conflicts
- Missing critical packages
- Packages in wrong location
- Recommendations for fixing issues
