@echo off
REM Get Home IP Addresses for Oracle Cloud ScreenConnect RDP Access
REM Batch file for easy execution

echo ========================================
echo Home IP Detection for ScreenConnect RDP
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

echo Detecting your home IP addresses...
echo.

REM Run the PowerShell script with default settings
powershell -ExecutionPolicy Bypass -File "get-home-ips.ps1" -UsePublicIPDetection -GenerateTerraformVars

echo.
echo ========================================
echo IP Detection Complete
echo ========================================
echo.
echo Check the generated files:
echo - home-ips.txt (detected IP addresses)
echo - terraform.tfvars.generated (Terraform variables template)
echo.
echo Next steps:
echo 1. Review the detected IP addresses
echo 2. Copy the IPs to your terraform.tfvars file
echo 3. Run terraform plan and apply
echo.
pause 