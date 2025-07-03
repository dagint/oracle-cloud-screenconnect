# Oracle Cloud ScreenConnect Maintenance Script
# Handles updates, agent installation, and system maintenance

param(
    [Parameter(Mandatory=$false)]
    [string]$Action = "all",
    
    [Parameter(Mandatory=$false)]
    [string]$AgentType = "",
    
    [Parameter(Mandatory=$false)]
    [string]$AgentConfig = "",
    
    [Parameter(Mandatory=$false)]
    [switch]$Force,
    
    [Parameter(Mandatory=$false)]
    [switch]$DryRun
)

# Function to write logs
function Write-Log {
    param($Message, $Level = "INFO")
    $logMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'): [$Level] $Message"
    Write-Output $logMessage
    Add-Content -Path "C:\screenconnect_maintenance_log.txt" -Value $logMessage
}

Write-Log "Starting ScreenConnect maintenance process - Action: $Action"

# Check if running as administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Log "ERROR: This script must be run as Administrator" "ERROR"
    exit 1
}

# Function to check ScreenConnect status
function Test-ScreenConnectStatus {
    try {
        $service = Get-Service -Name "ScreenConnect*" -ErrorAction SilentlyContinue
        if ($service) {
            return $service.Status -eq "Running"
        }
        return $false
    } catch {
        return $false
    }
}

# Function to backup ScreenConnect before updates
function Backup-ScreenConnect {
    Write-Log "Creating backup before maintenance..."
    
    $backupDir = "C:\screenconnect_backups\maintenance"
    if (-not (Test-Path $backupDir)) {
        New-Item -Path $backupDir -ItemType Directory -Force
    }
    
    $timestamp = Get-Date -Format "yyyy-MM-dd-HHmmss"
    $backupPath = Join-Path $backupDir "pre-maintenance-$timestamp.scb"
    
    $screenconnectPath = "C:\Program Files (x86)\ScreenConnect\ScreenConnect.Host.exe"
    if (Test-Path $screenconnectPath) {
        try {
            Start-Process -FilePath $screenconnectPath -ArgumentList "backup", "--file", $backupPath, "--description", "Pre-maintenance backup created on $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -Wait -NoNewWindow
            Write-Log "Backup created successfully: $backupPath"
            return $backupPath
        } catch {
            Write-Log "WARNING: Failed to create backup: $_" "WARN"
            return $null
        }
    }
    return $null
}

# Function to update ScreenConnect
function Update-ScreenConnect {
    Write-Log "Checking for ScreenConnect updates..."
    
    # Stop ScreenConnect service
    Write-Log "Stopping ScreenConnect service..."
    Stop-Service -Name "ScreenConnect*" -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 10
    
    # Download latest version
    $downloadUrl = "https://download.screenconnect.com/23.9.8.8811/ScreenConnect_23.9.8.8811.msi"
    $downloadPath = "C:\temp\ScreenConnect_Update.msi"
    
    if (-not (Test-Path "C:\temp")) {
        New-Item -Path "C:\temp" -ItemType Directory -Force
    }
    
    try {
        Write-Log "Downloading latest ScreenConnect version..."
        Invoke-WebRequest -Uri $downloadUrl -OutFile $downloadPath
        
        # Install update
        Write-Log "Installing ScreenConnect update..."
        $installArgs = @(
            "/i", $downloadPath,
            "/quiet",
            "/norestart",
            "/log", "C:\temp\screenconnect_update.log"
        )
        
        if ($DryRun) {
            Write-Log "DRY RUN: Would install ScreenConnect update with args: $($installArgs -join ' ')"
        } else {
            Start-Process -FilePath "msiexec.exe" -ArgumentList $installArgs -Wait -NoNewWindow
            Write-Log "ScreenConnect update completed"
        }
        
        # Clean up
        Remove-Item $downloadPath -Force -ErrorAction SilentlyContinue
        
    } catch {
        Write-Log "ERROR: Failed to update ScreenConnect: $_" "ERROR"
        return $false
    }
    
    # Start ScreenConnect service
    Write-Log "Starting ScreenConnect service..."
    Start-Service -Name "ScreenConnect*" -ErrorAction SilentlyContinue
    
    return $true
}

# Function to install agents
function Install-Agent {
    param(
        [string]$AgentType,
        [string]$AgentConfig
    )
    
    Write-Log "Installing agent: $AgentType"
    
    switch ($AgentType.ToLower()) {
        "atera" {
            Install-AteraAgent -Config $AgentConfig
        }
        "antivirus" {
            Install-AntivirusAgent -Config $AgentConfig
        }
        "monitoring" {
            Install-MonitoringAgent -Config $AgentConfig
        }
        default {
            Write-Log "ERROR: Unknown agent type: $AgentType" "ERROR"
            return $false
        }
    }
}

# Function to install Atera agent
function Install-AteraAgent {
    param([string]$Config)
    
    try {
        # Parse Atera configuration
        $configData = $Config | ConvertFrom-Json -ErrorAction SilentlyContinue
        if (-not $configData) {
            Write-Log "ERROR: Invalid Atera configuration" "ERROR"
            return $false
        }
        
        $downloadUrl = "https://app.atera.com/agents/download"
        $downloadPath = "C:\temp\atera_agent.exe"
        
        Write-Log "Downloading Atera agent..."
        Invoke-WebRequest -Uri $downloadUrl -OutFile $downloadPath
        
        # Install with configuration
        $installArgs = @(
            "/S",
            "/ACCOUNTKEY=$($configData.accountKey)",
            "/SITEKEY=$($configData.siteKey)"
        )
        
        if ($DryRun) {
            Write-Log "DRY RUN: Would install Atera agent with args: $($installArgs -join ' ')"
        } else {
            Start-Process -FilePath $downloadPath -ArgumentList $installArgs -Wait -NoNewWindow
            Write-Log "Atera agent installed successfully"
        }
        
        Remove-Item $downloadPath -Force -ErrorAction SilentlyContinue
        return $true
        
    } catch {
        Write-Log "ERROR: Failed to install Atera agent: $_" "ERROR"
        return $false
    }
}

# Function to install antivirus agent
function Install-AntivirusAgent {
    param([string]$Config)
    
    try {
        $configData = $Config | ConvertFrom-Json -ErrorAction SilentlyContinue
        if (-not $configData) {
            Write-Log "ERROR: Invalid antivirus configuration" "ERROR"
            return $false
        }
        
        # Example: Windows Defender configuration
        if ($configData.type -eq "defender") {
            Write-Log "Configuring Windows Defender..."
            
            # Enable real-time protection
            Set-MpPreference -DisableRealtimeMonitoring $false
            
            # Configure exclusions for ScreenConnect
            $exclusions = @(
                "C:\Program Files (x86)\ScreenConnect\*",
                "C:\ProgramData\ScreenConnect\*"
            )
            
            foreach ($exclusion in $exclusions) {
                Add-MpPreference -ExclusionPath $exclusion
            }
            
            Write-Log "Windows Defender configured successfully"
        }
        
        return $true
        
    } catch {
        Write-Log "ERROR: Failed to install antivirus agent: $_" "ERROR"
        return $false
    }
}

# Function to install monitoring agent
function Install-MonitoringAgent {
    param([string]$Config)
    
    try {
        $configData = $Config | ConvertFrom-Json -ErrorAction SilentlyContinue
        if (-not $configData) {
            Write-Log "ERROR: Invalid monitoring configuration" "ERROR"
            return $false
        }
        
        # Example: Install custom monitoring agent
        Write-Log "Installing monitoring agent..."
        
        # Create monitoring script
        $monitoringScript = @"
# ScreenConnect Monitoring Script
# Monitors ScreenConnect service and performance

`$logFile = "C:\logs\screenconnect_monitoring.log"
`$serviceName = "ScreenConnect*"

# Check service status
`$service = Get-Service -Name `$serviceName -ErrorAction SilentlyContinue
if (`$service.Status -ne "Running") {
    Add-Content -Path `$logFile -Value "$(Get-Date): Service not running - attempting restart"
    Start-Service -Name `$serviceName -ErrorAction SilentlyContinue
}

# Check disk space
`$disk = Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='C:'"
if (`$disk.FreeSpace / `$disk.Size -lt 0.1) {
    Add-Content -Path `$logFile -Value "$(Get-Date): Low disk space warning"
}

# Check memory usage
`$memory = Get-WmiObject -Class Win32_OperatingSystem
`$memoryUsage = (`$memory.TotalVisibleMemorySize - `$memory.FreePhysicalMemory) / `$memory.TotalVisibleMemorySize
if (`$memoryUsage -gt 0.9) {
    Add-Content -Path `$logFile -Value "$(Get-Date): High memory usage warning"
}
"@
        
        $scriptPath = "C:\scripts\monitor-screenconnect.ps1"
        if (-not (Test-Path "C:\scripts")) {
            New-Item -Path "C:\scripts" -ItemType Directory -Force
        }
        
        $monitoringScript | Out-File -FilePath $scriptPath -Encoding UTF8
        
        # Create scheduled task for monitoring
        $taskName = "ScreenConnect Monitoring"
        # Use RemoteSigned instead of Bypass for better security
        $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy RemoteSigned -File `"$scriptPath`""
        $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 5) -RepetitionDuration (New-TimeSpan -Days 365)
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
        
        if (-not $DryRun) {
            Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Force
            Write-Log "Monitoring agent installed successfully"
        } else {
            Write-Log "DRY RUN: Would install monitoring agent"
        }
        
        return $true
        
    } catch {
        Write-Log "ERROR: Failed to install monitoring agent: $_" "ERROR"
        return $false
    }
}

# Function to update Windows
function Update-Windows {
    Write-Log "Checking for Windows updates..."
    
    try {
        # Install PSWindowsUpdate module if not present
        if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
            Write-Log "Installing PSWindowsUpdate module..."
            Install-Module -Name PSWindowsUpdate -Force -Scope LocalMachine
        }
        
        # Import module
        Import-Module PSWindowsUpdate
        
        # Get available updates
        $updates = Get-WindowsUpdate -MicrosoftUpdate -NotCategory "Drivers"
        
        if ($updates.Count -gt 0) {
            Write-Log "Found $($updates.Count) Windows updates"
            
            if ($DryRun) {
                Write-Log "DRY RUN: Would install $($updates.Count) Windows updates"
            } else {
                # Install updates
                Install-WindowsUpdate -MicrosoftUpdate -NotCategory "Drivers" -AcceptAll -IgnoreReboot
                Write-Log "Windows updates installed successfully"
            }
        } else {
            Write-Log "No Windows updates available"
        }
        
    } catch {
        Write-Log "ERROR: Failed to update Windows: $_" "ERROR"
        return $false
    }
    
    return $true
}

# Function to clean up old files
function Cleanup-OldFiles {
    Write-Log "Cleaning up old files..."
    
    try {
        # Clean up old backups (keep last 10)
        $backupDir = "C:\screenconnect_backups"
        if (Test-Path $backupDir) {
            $oldBackups = Get-ChildItem -Path $backupDir -Filter "*.scb" | Sort-Object LastWriteTime -Descending | Select-Object -Skip 10
            foreach ($backup in $oldBackups) {
                if (-not $DryRun) {
                    Remove-Item $backup.FullName -Force
                }
                Write-Log "Removed old backup: $($backup.Name)"
            }
        }
        
        # Clean up temp files
        $tempDirs = @("C:\temp", "C:\Windows\Temp")
        foreach ($tempDir in $tempDirs) {
            if (Test-Path $tempDir) {
                $oldFiles = Get-ChildItem -Path $tempDir -File | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-7) }
                foreach ($file in $oldFiles) {
                    if (-not $DryRun) {
                        Remove-Item $file.FullName -Force -ErrorAction SilentlyContinue
                    }
                }
                Write-Log "Cleaned up $($oldFiles.Count) old files in $tempDir"
            }
        }
        
        # Clean up Windows Update cache
        if (-not $DryRun) {
            Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
            Remove-Item "C:\Windows\SoftwareDistribution\*" -Recurse -Force -ErrorAction SilentlyContinue
            Start-Service -Name wuauserv -ErrorAction SilentlyContinue
            Write-Log "Cleaned up Windows Update cache"
        } else {
            Write-Log "DRY RUN: Would clean up Windows Update cache"
        }
        
    } catch {
        Write-Log "ERROR: Failed to clean up old files: $_" "ERROR"
        return $false
    }
    
    return $true
}

# Function to check system health
function Test-SystemHealth {
    Write-Log "Performing system health check..."
    
    $healthIssues = @()
    
    # Check ScreenConnect service
    if (-not (Test-ScreenConnectStatus)) {
        $healthIssues += "ScreenConnect service not running"
    }
    
    # Check disk space
    $disk = Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='C:'"
    $freeSpacePercent = ($disk.FreeSpace / $disk.Size) * 100
    if ($freeSpacePercent -lt 10) {
        $healthIssues += "Low disk space: $([math]::Round($freeSpacePercent, 1))% free"
    }
    
    # Check memory usage
    $memory = Get-WmiObject -Class Win32_OperatingSystem
    $memoryUsage = (($memory.TotalVisibleMemorySize - $memory.FreePhysicalMemory) / $memory.TotalVisibleMemorySize) * 100
    if ($memoryUsage -gt 90) {
        $healthIssues += "High memory usage: $([math]::Round($memoryUsage, 1))%"
    }
    
    # Check for pending reboots
    $pendingReboot = $false
    $rebootKeys = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending"
    )
    
    foreach ($key in $rebootKeys) {
        if (Test-Path $key) {
            $pendingReboot = $true
            break
        }
    }
    
    if ($pendingReboot) {
        $healthIssues += "System reboot required"
    }
    
    # Report health status
    if ($healthIssues.Count -gt 0) {
        Write-Log "System health issues found:" "WARN"
        foreach ($issue in $healthIssues) {
            Write-Log "  - $issue" "WARN"
        }
        return $false
    } else {
        Write-Log "System health check passed"
        return $true
    }
}

# Main execution logic
try {
    # Create backup before any maintenance
    if ($Action -eq "all" -or $Action -eq "update") {
        $backupPath = Backup-ScreenConnect
    }
    
    # Perform requested actions
    switch ($Action.ToLower()) {
        "update" {
            Update-ScreenConnect
            Update-Windows
        }
        "agent" {
            if ($AgentType) {
                Install-Agent -AgentType $AgentType -AgentConfig $AgentConfig
            } else {
                Write-Log "ERROR: Agent type must be specified for agent installation" "ERROR"
            }
        }
        "cleanup" {
            Cleanup-OldFiles
        }
        "health" {
            Test-SystemHealth
        }
        "all" {
            Update-ScreenConnect
            Update-Windows
            Cleanup-OldFiles
            Test-SystemHealth
        }
        default {
            Write-Log "ERROR: Unknown action: $Action" "ERROR"
            Write-Log "Valid actions: update, agent, cleanup, health, all"
            exit 1
        }
    }
    
    Write-Log "Maintenance process completed successfully"
    
} catch {
    Write-Log "ERROR: Maintenance process failed: $_" "ERROR"
    exit 1
} 