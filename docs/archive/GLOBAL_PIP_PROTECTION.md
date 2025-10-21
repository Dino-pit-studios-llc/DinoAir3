# Moved from repository root on 2025-10-21

This document was relocated from the repository root to keep the root clean. The original file name was `GLOBAL_PIP_PROTECTION.md`.

---

# Global Pip Protection Setup

## 🔒 What Was Configured

Your system is now configured to **prevent accidental global pip installations** and require an active virtual environment.

### Configuration File Created

**Location**: `C:\Users\kevin\AppData\Roaming\pip\pip.ini`

**Content**:
```ini
[global]
require-virtualenv = true

[install]
prefer-binary = true
```

## ✅ How It Works

### Before This Setup
```powershell
# This would install globally (dangerous!)
pip install requests
```

### After This Setup
```powershell
# Without venv active - BLOCKED ❌
pip install requests
# ERROR: Could not find an activated virtualenv (required).

# With venv active - ALLOWED ✅
.\activate_venv.ps1
pip install requests
# Works fine!
```

## 🎯 Benefits

1. ✅ **Prevents accidental global installs** - No more polluting global Python
2. ✅ **Forces best practices** - Must use virtual environments
3. ✅ **Protects system Python** - Global packages stay clean
4. ✅ **Encourages isolation** - Each project uses its own venv
5. ✅ **IDE-friendly** - VS Code auto-activates venv, so pip "just works"

## 🛠 Usage

### Normal Usage (Recommended)
With venv auto-activation in VS Code, you don't need to do anything special:

```powershell
# Open terminal in VS Code (venv auto-activates)
(.venv) PS> pip install <package>
# Works! ✅
```

### Manual Activation
If you're outside VS Code:

```powershell
# Activate venv first
.\activate_venv.ps1

# Then install
pip install <package>
```

### Bypass Protection (Emergency Only)
If you absolutely must install globally (not recommended):

**Option 1: Temporary bypass with environment variable**
```powershell
$env:PIP_REQUIRE_VIRTUALENV = "false"
pip install <package>
$env:PIP_REQUIRE_VIRTUALENV = $null  # Reset after
```

**Option 2: Use --isolated flag**
```powershell
python -m pip install --isolated <package>
```

**Option 3: Temporarily rename the config**
```powershell
Rename-Item "$env:APPDATA\pip\pip.ini" "$env:APPDATA\pip\pip.ini.disabled"
pip install <package>
Rename-Item "$env:APPDATA\pip\pip.ini.disabled" "$env:APPDATA\pip\pip.ini"
```

## 🧪 Testing

### Test 1: Global Install Blocked
```powershell
# Deactivate venv
deactivate

# Try to install globally
pip install requests

# Expected result:
# ERROR: Could not find an activated virtualenv (required).
```

### Test 2: Venv Install Works
```powershell
# Activate venv
.\activate_venv.ps1

# Install in venv
pip install requests

# Expected result:
# Successfully installed requests-x.x.x
```

### Test 3: Verify Configuration
```powershell
# Show pip configuration
pip config list

# Expected output:
# global.require-virtualenv='true'
# install.prefer-binary='true'
```

## 📎 Configuration Details

### File Location (Windows)
```
C:\Users\<username>\AppData\Roaming\pip\pip.ini
```

### File Location (Linux/Mac)
```
~/.config/pip/pip.conf
```

### Settings Explained

**`require-virtualenv = true`**
- Blocks pip install/uninstall outside virtual environments
- Does NOT affect pip list, pip show, pip freeze, etc.
- Only affects install/uninstall operations

**`prefer-binary = true`**
- Downloads pre-compiled binary packages when available
- Faster installs (no compilation needed)
- More reliable on Windows

## 🔄 Integration with VS Code

Your VS Code setup automatically:
1. ✅ Activates venv when terminal opens
2. ✅ Sets correct Python interpreter
3. ✅ Shows `(.venv)` indicator in prompt
4. ✅ pip works seamlessly because venv is active

**Result**: You can use `pip install` normally in VS Code terminals!

## 🧰 Troubleshooting

### Error: "Could not find an activated virtualenv"

**Problem**: Trying to pip install outside venv

**Solutions**:
1. Activate venv: `.\activate_venv.ps1`
2. Use VS Code terminal (auto-activates)
3. Check venv status: `$env:VIRTUAL_ENV`

### Error: pip commands slow or hanging

**Problem**: Network or pip cache issues

**Solutions**:
```powershell
# Clear pip cache
pip cache purge

# Use a mirror
pip install --index-url https://pypi.org/simple <package>
```

### Want to disable protection temporarily

**Quick disable**:
```powershell
$env:PIP_REQUIRE_VIRTUALENV = "false"
# ... do your installs ...
$env:PIP_REQUIRE_VIRTUALENV = $null
```

**Permanent disable** (not recommended):
```powershell
Remove-Item "$env:APPDATA\\pip\\pip.ini"
```

### Want different settings per project

You can create project-specific pip.conf:
```powershell
# Create local config
New-Item -ItemType File -Path "pip.conf"

# Add settings
@"
[install]
no-cache-dir = true
"@ | Out-File pip.conf

# Use with --config flag
pip install --config pip.conf <package>
```

## 📊 Impact Summary

### Before
- ❌ Easy to accidentally install globally
- ❌ Global Python polluted with project dependencies
- ❌ Version conflicts between projects
- ❌ Hard to clean up global packages

### After
- ✅ **Impossible** to install globally by accident
- ✅ Global Python stays clean
- ✅ Each project isolated
- ✅ Clear error message if you forget venv
- ✅ Works seamlessly with VS Code auto-activation

## 🎓 Best Practices

1. ✅ **Use VS Code terminals** - venv auto-activates
2. ✅ **Check for `(.venv)` prefix** before pip install
3. ✅ **Never bypass protection** unless absolutely necessary
4. ✅ **Keep venv updated**: `python -m pip install --upgrade pip`
5. ✅ **Document dependencies**: `pip freeze > requirements.txt`

## 🔗 Related Files

- **VS Code Settings**: `.vscode/settings.json` (auto-activation)
- **Activation Script**: `activate_venv.ps1` (manual activation)
- **Dependency Checker**: `check_dependencies.py` (verify isolation)
- **Setup Guide**: `VENV_SETUP.md` (complete documentation)

## ✨ Summary

Global pip installations are now **blocked by default**. You must have an active virtual environment to install packages.

With VS Code's auto-activation, this is transparent - pip "just works" because the venv is always active in VS Code terminals!

**Status**: 🔒 **Global pip installs DISABLED** - System protected!
