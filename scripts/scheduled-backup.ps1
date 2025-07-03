# Oracle Cloud ScreenConnect Backup Script
# This script creates weekly backups and maintains only the 5 most recent copies
# Credentials are retrieved from Oracle Vault

param(
    [Parameter(Mandatory=$false)]
    [int]$MaxBackups = 5,
    
    [Parameter(Mandatory=$false)]
    [string]$BackupPrefix = "screenconnect-backup",
    
    [Parameter(Mandatory=$false)]
    [string]$SecretPrefix = "screenconnect-backup"
)

# Function to write logs
function Write-Log {
    param($Message)
    $logMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'): $Message"
    Write-Output $logMessage
    Add-Content -Path "C:\screenconnect_backup_log.txt" -Value $logMessage
}

Write-Log "Starting Oracle Cloud ScreenConnect backup process"

# Check if OCI CLI is installed
if (-not (Get-Command oci -ErrorAction SilentlyContinue)) {
    Write-Log "ERROR: Oracle Cloud CLI (oci) not found"
    Write-Log "Please install OCI CLI from: https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm"
    exit 1
}

# Function to retrieve secret from Oracle Vault
function Get-OracleSecret {
    param([string]$SecretName)
    try {
        $secretValue = oci vault secret get --secret-id $SecretName --query "data.\"secret-bundle-content\".content" --raw-output
        return $secretValue
    } catch {
        Write-Log "ERROR: Failed to retrieve secret '$SecretName': $_"
        exit 1
    }
}

# Retrieve credentials from Oracle Vault
Write-Log "Retrieving credentials from Oracle Vault..."
try {
    $BucketName = Get-OracleSecret "$SecretPrefix-bucket-name"
    $Namespace = Get-OracleSecret "$SecretPrefix-namespace"
    $Region = Get-OracleSecret "$SecretPrefix-region"
    
    # Try to get backup password (optional)
    $BackupPassword = ""
    try {
        $BackupPassword = Get-OracleSecret "$SecretPrefix-backup-password"
    } catch {
        Write-Log "No backup password found in Vault (backups will be unencrypted)"
    }
    
    Write-Log "Credentials retrieved successfully from Oracle Vault"
} catch {
    Write-Log "ERROR: Failed to retrieve credentials from Oracle Vault: $_"
    exit 1
}

# Check if ScreenConnect is installed
$screenconnectPath = "C:\Program Files (x86)\ScreenConnect\ScreenConnect.Host.exe"
if (-not (Test-Path $screenconnectPath)) {
    Write-Log "ERROR: ScreenConnect not found at expected location"
    exit 1
}

# Create backup directory
$backupDir = "C:\screenconnect_backups"
if (-not (Test-Path $backupDir)) {
    New-Item -Path $backupDir -ItemType Directory -Force
    Write-Log "Created backup directory: $backupDir"
}

# Generate backup filename with timestamp
$timestamp = Get-Date -Format "yyyy-MM-dd-HHmmss"
$backupFileName = "$BackupPrefix-$timestamp.scb"
$backupPath = Join-Path $backupDir $backupFileName
$zipFileName = "$BackupPrefix-$timestamp.zip"
$zipPath = Join-Path $backupDir $zipFileName

# Create the backup
Write-Log "Creating backup: $backupFileName"
try {
    $backupArgs = @(
        "backup",
        "--file", $backupPath,
        "--description", "Scheduled backup created on $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    )
    
    if ($BackupPassword) {
        $backupArgs += @("--password", $BackupPassword)
        Write-Log "Backup will be encrypted with password"
    }
    
    Start-Process -FilePath $screenconnectPath -ArgumentList $backupArgs -Wait -NoNewWindow
    
    if (Test-Path $backupPath) {
        $fileSize = (Get-Item $backupPath).Length
        $fileSizeMB = [math]::Round($fileSize / 1MB, 2)
        Write-Log "Backup created successfully: $fileSizeMB MB"
    } else {
        Write-Log "ERROR: Backup file not found after creation"
        exit 1
    }
} catch {
    Write-Log "ERROR: Failed to create backup: $_"
    exit 1
}

# Create zip archive
Write-Log "Creating zip archive: $zipFileName"
try {
    Compress-Archive -Path $backupPath -DestinationPath $zipPath -Force
    Write-Log "Zip archive created successfully"
} catch {
    Write-Log "ERROR: Failed to create zip archive: $_"
    exit 1
}

# Upload to Oracle Object Storage
Write-Log "Uploading backup to Oracle Object Storage..."
try {
    # Use Start-Process instead of Invoke-Expression for security
    $uploadArgs = @(
        "os", "object", "put",
        "--bucket-name", $BucketName,
        "--file", $zipPath,
        "--name", $zipFileName,
        "--namespace", $Namespace
    )
    
    $process = Start-Process -FilePath "oci" -ArgumentList $uploadArgs -Wait -PassThru -NoNewWindow
    
    if ($process.ExitCode -eq 0) {
        Write-Log "Backup uploaded successfully to $BucketName/$zipFileName"
    } else {
        Write-Log "ERROR: Upload failed with exit code: $($process.ExitCode)"
        exit 1
    }
} catch {
    Write-Log "ERROR: Upload failed: $_"
    exit 1
}

# List existing backups and keep only the most recent ones
Write-Log "Managing backup retention (keeping $MaxBackups most recent backups)..."
try {
    # List all backups in the bucket using safer approach
    $listArgs = @(
        "os", "object", "list",
        "--bucket-name", $BucketName,
        "--namespace", $Namespace,
        "--query", "data[?contains(name, '$BackupPrefix-') && contains(name, '.zip')].{name: name, timeCreated: 'time-created'}",
        "--output", "table"
    )
    
    $backupListOutput = & oci @listArgs
    
    if ($backupListOutput) {
        # Parse the list and sort by date (newest first)
        $backups = @()
        foreach ($line in $backupListOutput) {
            if ($line -match "$BackupPrefix-(\d{4}-\d{2}-\d{2}-\d{6})\.zip") {
                $backupDate = [DateTime]::ParseExact($matches[1], "yyyy-MM-dd-HHmmss", $null)
                $backups += [PSCustomObject]@{
                    Date = $backupDate
                    Name = "$BackupPrefix-$($matches[1]).zip"
                }
            }
        }
        
        # Sort by date (newest first) and remove old backups
        $sortedBackups = $backups | Sort-Object Date -Descending
        $backupsToDelete = $sortedBackups | Select-Object -Skip $MaxBackups
        
        foreach ($backup in $backupsToDelete) {
            Write-Log "Deleting old backup: $($backup.Name)"
            $deleteArgs = @(
                "os", "object", "delete",
                "--bucket-name", $BucketName,
                "--object-name", $backup.Name,
                "--namespace", $Namespace,
                "--force"
            )
            
            $deleteProcess = Start-Process -FilePath "oci" -ArgumentList $deleteArgs -Wait -PassThru -NoNewWindow
            if ($deleteProcess.ExitCode -ne 0) {
                Write-Log "WARNING: Failed to delete backup $($backup.Name)"
            }
        }
        
        Write-Log "Backup retention completed. Kept $($sortedBackups.Count - $backupsToDelete.Count) backups, deleted $($backupsToDelete.Count) old backups"
    } else {
        Write-Log "No existing backups found in bucket"
    }
} catch {
    Write-Log "WARNING: Failed to manage backup retention: $_"
}

# Clean up local files
Write-Log "Cleaning up local backup files..."
try {
    Remove-Item $backupPath -Force -ErrorAction SilentlyContinue
    Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
    Write-Log "Local cleanup completed"
} catch {
    Write-Log "WARNING: Failed to clean up local files: $_"
}

Write-Log "Oracle Cloud backup process completed successfully" 