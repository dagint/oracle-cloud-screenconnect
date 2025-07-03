@echo off
REM Oracle Cloud ScreenConnect Maintenance Batch File
REM Easy execution of maintenance tasks - Cost optimized

setlocal enabledelayedexpansion

echo ========================================
echo Oracle Cloud ScreenConnect Maintenance
echo ========================================
echo.

REM Check if running as administrator
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ERROR: This script must be run as Administrator
    echo Right-click and select "Run as administrator"
    pause
    exit /b 1
)

echo Available maintenance actions:
echo 1. Update ScreenConnect and Windows
echo 2. Install Atera Agent
echo 3. Install Antivirus Agent
echo 4. Install Monitoring Agent
echo 5. Clean up old files
echo 6. System health check
echo 7. All maintenance tasks
echo 8. SSL certificate management
echo 9. Exit
echo.

set /p choice="Enter your choice (1-9): "

if "%choice%"=="1" (
    echo Running ScreenConnect and Windows updates...
    powershell.exe -ExecutionPolicy Bypass -File "%~dp0maintenance.ps1" -Action "update"
) else if "%choice%"=="2" (
    echo Installing Atera Agent...
    set /p config="Enter Atera configuration (JSON): "
    powershell.exe -ExecutionPolicy Bypass -File "%~dp0maintenance.ps1" -Action "agent" -AgentType "atera" -AgentConfig "!config!"
) else if "%choice%"=="3" (
    echo Installing Antivirus Agent...
    set /p config="Enter antivirus configuration (JSON): "
    powershell.exe -ExecutionPolicy Bypass -File "%~dp0maintenance.ps1" -Action "agent" -AgentType "antivirus" -AgentConfig "!config!"
) else if "%choice%"=="4" (
    echo Installing Monitoring Agent...
    set /p config="Enter monitoring configuration (JSON): "
    powershell.exe -ExecutionPolicy Bypass -File "%~dp0maintenance.ps1" -Action "agent" -AgentType "monitoring" -AgentConfig "!config!"
) else if "%choice%"=="5" (
    echo Cleaning up old files...
    powershell.exe -ExecutionPolicy Bypass -File "%~dp0maintenance.ps1" -Action "cleanup"
) else if "%choice%"=="6" (
    echo Running system health check...
    powershell.exe -ExecutionPolicy Bypass -File "%~dp0maintenance.ps1" -Action "health"
) else if "%choice%"=="7" (
    echo Running all maintenance tasks...
    powershell.exe -ExecutionPolicy Bypass -File "%~dp0maintenance.ps1" -Action "all"
) else if "%choice%"=="8" (
    echo SSL Certificate Management
    echo.
    echo Current domains:
    echo - remotesupport.yourdomain.com (web UI - SSL required)
echo - relay.yourdomain.com (relay protocol - no SSL needed)
    echo.
    set /p domain="Enter domain for SSL (e.g., remotesupport.yourdomain.com): "
    set /p email="Enter email for Let's Encrypt: "
    set /p force="Force renewal? (y/n): "
    
    if /i "!force!"=="y" (
        powershell.exe -ExecutionPolicy Bypass -File "%~dp0ssl-management.ps1" -Domain "!domain!" -Email "!email!" -ForceRenewal
    ) else (
        powershell.exe -ExecutionPolicy Bypass -File "%~dp0ssl-management.ps1" -Domain "!domain!" -Email "!email!"
    )
) else if "%choice%"=="9" (
    echo Exiting...
    exit /b 0
) else (
    echo Invalid choice. Please run the script again.
    pause
    exit /b 1
)

echo.
echo Maintenance task completed.
echo Check the log files for details:
echo - C:\screenconnect_maintenance_log.txt
echo - C:\ssl_management_log.txt
echo.
pause 