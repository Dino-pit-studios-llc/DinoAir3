@echo off
setlocal enabledelayedexpansion

REM Pseudocode Translator - Windows Test Runner
REM This script:
REM  - Disables plugins (PSEUDOCODE_ENABLE_PLUGINS=0) for safe, deterministic tests
REM  - Sets PYTHONPATH to the repo root so imports work without extra setup
REM  - Runs both test suites:
REM      1) pseudocode_translator/tests/
REM      2) tests/
REM  - Propagates a non-zero exit code if any test run fails

REM Determine repo root based on the script location
set "SCRIPT_DIR=%~dp0"
pushd "%SCRIPT_DIR%\.."
set "REPO_ROOT=%CD%"

echo === Pseudocode Translator: Windows test runner ===
echo Repo root: %REPO_ROOT%
echo - Setting PSEUDOCODE_ENABLE_PLUGINS=0
set "PSEUDOCODE_ENABLE_PLUGINS=0"
echo - Ensuring PYTHONPATH includes repo root
if defined PYTHONPATH (
  set "PYTHONPATH=%REPO_ROOT%;%PYTHONPATH%"
) else (
  set "PYTHONPATH=%REPO_ROOT%"
)
echo PYTHONPATH=%PYTHONPATH%

echo.
echo Running: pytest -q pseudocode_translator/tests/
python -m pytest -q "pseudocode_translator/tests/"
set "RC1=%ERRORLEVEL%"

echo.
echo Running: pytest -q tests/
python -m pytest -q "tests/"
set "RC2=%ERRORLEVEL%"

echo.
echo Flutter web tests (optional): set RUN_FLUTTER_TESTS_WEB=1 to enable
if "%RUN_FLUTTER_TESTS_WEB%"=="1" (
  where flutter >nul 2>nul
  if errorlevel 1 (
    echo Flutter not found on PATH. Skipping Flutter web tests.
    set "RC3=0"
  ) else (
    pushd "user_interface\User_Interface"
    echo Running: flutter test --platform chrome --coverage -r expanded --concurrency=1
    flutter test --platform chrome --coverage -r expanded --concurrency=1
    set "RC3=%ERRORLEVEL%"
    if "%RC3%"=="0" (
      echo Flutter tests passed. Coverage at: %CD%\coverage\lcov.info
    ) else (
      echo Flutter tests failed with RC=%RC3%
    )
    popd
  )
) else (
  echo Skipping Flutter web tests. Set RUN_FLUTTER_TESTS_WEB=1 to enable.
  set "RC3=0"
)

REM Combine exit codes: non-zero if any failed
set "RC=0"
if not "%RC1%"=="0" set "RC=%RC1%"
if not "%RC2%"=="0" set "RC=%RC2%"
if not "%RC3%"=="0" set "RC=%RC3%"

if "%RC%"=="0" (
  echo.
  echo All tests passed.
) else (
  echo.
  echo One or more test runs failed. RC1=%RC1% RC2=%RC2%
)

popd
endlocal & exit /b %RC%
