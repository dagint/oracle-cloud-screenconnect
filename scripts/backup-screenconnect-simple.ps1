# Simple ScreenConnect Backup Script for Migration
# Run this on your AWS ScreenConnect server

param(
    [string]$BackupPath = "C:\ScreenConnect-Backup"
)

Write-Host "=== ScreenConnect Backup for Migration ===" -ForegroundColor Green
Write-Host "This script will create a backup of your ScreenConnect installation" -ForegroundColor Yellow

# Create backup directory with timestamp
$timestamp = Get-Date -Format "yyyy-MM-dd-HHmm"
$backupDir = "$BackupPath-$timestamp"
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null

Write-Host "Backup directory: $backupDir" -ForegroundColor Cyan

# Stop ScreenConnect services
Write-Host "Stopping ScreenConnect services..." -ForegroundColor Yellow
try {
    Stop-Service -Name "ScreenConnect" -Force -ErrorAction SilentlyContinue
    Stop-Service -Name "ScreenConnectRelay" -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 5
    Write-Host "✓ Services stopped" -ForegroundColor Green
}
catch {
    Write-Warning "Could not stop all services: $($_.Exception.Message)"
}

# Backup ScreenConnect installation
Write-Host "Backing up ScreenConnect files..." -ForegroundColor Yellow
$screenConnectPath = "C:\Program Files (x86)\ScreenConnect"
if (Test-Path $screenConnectPath) {
    Copy-Item -Path $screenConnectPath -Destination "$backupDir\ScreenConnect" -Recurse -Force
    Write-Host "✓ ScreenConnect files backed up" -ForegroundColor Green
} else {
    Write-Warning "ScreenConnect not found at expected location: $screenConnectPath"
}

# Backup IIS configuration
Write-Host "Backing up IIS configuration..." -ForegroundColor Yellow
$iisConfigPath = "C:\Windows\System32\inetsrv\config"
if (Test-Path $iisConfigPath) {
    Copy-Item -Path $iisConfigPath -Destination "$backupDir\IIS-Config" -Recurse -Force
    Write-Host "✓ IIS configuration backed up" -ForegroundColor Green
}

# Export IIS sites and applications
Write-Host "Exporting IIS configuration..." -ForegroundColor Yellow
$iisExportPath = "$backupDir\IIS-Export"
New-Item -ItemType Directory -Path $iisExportPath -Force | Out-Null

try {
    # Export application pools
    Get-IISAppPool | ForEach-Object {
        $poolName = $_.Name
        $_.GetConfiguration() | Export-WebConfiguration -FilePath "$iisExportPath\AppPool-$poolName.xml"
    }

    # Export sites
    Get-IISWebsite | ForEach-Object {
        $siteName = $_.Name
        $_.GetConfiguration() | Export-WebConfiguration -FilePath "$iisExportPath\Site-$siteName.xml"
    }
    Write-Host "✓ IIS configuration exported" -ForegroundColor Green
}
catch {
    Write-Warning "Could not export IIS configuration: $($_.Exception.Message)"
}

# Backup SSL certificates
Write-Host "Backing up SSL certificates..." -ForegroundColor Yellow
$certBackupPath = "$backupDir\Certificates"
New-Item -ItemType Directory -Path $certBackupPath -Force | Out-Null

try {
    # Export certificates from personal store
    Get-ChildItem -Path Cert:\LocalMachine\My | ForEach-Object {
        $certName = $_.Subject -replace '[^a-zA-Z0-9]', '_'
        $certPath = "$certBackupPath\$certName.cer"
        $_.Export('Cert') | Out-File -FilePath $certPath -Encoding Binary
    }

    # Export private keys (if accessible)
    Get-ChildItem -Path Cert:\LocalMachine\My | ForEach-Object {
        try {
            $certName = $_.Subject -replace '[^a-zA-Z0-9]', '_'
            $pfxPath = "$certBackupPath\$certName.pfx"
            $_.Export('PFX', 'password123') | Out-File -FilePath $pfxPath -Encoding Binary
        }
        catch {
            Write-Warning "Could not export private key for certificate: $($_.Subject)"
        }
    }
    Write-Host "✓ SSL certificates backed up" -ForegroundColor Green
}
catch {
    Write-Warning "Could not backup certificates: $($_.Exception.Message)"
}

# Backup Windows Registry (ScreenConnect related)
Write-Host "Backing up registry settings..." -ForegroundColor Yellow
$regBackupPath = "$backupDir\Registry"
New-Item -ItemType Directory -Path $regBackupPath -Force | Out-Null

$regKeys = @(
    "HKLM:\SOFTWARE\ScreenConnect",
    "HKLM:\SOFTWARE\WOW6432Node\ScreenConnect"
)

foreach ($key in $regKeys) {
    if (Test-Path $key) {
        $keyName = $key.Split('\')[-1]
        reg export $key "$regBackupPath\$keyName.reg" /y | Out-Null
    }
}
Write-Host "✓ Registry settings backed up" -ForegroundColor Green

# Create system information report
Write-Host "Creating system information report..." -ForegroundColor Yellow
$sysInfoPath = "$backupDir\System-Info.txt"

$sysInfo = @"
ScreenConnect Migration Backup Report
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

System Information:
- OS Version: $((Get-WmiObject -Class Win32_OperatingSystem).Caption)
- ScreenConnect Version: $(Get-ItemProperty -Path "HKLM:\SOFTWARE\ScreenConnect" -Name "Version" -ErrorAction SilentlyContinue).Version
- IIS Version: $(Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\InetStp" -Name "MajorVersion" -ErrorAction SilentlyContinue).MajorVersion

Installed Services:
$(Get-Service | Where-Object {$_.Name -like "*ScreenConnect*"} | ForEach-Object {"- $($_.Name): $($_.Status)"})

IIS Sites:
$(Get-IISWebsite | ForEach-Object {"- $($_.Name): $($_.State)"})

SSL Certificates:
$(Get-ChildItem -Path Cert:\LocalMachine\My | ForEach-Object {"- $($_.Subject) (Expires: $($_.NotAfter))"})

"@

$sysInfo | Out-File -FilePath $sysInfoPath -Encoding UTF8
Write-Host "✓ System information report created" -ForegroundColor Green

# Restart ScreenConnect services
Write-Host "Restarting ScreenConnect services..." -ForegroundColor Yellow
try {
    Start-Service -Name "ScreenConnect" -ErrorAction SilentlyContinue
    Start-Service -Name "ScreenConnectRelay" -ErrorAction SilentlyContinue
    Write-Host "✓ Services restarted" -ForegroundColor Green
}
catch {
    Write-Warning "Could not restart all services: $($_.Exception.Message)"
}

# Create compressed backup
Write-Host "Creating compressed backup archive..." -ForegroundColor Yellow
$archivePath = "$backupDir.zip"
Compress-Archive -Path $backupDir -DestinationPath $archivePath -Force

Write-Host "✓ Backup completed successfully!" -ForegroundColor Green
Write-Host "Backup location: $archivePath" -ForegroundColor Cyan
Write-Host "Backup size: $([math]::Round((Get-Item $archivePath).Length / 1MB, 2)) MB" -ForegroundColor Cyan

# Cleanup temporary directory
Remove-Item -Path $backupDir -Recurse -Force

Write-Host "`n=== Next Steps ===" -ForegroundColor Green
Write-Host "1. Copy the backup file to a secure location" -ForegroundColor White
Write-Host "2. Test the backup on a test environment" -ForegroundColor White
Write-Host "3. Proceed with Oracle Cloud deployment" -ForegroundColor White
Write-Host "4. Use the restore script on the Oracle Cloud instance" -ForegroundColor White

Write-Host "`nBackup file: $archivePath" -ForegroundColor Yellow 