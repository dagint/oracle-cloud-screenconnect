# Simple ScreenConnect Restore Script for Migration
# Run this on your Oracle Cloud ScreenConnect instance

param(
    [Parameter(Mandatory=$true)]
    [string]$BackupPath,
    
    [Parameter(Mandatory=$false)]
    [string]$ScreenConnectPath = "C:\Program Files (x86)\ScreenConnect"
)

Write-Host "=== ScreenConnect Restore for Migration ===" -ForegroundColor Green
Write-Host "This script will restore ScreenConnect from backup" -ForegroundColor Yellow

# Validate backup file
if (-not (Test-Path $BackupPath)) {
    Write-Error "Backup file not found: $BackupPath"
    exit 1
}

Write-Host "Backup file: $BackupPath" -ForegroundColor Cyan

# Create restore directory
$restoreDir = "C:\temp\screenconnect-restore"
if (Test-Path $restoreDir) {
    Remove-Item -Path $restoreDir -Recurse -Force
}
New-Item -ItemType Directory -Path $restoreDir -Force | Out-Null

# Extract backup
Write-Host "Extracting backup..." -ForegroundColor Yellow
try {
    Expand-Archive -Path $BackupPath -DestinationPath $restoreDir -Force
    Write-Host "✓ Backup extracted" -ForegroundColor Green
}
catch {
    Write-Error "Failed to extract backup: $($_.Exception.Message)"
    exit 1
}

# Find the backup directory (it might be nested)
$backupContent = Get-ChildItem -Path $restoreDir -Directory | Select-Object -First 1
if (-not $backupContent) {
    Write-Error "Invalid backup structure - no directories found"
    exit 1
}

$actualBackupDir = $backupContent.FullName
Write-Host "Backup content directory: $actualBackupDir" -ForegroundColor Cyan

# Stop ScreenConnect services
Write-Host "Stopping ScreenConnect services..." -ForegroundColor Yellow
try {
    Stop-Service -Name "ScreenConnect*" -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 5
    Write-Host "✓ Services stopped" -ForegroundColor Green
}
catch {
    Write-Warning "Could not stop all services: $($_.Exception.Message)"
}

# Backup existing installation
if (Test-Path $ScreenConnectPath) {
    Write-Host "Backing up existing installation..." -ForegroundColor Yellow
    $existingBackup = "$ScreenConnectPath-backup-$(Get-Date -Format 'yyyy-MM-dd-HHmm')"
    Copy-Item -Path $ScreenConnectPath -Destination $existingBackup -Recurse -Force
    Write-Host "✓ Existing installation backed up to: $existingBackup" -ForegroundColor Green
}

# Restore ScreenConnect files
Write-Host "Restoring ScreenConnect files..." -ForegroundColor Yellow
$sourceScreenConnect = "$actualBackupDir\ScreenConnect"
if (Test-Path $sourceScreenConnect) {
    Copy-Item -Path $sourceScreenConnect -Destination $ScreenConnectPath -Recurse -Force
    Write-Host "✓ ScreenConnect files restored" -ForegroundColor Green
} else {
    Write-Warning "ScreenConnect files not found in backup"
}

# Restore IIS configuration
Write-Host "Restoring IIS configuration..." -ForegroundColor Yellow
$sourceIISConfig = "$actualBackupDir\IIS-Config"
if (Test-Path $sourceIISConfig) {
    Copy-Item -Path $sourceIISConfig -Destination "C:\Windows\System32\inetsrv\config" -Recurse -Force
    Write-Host "✓ IIS configuration restored" -ForegroundColor Green
}

# Restore registry settings
Write-Host "Restoring registry settings..." -ForegroundColor Yellow
$regBackupPath = "$actualBackupDir\Registry"
if (Test-Path $regBackupPath) {
    Get-ChildItem -Path $regBackupPath -Filter "*.reg" | ForEach-Object {
        Write-Host "Importing registry file: $($_.Name)" -ForegroundColor Cyan
        reg import $_.FullName | Out-Null
    }
    Write-Host "✓ Registry settings restored" -ForegroundColor Green
}

# Restore SSL certificates
Write-Host "Restoring SSL certificates..." -ForegroundColor Yellow
$certBackupPath = "$actualBackupDir\Certificates"
if (Test-Path $certBackupPath) {
    Get-ChildItem -Path $certBackupPath -Filter "*.pfx" | ForEach-Object {
        try {
            $certName = $_.BaseName
            Write-Host "Importing certificate: $certName" -ForegroundColor Cyan
            Import-PfxCertificate -FilePath $_.FullName -CertStoreLocation Cert:\LocalMachine\My -Password (ConvertTo-SecureString -String "password123" -AsPlainText -Force)
        }
        catch {
            Write-Warning "Could not import certificate: $($_.Name)"
        }
    }
    Write-Host "✓ SSL certificates restored" -ForegroundColor Green
}

# Update configuration for Oracle Cloud
Write-Host "Updating configuration for Oracle Cloud..." -ForegroundColor Yellow

# Update web.config if it exists
$webConfigPath = "$ScreenConnectPath\App_Web.config"
if (Test-Path $webConfigPath) {
    Write-Host "Updating web.config..." -ForegroundColor Cyan
    
    try {
        $webConfig = [xml](Get-Content $webConfigPath)
        
        # Update connection strings if needed
        $connectionStrings = $webConfig.SelectNodes("//connectionStrings/add")
        foreach ($connString in $connectionStrings) {
            if ($connString.connectionString -like "*localhost*") {
                $connString.connectionString = $connString.connectionString -replace "localhost", "127.0.0.1"
            }
        }
        
        # Save updated web.config
        $webConfig.Save($webConfigPath)
        Write-Host "✓ Web.config updated" -ForegroundColor Green
    }
    catch {
        Write-Warning "Could not update web.config: $($_.Exception.Message)"
    }
}

# Update service configuration
$serviceConfigPath = "$ScreenConnectPath\ScreenConnect.Service.exe.config"
if (Test-Path $serviceConfigPath) {
    Write-Host "Updating service configuration..." -ForegroundColor Cyan
    
    try {
        $serviceConfig = [xml](Get-Content $serviceConfigPath)
        
        # Update any localhost references
        $appSettings = $serviceConfig.SelectNodes("//appSettings/add")
        foreach ($setting in $appSettings) {
            if ($setting.value -like "*localhost*") {
                $setting.value = $setting.value -replace "localhost", "127.0.0.1"
            }
        }
        
        # Save updated service config
        $serviceConfig.Save($serviceConfigPath)
        Write-Host "✓ Service configuration updated" -ForegroundColor Green
    }
    catch {
        Write-Warning "Could not update service configuration: $($_.Exception.Message)"
    }
}

# Start ScreenConnect services
Write-Host "Starting ScreenConnect services..." -ForegroundColor Yellow
try {
    Start-Service -Name "ScreenConnect" -ErrorAction SilentlyContinue
    Start-Service -Name "ScreenConnectRelay" -ErrorAction SilentlyContinue
    
    # Wait for services to start
    Start-Sleep -Seconds 30
    
    # Check service status
    $screenConnectService = Get-Service -Name "ScreenConnect" -ErrorAction SilentlyContinue
    $relayService = Get-Service -Name "ScreenConnectRelay" -ErrorAction SilentlyContinue
    
    if ($screenConnectService.Status -eq "Running") {
        Write-Host "✓ ScreenConnect service started successfully" -ForegroundColor Green
    } else {
        Write-Warning "ScreenConnect service not running. Status: $($screenConnectService.Status)"
    }
    
    if ($relayService.Status -eq "Running") {
        Write-Host "✓ ScreenConnect Relay service started successfully" -ForegroundColor Green
    } else {
        Write-Warning "ScreenConnect Relay service not running. Status: $($relayService.Status)"
    }
}
catch {
    Write-Warning "Could not start all services: $($_.Exception.Message)"
}

# Cleanup
Write-Host "Cleaning up temporary files..." -ForegroundColor Yellow
Remove-Item -Path $restoreDir -Recurse -Force

Write-Host "`n✓ ScreenConnect restore completed successfully!" -ForegroundColor Green
Write-Host "`n=== Next Steps ===" -ForegroundColor Green
Write-Host "1. Configure SSL certificates for new domains" -ForegroundColor White
Write-Host "2. Update DNS records" -ForegroundColor White
Write-Host "3. Test all ScreenConnect functionality" -ForegroundColor White
Write-Host "4. Run SSL management script: .\scripts\ssl-management.ps1" -ForegroundColor White
Write-Host "5. Verify backups are working" -ForegroundColor White

Write-Host "`n=== Important Notes ===" -ForegroundColor Yellow
Write-Host "• Check the system information report in the backup for details" -ForegroundColor White
Write-Host "• Verify all custom configurations were restored" -ForegroundColor White
Write-Host "• Test user access and functionality" -ForegroundColor White
Write-Host "• Monitor logs for any errors" -ForegroundColor White 