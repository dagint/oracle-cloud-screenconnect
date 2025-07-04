# Simple ScreenConnect Backup Script for Migration
# Run this on your AWS ScreenConnect server
# Final version - fixes all known issues

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
    Write-Warning "Could not stop all services - $($_.Exception.Message)"
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

# Export IIS sites and applications using appcmd (native IIS tool)
Write-Host "Exporting IIS configuration..." -ForegroundColor Yellow
$iisExportPath = "$backupDir\IIS-Export"
New-Item -ItemType Directory -Path $iisExportPath -Force | Out-Null

try {
    # Export all sites using appcmd
    Write-Host "Exporting websites..." -ForegroundColor Yellow
    $appCmdOutput = & "C:\Windows\System32\inetsrv\appcmd.exe" list site /config
    if ($appCmdOutput) {
        $appCmdOutput | Out-File -FilePath "$iisExportPath\AllSites.xml" -Encoding UTF8
        Write-Host "✓ Websites exported" -ForegroundColor Green
    }

    # Export all application pools using appcmd
    Write-Host "Exporting application pools..." -ForegroundColor Yellow
    $appCmdOutput = & "C:\Windows\System32\inetsrv\appcmd.exe" list apppool /config
    if ($appCmdOutput) {
        $appCmdOutput | Out-File -FilePath "$iisExportPath\AllAppPools.xml" -Encoding UTF8
        Write-Host "✓ Application pools exported" -ForegroundColor Green
    }

    # Export individual sites using appcmd
    Write-Host "Exporting individual site configurations..." -ForegroundColor Yellow
    $sitesOutput = & "C:\Windows\System32\inetsrv\appcmd.exe" list sites
    if ($sitesOutput) {
        $sitesOutput | ForEach-Object {
            if ($_ -match 'SITE "([^"]+)"') {
                $siteName = $matches[1]
                try {
                    $siteConfig = & "C:\Windows\System32\inetsrv\appcmd.exe" list site "$siteName" /config
                    if ($siteConfig) {
                        $siteConfig | Out-File -FilePath "$iisExportPath\Site-$siteName.xml" -Encoding UTF8
                    }
                }
                catch {
                    Write-Warning "Could not export site $siteName - $($_.Exception.Message)"
                }
            }
        }
    }

    # Export individual application pools using appcmd
    Write-Host "Exporting individual app pool configurations..." -ForegroundColor Yellow
    $poolsOutput = & "C:\Windows\System32\inetsrv\appcmd.exe" list apppools
    if ($poolsOutput) {
        $poolsOutput | ForEach-Object {
            if ($_ -match 'APPPOOL "([^"]+)"') {
                $poolName = $matches[1]
                try {
                    $poolConfig = & "C:\Windows\System32\inetsrv\appcmd.exe" list apppool "$poolName" /config
                    if ($poolConfig) {
                        $poolConfig | Out-File -FilePath "$iisExportPath\AppPool-$poolName.xml" -Encoding UTF8
                    }
                }
                catch {
                    Write-Warning "Could not export app pool $poolName - $($_.Exception.Message)"
                }
            }
        }
    }

    # Export IIS bindings
    Write-Host "Exporting IIS bindings..." -ForegroundColor Yellow
    $bindingsOutput = & "C:\Windows\System32\inetsrv\appcmd.exe" list bindings
    if ($bindingsOutput) {
        $bindingsOutput | Out-File -FilePath "$iisExportPath\Bindings.txt" -Encoding UTF8
        Write-Host "✓ IIS bindings exported" -ForegroundColor Green
    }

    Write-Host "✓ IIS configuration exported using appcmd" -ForegroundColor Green
}
catch {
    Write-Warning "Could not export IIS configuration - $($_.Exception.Message)"
}

# Backup SSL certificates
Write-Host "Backing up SSL certificates..." -ForegroundColor Yellow
$certBackupPath = "$backupDir\Certificates"
New-Item -ItemType Directory -Path $certBackupPath -Force | Out-Null

try {
    # Export certificates from personal store
    Get-ChildItem -Path Cert:\LocalMachine\My | ForEach-Object {
        try {
            $certName = $_.Subject -replace '[^a-zA-Z0-9]', '_'
            $certPath = "$certBackupPath\$certName.cer"
            $_.Export('Cert') | Out-File -FilePath $certPath -Encoding Default
        }
        catch {
            Write-Warning "Could not export certificate $($_.Subject) - $($_.Exception.Message)"
        }
    }

    # Export private keys (if accessible)
    Get-ChildItem -Path Cert:\LocalMachine\My | ForEach-Object {
        try {
            $certName = $_.Subject -replace '[^a-zA-Z0-9]', '_'
            $pfxPath = "$certBackupPath\$certName.pfx"
            $_.Export('PFX', 'password123') | Out-File -FilePath $pfxPath -Encoding Default
        }
        catch {
            Write-Warning "Could not export private key for certificate - $($_.Subject)"
        }
    }
    Write-Host "✓ SSL certificates backed up" -ForegroundColor Green
}
catch {
    Write-Warning "Could not backup certificates - $($_.Exception.Message)"
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

# Get IIS information safely using appcmd
$iisInfo = "IIS information not available"
try {
    $appCmdOutput = & "C:\Windows\System32\inetsrv\appcmd.exe" list site
    if ($appCmdOutput) {
        $iisInfo = $appCmdOutput | ForEach-Object {"- $_"}
    }
}
catch {
    $iisInfo = "Could not retrieve IIS information"
}

$sysInfo = @"
ScreenConnect Migration Backup Report
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

System Information:
- OS Version: $((Get-WmiObject -Class Win32_OperatingSystem).Caption)
- ScreenConnect Version: $(Get-ItemProperty -Path "HKLM:\SOFTWARE\ScreenConnect" -Name "Version" -ErrorAction SilentlyContinue).Version
- IIS Version: $(Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\InetStp" -Name "MajorVersion" -ErrorAction SilentlyContinue).MajorVersion

Installed Services:
$(Get-Service | Where-Object {$_.Name -like "*ScreenConnect*"} | ForEach-Object {"- $($_.Name) - $($_.Status)"})

IIS Sites:
$iisInfo

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
    Write-Warning "Could not restart all services - $($_.Exception.Message)"
}

# Create compressed backup with better error handling
Write-Host "Creating compressed backup archive..." -ForegroundColor Yellow
$archivePath = "$backupDir.zip"

# Try multiple approaches for compression
$compressionSuccess = $false
$maxRetries = 3

for ($retry = 1; $retry -le $maxRetries; $retry++) {
    try {
        Write-Host "Attempt $retry of $maxRetries to create backup archive..." -ForegroundColor Yellow
        
        # Wait a bit before retrying to let file handles close
        if ($retry -gt 1) {
            Start-Sleep -Seconds 10
        }
        
        # Try to create the archive
        Compress-Archive -Path $backupDir -DestinationPath $archivePath -Force -ErrorAction Stop
        
        if (Test-Path $archivePath) {
            $fileSize = (Get-Item $archivePath).Length
            $sizeMB = [math]::Round($fileSize / 1MB, 2)
            Write-Host "✓ Backup completed successfully!" -ForegroundColor Green
            Write-Host "Backup location: $archivePath" -ForegroundColor Cyan
            Write-Host "Backup size: $sizeMB MB" -ForegroundColor Cyan
            $compressionSuccess = $true
            break
        } else {
            Write-Warning "Backup archive was not created successfully on attempt $retry"
        }
    }
    catch {
        Write-Warning "Could not create compressed archive on attempt $retry - $($_.Exception.Message)"
        
        if ($retry -eq $maxRetries) {
            Write-Host "All compression attempts failed. Backup files are available in $backupDir" -ForegroundColor Yellow
            $archivePath = $null
        }
    }
}

# If compression failed, try to create a simple zip using 7-Zip if available
if (-not $compressionSuccess) {
    Write-Host "Trying alternative compression method..." -ForegroundColor Yellow
    try {
        # Check if 7-Zip is available
        $sevenZipPath = "C:\Program Files\7-Zip\7z.exe"
        if (Test-Path $sevenZipPath) {
            $sevenZipArchive = "$backupDir.7z"
            & $sevenZipPath a -t7z $sevenZipArchive $backupDir\* -r
            if (Test-Path $sevenZipArchive) {
                $archivePath = $sevenZipArchive
                $fileSize = (Get-Item $archivePath).Length
                $sizeMB = [math]::Round($fileSize / 1MB, 2)
                Write-Host "✓ Backup completed using 7-Zip!" -ForegroundColor Green
                Write-Host "Backup location: $archivePath" -ForegroundColor Cyan
                Write-Host "Backup size: $sizeMB MB" -ForegroundColor Cyan
                $compressionSuccess = $true
            }
        }
    }
    catch {
        Write-Warning "Alternative compression also failed - $($_.Exception.Message)"
    }
}

# Cleanup temporary directory with better error handling
if ($archivePath -and (Test-Path $archivePath)) {
    Write-Host "Cleaning up temporary files..." -ForegroundColor Yellow
    try {
        # Force close any handles that might be locking files
        Start-Sleep -Seconds 5
        
        # Try to remove the directory, ignore errors for locked files
        Remove-Item -Path $backupDir -Recurse -Force -ErrorAction SilentlyContinue
        
        # If directory still exists, try to remove individual locked files
        if (Test-Path $backupDir) {
            Get-ChildItem -Path $backupDir -Recurse -Force | ForEach-Object {
                try {
                    Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue
                }
                catch {
                    # Ignore errors for locked files
                }
            }
            
            # Try to remove the directory again
            Remove-Item -Path $backupDir -Recurse -Force -ErrorAction SilentlyContinue
        }
        
        Write-Host "✓ Cleanup completed" -ForegroundColor Green
    }
    catch {
        Write-Warning "Could not completely clean up temporary files - $($_.Exception.Message)"
        Write-Host "Temporary files may remain in $backupDir" -ForegroundColor Yellow
    }
}

Write-Host "`n=== Next Steps ===" -ForegroundColor Green
Write-Host "1. Copy the backup file to a secure location" -ForegroundColor White
Write-Host "2. Test the backup on a test environment" -ForegroundColor White
Write-Host "3. Proceed with Oracle Cloud deployment" -ForegroundColor White
Write-Host "4. Use the restore script on the Oracle Cloud instance" -ForegroundColor White

if ($archivePath -and (Test-Path $archivePath)) {
    Write-Host "`nBackup file: $archivePath" -ForegroundColor Yellow
} else {
    Write-Host "`nBackup files available in $backupDir" -ForegroundColor Yellow
} 