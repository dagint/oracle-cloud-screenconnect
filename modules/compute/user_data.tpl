# PowerShell script to set up ScreenConnect on Windows Server 2022

# Set execution policy
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force

# Install Chocolatey
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install required software
choco install -y git
choco install -y 7zip

# Create directories
New-Item -Path "C:\scripts" -ItemType Directory -Force
New-Item -Path "C:\tools" -ItemType Directory -Force
New-Item -Path "C:\certificates" -ItemType Directory -Force
New-Item -Path "C:\screenconnect_backups" -ItemType Directory -Force

# Download and install ScreenConnect
$screenconnectUrl = "https://download.screenconnect.com/24.1.0.8811/ScreenConnect_24.1.0.8811.msi"
$screenconnectPath = "C:\temp\ScreenConnect.msi"

if (-not (Test-Path "C:\temp")) {
    New-Item -Path "C:\temp" -ItemType Directory -Force
}

try {
    Write-Host "Downloading ScreenConnect from $screenconnectUrl"
    Invoke-WebRequest -Uri $screenconnectUrl -OutFile $screenconnectPath -UseBasicParsing
    Write-Host "ScreenConnect downloaded successfully"
    
    Write-Host "Installing ScreenConnect..."
    $process = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i", $screenconnectPath, "/quiet", "/norestart" -Wait -PassThru
    if ($process.ExitCode -eq 0) {
        Write-Host "ScreenConnect installed successfully"
    } else {
        Write-Error "ScreenConnect installation failed with exit code: $($process.ExitCode)"
    }
} catch {
    Write-Error "Failed to download or install ScreenConnect: $($_.Exception.Message)"
    throw
}

# Configure ScreenConnect
$configPath = "C:\Program Files (x86)\ScreenConnect\App_Data\config.json"
if (Test-Path $configPath) {
    $config = Get-Content -Path $configPath | ConvertFrom-Json
    $config.LicenseKey = "${screenconnect_license_key}"
    $config.AdminPassword = "${admin_password}"
    
    # Configure web UI settings for primary domain
    $config.WebServerSettings = @{
        Port = 443
        UseSSL = $true
        CertificatePath = ""
        CertificatePassword = ""
        BindAddress = "0.0.0.0"
        RedirectHttpToHttps = $true
        HttpPort = 80
        HttpsPort = 443
        HostName = "${primary_domain}"
    }
    
    # Configure relay settings for relay domain
    $config.RelayServerSettings = @{
        Port = 8041
        UseSSL = $false
        BindAddress = "0.0.0.0"
        HostName = "${relay_domain}"
    }
    
    # Configure domain settings
    $config.DomainSettings = @{
        PrimaryDomain = "${primary_domain}"
        RelayDomain = "${relay_domain}"
        WebServerHostName = "${primary_domain}"
        RelayServerHostName = "${relay_domain}"
    }
    
    $config | ConvertTo-Json -Depth 10 | Set-Content -Path $configPath
    
    Write-Host "ScreenConnect configuration updated with domain and port settings"
    Write-Host "  - Web UI: https://${primary_domain} (port 443)" -ForegroundColor Green
    Write-Host "  - Relay: ${relay_domain}:8041" -ForegroundColor Green
}

# Set up scheduled tasks for maintenance
$maintenanceScript = @"
# ScreenConnect Maintenance Script
powershell.exe -ExecutionPolicy Bypass -File "C:\scripts\maintenance.ps1" -Action "all"
"@

$maintenanceScript | Out-File -FilePath "C:\scripts\run-maintenance.ps1" -Encoding UTF8

# Create scheduled task for monthly maintenance
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"C:\scripts\run-maintenance.ps1`""
$trigger = New-ScheduledTaskTrigger -Monthly -Day 1 -At "02:00"
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

Register-ScheduledTask -TaskName "ScreenConnect Monthly Maintenance" -Action $action -Trigger $trigger -Settings $settings -Force

# Configure Windows Firewall for ScreenConnect
# Web UI - HTTP (for redirect to HTTPS)
New-NetFirewallRule -DisplayName "ScreenConnect Web UI HTTP" -Direction Inbound -Protocol TCP -LocalPort 80 -Action Allow
# Web UI - HTTPS
New-NetFirewallRule -DisplayName "ScreenConnect Web UI HTTPS" -Direction Inbound -Protocol TCP -LocalPort 443 -Action Allow
# Relay - Port 8041 only
New-NetFirewallRule -DisplayName "ScreenConnect Relay" -Direction Inbound -Protocol TCP -LocalPort 8041 -Action Allow

# Enable Windows Update
Set-Service -Name wuauserv -StartupType Automatic
Start-Service -Name wuauserv

# Configure Windows Defender exclusions for ScreenConnect
Add-MpPreference -ExclusionPath "C:\Program Files (x86)\ScreenConnect\*"
Add-MpPreference -ExclusionPath "C:\ProgramData\ScreenConnect\*"

# Configure HTTP to HTTPS redirect
Write-Host "Configuring HTTP to HTTPS redirect..."
try {
    # Copy the SSL redirect script to the instance
    $sslRedirectScript = @"
# ScreenConnect HTTP to HTTPS Redirect Configuration Script
# This script configures IIS to redirect HTTP traffic to HTTPS for ScreenConnect

param(
    [string]`$Domain = "${primary_domain}",
    [int]`$HttpPort = 80,
    [int]`$HttpsPort = 443
)

Write-Host "=== ScreenConnect SSL Redirect Configuration ===" -ForegroundColor Green
Write-Host "Domain: `$Domain" -ForegroundColor Yellow
Write-Host "HTTP Port: `$HttpPort" -ForegroundColor Yellow
Write-Host "HTTPS Port: `$HttpsPort" -ForegroundColor Yellow
Write-Host ""

# Check if running as administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "This script must be run as Administrator"
    exit 1
}

try {
    # Install IIS URL Rewrite module if not present
    Write-Host "Checking for IIS URL Rewrite module..." -ForegroundColor Yellow
    `$urlRewrite = Get-WindowsFeature -Name "Web-Url-Auth"
    if (-not `$urlRewrite.Installed) {
        Write-Host "Installing IIS URL Rewrite module..." -ForegroundColor Yellow
        Install-WindowsFeature -Name "Web-Url-Auth" -IncludeManagementTools
    } else {
        Write-Host "✓ IIS URL Rewrite module is already installed" -ForegroundColor Green
    }

    # Install IIS URL Rewrite 2.1 if not present
    `$urlRewritePath = "C:\Program Files\IIS\UrlRewrite\urlrewrite.dll"
    if (-not (Test-Path `$urlRewritePath)) {
        Write-Host "Installing IIS URL Rewrite 2.1..." -ForegroundColor Yellow
        `$urlRewriteUrl = "https://download.microsoft.com/download/1/2/8/128E2E22-C1B9-44A4-BE2A-E5850FB3ED6B/urlrewrite2.exe"
        `$urlRewriteInstaller = "C:\temp\urlrewrite2.exe"
        
        if (-not (Test-Path "C:\temp")) {
            New-Item -Path "C:\temp" -ItemType Directory -Force
        }
        
        Invoke-WebRequest -Uri `$urlRewriteUrl -OutFile `$urlRewriteInstaller -UseBasicParsing
        Start-Process -FilePath `$urlRewriteInstaller -ArgumentList "/quiet" -Wait
        Remove-Item `$urlRewriteInstaller -Force
    } else {
        Write-Host "✓ IIS URL Rewrite 2.1 is already installed" -ForegroundColor Green
    }

    # Create web.config for HTTP to HTTPS redirect
    Write-Host "Creating web.config for HTTP to HTTPS redirect..." -ForegroundColor Yellow
    `$webConfigPath = "C:\inetpub\wwwroot\web.config"
    
    `$webConfigContent = @"
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <system.webServer>
        <rewrite>
            <rules>
                <rule name="HTTP to HTTPS redirect" stopProcessing="true">
                    <match url="(.*)" />
                    <conditions>
                        <add input="{HTTPS}" pattern="off" ignoreCase="true" />
                        <add input="{HTTP_HOST}" pattern="^`$Domain`$" ignoreCase="true" />
                    </conditions>
                    <action type="Redirect" url="https://`$Domain{REQUEST_URI}" redirectType="Permanent" />
                </rule>
            </rules>
        </rewrite>
    </system.webServer>
</configuration>
"@

    `$webConfigContent | Out-File -FilePath `$webConfigPath -Encoding UTF8
    Write-Host "✓ Web.config created successfully" -ForegroundColor Green

    # Configure ScreenConnect web.config for SSL redirect
    `$screenconnectWebConfigPath = "C:\Program Files (x86)\ScreenConnect\Web.config"
    if (Test-Path `$screenconnectWebConfigPath) {
        Write-Host "Updating ScreenConnect Web.config for SSL redirect..." -ForegroundColor Yellow
        
        # Read existing web.config
        `$xml = [xml](Get-Content `$screenconnectWebConfigPath)
        
        # Check if rewrite section exists
        `$rewriteNode = `$xml.SelectSingleNode("//system.webServer/rewrite")
        if (-not `$rewriteNode) {
            # Create rewrite section
            `$systemWebServer = `$xml.SelectSingleNode("//system.webServer")
            if (-not `$systemWebServer) {
                `$systemWebServer = `$xml.CreateElement("system.webServer")
                `$xml.configuration.AppendChild(`$systemWebServer)
            }
            `$rewriteNode = `$xml.CreateElement("rewrite")
            `$systemWebServer.AppendChild(`$rewriteNode)
        }
        
        # Check if rules section exists
        `$rulesNode = `$rewriteNode.SelectSingleNode("rules")
        if (-not `$rulesNode) {
            `$rulesNode = `$xml.CreateElement("rules")
            `$rewriteNode.AppendChild(`$rulesNode)
        }
        
        # Add HTTP to HTTPS redirect rule
        `$ruleNode = `$xml.CreateElement("rule")
        `$ruleNode.SetAttribute("name", "HTTP to HTTPS redirect")
        `$ruleNode.SetAttribute("stopProcessing", "true")
        
        `$matchNode = `$xml.CreateElement("match")
        `$matchNode.SetAttribute("url", "(.*)")
        `$ruleNode.AppendChild(`$matchNode)
        
        `$conditionsNode = `$xml.CreateElement("conditions")
        
        `$condition1 = `$xml.CreateElement("add")
        `$condition1.SetAttribute("input", "{HTTPS}")
        `$condition1.SetAttribute("pattern", "off")
        `$condition1.SetAttribute("ignoreCase", "true")
        `$conditionsNode.AppendChild(`$condition1)
        
        `$condition2 = `$xml.CreateElement("add")
        `$condition2.SetAttribute("input", "{HTTP_HOST}")
        `$condition2.SetAttribute("pattern", "^`$Domain`$")
        `$condition2.SetAttribute("ignoreCase", "true")
        `$conditionsNode.AppendChild(`$condition2)
        
        `$ruleNode.AppendChild(`$conditionsNode)
        
        `$actionNode = `$xml.CreateElement("action")
        `$actionNode.SetAttribute("type", "Redirect")
        `$actionNode.SetAttribute("url", "https://`$Domain{REQUEST_URI}")
        `$actionNode.SetAttribute("redirectType", "Permanent")
        `$ruleNode.AppendChild(`$actionNode)
        
        `$rulesNode.AppendChild(`$ruleNode)
        
        # Save updated web.config
        `$xml.Save(`$screenconnectWebConfigPath)
        Write-Host "✓ ScreenConnect Web.config updated successfully" -ForegroundColor Green
    }

    # Restart IIS to apply changes
    Write-Host "Restarting IIS to apply changes..." -ForegroundColor Yellow
    Restart-Service -Name "W3SVC" -Force
    Write-Host "✓ IIS restarted successfully" -ForegroundColor Green

    Write-Host ""
    Write-Host "=== Configuration Complete ===" -ForegroundColor Green
    Write-Host "ScreenConnect is now configured with:" -ForegroundColor Yellow
    Write-Host "  - Web UI: https://`$Domain (port 443)" -ForegroundColor White
    Write-Host "  - Relay: `$Domain (port 8041)" -ForegroundColor White
    Write-Host "  - HTTP redirect: http://`$Domain → https://`$Domain" -ForegroundColor White

} catch {
    Write-Error "Configuration failed: `$(`$_.Exception.Message)"
    exit 1
}
"@

    $sslRedirectScript | Out-File -FilePath "C:\scripts\configure-ssl-redirect.ps1" -Encoding UTF8
    
    # Run the SSL redirect configuration
    powershell.exe -ExecutionPolicy Bypass -File "C:\scripts\configure-ssl-redirect.ps1" -Domain "${primary_domain}"
    Write-Host "✓ HTTP to HTTPS redirect configured successfully for ${primary_domain}" -ForegroundColor Green
} catch {
    Write-Warning "Failed to configure HTTP to HTTPS redirect: $($_.Exception.Message)"
}

Write-Host "ScreenConnect setup completed successfully" 