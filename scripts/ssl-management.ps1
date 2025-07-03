# Oracle Cloud ScreenConnect SSL Management Script
# Manages SSL certificates using Let's Encrypt - Cost optimized

param(
    [Parameter(Mandatory=$true)]
    [string]$Domain,
    
    [Parameter(Mandatory=$false)]
    [string]$Email = "admin@yourdomain.com",
    
    [Parameter(Mandatory=$false)]
    [switch]$ForceRenewal,
    
    [Parameter(Mandatory=$false)]
    [switch]$DryRun,
    
    [Parameter(Mandatory=$false)]
    [switch]$InstallOnly
)

# Function to write logs
function Write-Log {
    param($Message, $Level = "INFO")
    $logMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'): [$Level] $Message"
    Write-Output $logMessage
    Add-Content -Path "C:\ssl_management_log.txt" -Value $logMessage
}

Write-Log "Starting SSL certificate management for domain: $Domain"

# Check if running as administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Log "ERROR: This script must be run as Administrator" "ERROR"
    exit 1
}

# Function to install Win-Acme (Let's Encrypt client)
function Install-WinAcme {
    Write-Log "Installing Win-Acme (Let's Encrypt client)..."
    
    try {
        # Download Win-Acme
        $downloadUrl = "https://github.com/win-acme/win-acme/releases/latest/download/wacs.exe"
        $wacsPath = "C:\tools\wacs.exe"
        
        if (-not (Test-Path "C:\tools")) {
            New-Item -Path "C:\tools" -ItemType Directory -Force
        }
        
        if (-not (Test-Path $wacsPath) -or $ForceRenewal) {
            Invoke-WebRequest -Uri $downloadUrl -OutFile $wacsPath
            Write-Log "Win-Acme downloaded successfully"
        }
        
        return $wacsPath
        
    } catch {
        Write-Log "ERROR: Failed to install Win-Acme: $_" "ERROR"
        return $null
    }
}

# Function to check if certificate is valid
function Test-CertificateValid {
    param([string]$Domain)
    
    try {
        $cert = Get-ChildItem -Path "Cert:\LocalMachine\My" | Where-Object { 
            $_.Subject -like "*$Domain*" -and $_.NotAfter -gt (Get-Date) 
        } | Sort-Object NotAfter -Descending | Select-Object -First 1
        
        if ($cert) {
            $daysUntilExpiry = ($cert.NotAfter - (Get-Date)).Days
            Write-Log "Certificate for $Domain expires in $daysUntilExpiry days"
            return $daysUntilExpiry -gt 30
        }
        
        return $false
        
    } catch {
        Write-Log "ERROR: Failed to check certificate validity: $_" "ERROR"
        return $false
    }
}

# Function to obtain SSL certificate
function Get-SSLCertificate {
    param(
        [string]$Domain,
        [string]$Email,
        [string]$WacsPath
    )
    
    Write-Log "Obtaining SSL certificate for $Domain..."
    
    try {
        # Create certificate directory
        $certDir = "C:\certificates\$Domain"
        if (-not (Test-Path $certDir)) {
            New-Item -Path $certDir -ItemType Directory -Force
        }
        
        # Build Win-Acme arguments
        $wacsArgs = @(
            "--target", "manual",
            "--host", $Domain,
            "--installation", "iis",
            "--accepttos",
            "--email", $Email,
            "--certificatestore", "My",
            "--centralssl",
            "--centralsslstore", "C:\certificates"
        )
        
        if ($DryRun) {
            $wacsArgs += "--dryrun"
        }
        
        if ($ForceRenewal) {
            $wacsArgs += "--force"
        }
        
        # Execute Win-Acme
        $process = Start-Process -FilePath $WacsPath -ArgumentList $wacsArgs -Wait -PassThru -NoNewWindow
        
        Write-Log "Win-Acme command: $WacsPath $($wacsArgs -join ' ')"
        
        if ($process.ExitCode -eq 0) {
            Write-Log "SSL certificate obtained successfully for $Domain"
            return $true
        } else {
            Write-Log "ERROR: Failed to obtain SSL certificate for $Domain (Exit code: $($process.ExitCode))" "ERROR"
            return $false
        }
        
    } catch {
        Write-Log "ERROR: Failed to obtain SSL certificate: $_" "ERROR"
        return $false
    }
}

# Function to configure IIS for SSL
function Configure-IISSSL {
    param([string]$Domain)
    
    Write-Log "Configuring IIS for SSL certificate..."
    
    try {
        # Import IIS module
        Import-Module WebAdministration
        
        # Get certificate thumbprint
        $cert = Get-ChildItem -Path "Cert:\LocalMachine\My" | Where-Object { 
            $_.Subject -like "*$Domain*" 
        } | Sort-Object NotAfter -Descending | Select-Object -First 1
        
        if (-not $cert) {
            Write-Log "ERROR: Certificate not found for $Domain" "ERROR"
            return $false
        }
        
        # Configure IIS site
        $siteName = "ScreenConnect"
        $site = Get-Website -Name $siteName -ErrorAction SilentlyContinue
        
        if (-not $site) {
            Write-Log "Creating IIS site: $siteName"
            New-Website -Name $siteName -Port 443 -PhysicalPath "C:\inetpub\wwwroot\screenconnect" -SslFlags 1
        }
        
        # Bind SSL certificate
        $binding = Get-WebBinding -Name $siteName -Protocol "https" -ErrorAction SilentlyContinue
        
        if ($binding) {
            Remove-WebBinding -Name $siteName -Protocol "https"
        }
        
        New-WebBinding -Name $siteName -Protocol "https" -Port 443 -SslFlags 1 -CertificateThumbPrint $cert.Thumbprint
        
        Write-Log "IIS SSL configuration completed"
        return $true
        
    } catch {
        Write-Log "ERROR: Failed to configure IIS SSL: $_" "ERROR"
        return $false
    }
}

# Function to configure ScreenConnect for SSL
function Configure-ScreenConnectSSL {
    param([string]$Domain)
    
    Write-Log "Configuring ScreenConnect for SSL..."
    
    try {
        # ScreenConnect configuration file path
        $configPath = "C:\Program Files (x86)\ScreenConnect\App_Data\config.json"
        
        if (Test-Path $configPath) {
            # Read current configuration
            $config = Get-Content -Path $configPath | ConvertFrom-Json
            
            # Update SSL settings
            $config.SslSettings = @{
                Enabled = $true
                CertificateThumbprint = (Get-ChildItem -Path "Cert:\LocalMachine\My" | Where-Object { 
                    $_.Subject -like "*$Domain*" 
                } | Sort-Object NotAfter -Descending | Select-Object -First 1).Thumbprint
                Domain = $Domain
            }
            
            # Update web server settings
            $config.WebServerSettings = @{
                Port = 443
                SslPort = 443
                UseSsl = $true
            }
            
            # Save configuration
            $config | ConvertTo-Json -Depth 10 | Set-Content -Path $configPath
            
            Write-Log "ScreenConnect SSL configuration updated"
        } else {
            Write-Log "WARNING: ScreenConnect configuration file not found" "WARN"
        }
        
        return $true
        
    } catch {
        Write-Log "ERROR: Failed to configure ScreenConnect SSL: $_" "ERROR"
        return $false
    }
}

# Function to create scheduled task for certificate renewal
function New-CertificateRenewalTask {
    Write-Log "Creating scheduled task for certificate renewal..."
    
    try {
        $scriptPath = $MyInvocation.MyCommand.Path
        
        # Create renewal script
        $renewalScript = @"
# SSL Certificate Renewal Script
# Auto-generated by SSL management script

param([string]`$Domain, [string]`$Email)

Write-Host "Renewing SSL certificate for `$Domain..."

# Check if win-acme is available
`$WacsPath = "C:\Program Files\win-acme\wacs.exe"
if (-not (Test-Path `$WacsPath)) {
    Write-Error "win-acme not found at `$WacsPath"
    exit 1
}

# Renew certificate
`$wacsArgs = @(
    "--target", "manual",
    "--host", "`$Domain",
    "--installation", "iis",
    "--accept-terms",
    "--email", "`$Email"
)

`$process = Start-Process -FilePath `$WacsPath -ArgumentList `$wacsArgs -Wait -PassThru -NoNewWindow

if (`$process.ExitCode -eq 0) {
    Write-Host "SSL certificate renewed successfully for `$Domain"
} else {
    Write-Error "Failed to renew SSL certificate for `$Domain"
    exit 1
}
"@

        $renewalScriptPath = "C:\scripts\renew-ssl.ps1"
        if (-not (Test-Path "C:\scripts")) {
            New-Item -Path "C:\scripts" -ItemType Directory -Force
        }
        
        $renewalScript | Out-File -FilePath $renewalScriptPath -Encoding UTF8
        
        # Create scheduled task for automatic renewal
        $taskName = "ScreenConnect SSL Renewal"
        # Use RemoteSigned instead of Bypass for better security
        $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy RemoteSigned -File `"$renewalScriptPath`" -Domain `"$Domain`" -Email `"$Email`""
        $trigger = New-ScheduledTaskTrigger -Daily -At "02:00"
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
        
        # Register task
        Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Force
        
        Write-Log "Certificate renewal task created successfully"
        return $true
        
    } catch {
        Write-Log "ERROR: Failed to create renewal task: $_" "ERROR"
        return $false
    }
}

# Function to test SSL configuration
function Test-SSLConfiguration {
    param([string]$Domain)
    
    Write-Log "Testing SSL configuration for $Domain..."
    
    try {
        # Test HTTPS connection
        $response = Invoke-WebRequest -Uri "https://$Domain" -UseBasicParsing -TimeoutSec 30 -ErrorAction SilentlyContinue
        
        if ($response.StatusCode -eq 200) {
            Write-Log "SSL configuration test passed for $Domain"
            return $true
        } else {
            Write-Log "WARNING: SSL test returned status code: $($response.StatusCode)" "WARN"
            return $false
        }
        
    } catch {
        Write-Log "ERROR: SSL configuration test failed: $_" "ERROR"
        return $false
    }
}

# Main execution logic
try {
    # Install Win-Acme if not already installed
    $wacsPath = Install-WinAcme
    if (-not $wacsPath) {
        exit 1
    }
    
    # Check if certificate is already valid
    if (-not $ForceRenewal -and (Test-CertificateValid -Domain $Domain)) {
        Write-Log "Certificate for $Domain is still valid"
        if ($InstallOnly) {
            Write-Log "Install-only mode: Skipping certificate renewal"
        } else {
            exit 0
        }
    }
    
    # Obtain SSL certificate
    if (-not $InstallOnly) {
        $certObtained = Get-SSLCertificate -Domain $Domain -Email $Email -WacsPath $wacsPath
        if (-not $certObtained) {
            exit 1
        }
    }
    
    # Configure IIS for SSL
    $iisConfigured = Configure-IISSSL -Domain $Domain
    if (-not $iisConfigured) {
        Write-Log "WARNING: IIS SSL configuration failed" "WARN"
    }
    
    # Configure ScreenConnect for SSL
    $screenconnectConfigured = Configure-ScreenConnectSSL -Domain $Domain
    if (-not $screenconnectConfigured) {
        Write-Log "WARNING: ScreenConnect SSL configuration failed" "WARN"
    }
    
    # Create renewal task
    $renewalTaskCreated = New-CertificateRenewalTask
    if (-not $renewalTaskCreated) {
        Write-Log "WARNING: Failed to create renewal task" "WARN"
    }
    
    # Test SSL configuration
    if (-not $DryRun) {
        Start-Sleep -Seconds 10 # Allow time for configuration to take effect
        $sslTestPassed = Test-SSLConfiguration -Domain $Domain
        if (-not $sslTestPassed) {
            Write-Log "WARNING: SSL configuration test failed" "WARN"
        }
    }
    
    Write-Log "SSL certificate management completed successfully"
    
} catch {
    Write-Log "ERROR: SSL certificate management failed: $_" "ERROR"
    exit 1
} 