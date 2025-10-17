# Flutter Development Quick Start for DinoAir3

## Environment Setup

The Flutter CLI requires Git and proper PATH configuration. Use one of these methods:

### Option 1: Quick Setup (Current Session Only)

```powershell
cd c:\src\Repositories\DinoAir3\user_interface\User_Interface
. .\setup-env.ps1
flutter run -d windows
```

### Option 2: Manual PATH Setup (Current Session)

```powershell
$env:PATH = "C:\Windows\System32;C:\Program Files\Git\bin;C:\src\Repositories\flutter\flutter\bin;$env:PATH"
cd c:\src\Repositories\DinoAir3\user_interface\User_Interface
flutter run -d windows
```

### Option 3: Add to System PATH (Permanent - Requires Admin)

Run this in an **Administrator PowerShell**:

```powershell
[Environment]::SetEnvironmentVariable("Path",
    $env:Path + ";C:\Program Files\Git\bin;C:\src\Repositories\flutter\flutter\bin",
    [EnvironmentVariableTarget]::User)
```

Then restart your terminal and run:

```powershell
flutter run -d windows
```

## Common Commands

Once the environment is set up:

```powershell
# Run the app on Windows
flutter run -d windows

# Run with hot reload enabled (recommended)
flutter run -d windows --hot

# Check Flutter environment
flutter doctor -v

# Get dependencies
flutter pub get

# Analyze code
flutter analyze

# Run tests
flutter test
```

## Troubleshooting

### "Unable to find git in your PATH"

- Verify git is installed: `Test-Path "C:\Program Files\Git\bin\git.exe"`
- Run `setup-env.ps1` from the User_Interface directory
- Or add Git to your system PATH permanently (Option 3)

### App won't build

- Run `flutter clean` then `flutter pub get`
- Check `flutter doctor -v` for any missing dependencies

### Notes feature shows placeholder

- The notes feature has domain/data layers implemented
- The presentation layer (UI) is not yet built
- This is expected behavior, not a bug

## Project Status

- ✅ Backend API with Pydantic v2
- ✅ Flutter project structure with clean architecture
- ✅ Notes domain/data layers complete
- ⚠️ Notes presentation layer pending (shows placeholder)
- ✅ Portfolio, Watchlist, Settings features have UI
