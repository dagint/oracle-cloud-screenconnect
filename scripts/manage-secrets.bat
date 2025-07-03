@echo off
REM Oracle Cloud ScreenConnect Secrets Management
REM Batch file for secure secrets management

echo ========================================
echo ScreenConnect Secrets Management
echo ========================================
echo.

REM Check if PowerShell is available
powershell -Command "Write-Host 'PowerShell is available'" >nul 2>&1
if errorlevel 1 (
    echo ERROR: PowerShell is not available or not in PATH
    echo Please ensure PowerShell is installed and accessible
    pause
    exit /b 1
)

REM Change to script directory
cd /d "%~dp0"

echo Checking secrets management status...
echo.

REM Run the PowerShell script to check secrets status
powershell -ExecutionPolicy Bypass -File "manage-secrets.ps1" -Action check

echo.
echo ========================================
echo Secrets Management Complete
echo ========================================
echo.
echo Available actions:
echo - Check secrets status: .\manage-secrets.ps1 -Action check
echo - Generate secure config: .\manage-secrets.ps1 -Action generate
echo.
echo Security recommendations:
echo 1. Use Oracle Vault for production (use_vault_for_secrets = true)
echo 2. Never commit secrets to version control
echo 3. Use environment variables in CI/CD
echo 4. Regularly rotate API tokens and passwords
echo.
pause 