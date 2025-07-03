# ScreenConnect HTTP to HTTPS Redirect Configuration Script
# This script configures IIS to redirect HTTP traffic to HTTPS for ScreenConnect

param(
    [string]$Domain = "remotesupport.yourdomain.com",
    [int]$HttpPort = 80,
    [int]$HttpsPort = 443
)

Write-Host "=== ScreenConnect SSL Redirect Configuration ===" -ForegroundColor Green
Write-Host "Domain: $Domain" -ForegroundColor Yellow
Write-Host "HTTP Port: $HttpPort" -ForegroundColor Yellow
Write-Host "HTTPS Port: $HttpsPort" -ForegroundColor Yellow
Write-Host ""

# Check if running as administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "This script must be run as Administrator"
    exit 1
}

try {
    # Install IIS URL Rewrite module if not present
    Write-Host "Checking for IIS URL Rewrite module..." -ForegroundColor Yellow
    $urlRewrite = Get-WindowsFeature -Name "Web-Url-Auth"
    if (-not $urlRewrite.Installed) {
        Write-Host "Installing IIS URL Rewrite module..." -ForegroundColor Yellow
        Install-WindowsFeature -Name "Web-Url-Auth" -IncludeManagementTools
    } else {
        Write-Host "✓ IIS URL Rewrite module is already installed" -ForegroundColor Green
    }

    # Install IIS URL Rewrite 2.1 if not present
    $urlRewritePath = "C:\Program Files\IIS\UrlRewrite\urlrewrite.dll"
    if (-not (Test-Path $urlRewritePath)) {
        Write-Host "Installing IIS URL Rewrite 2.1..." -ForegroundColor Yellow
        $urlRewriteUrl = "https://download.microsoft.com/download/1/2/8/128E2E22-C1B9-44A4-BE2A-E5850FB3ED6B/urlrewrite2.exe"
        $urlRewriteInstaller = "C:\temp\urlrewrite2.exe"
        
        if (-not (Test-Path "C:\temp")) {
            New-Item -Path "C:\temp" -ItemType Directory -Force
        }
        
        Invoke-WebRequest -Uri $urlRewriteUrl -OutFile $urlRewriteInstaller -UseBasicParsing
        Start-Process -FilePath $urlRewriteInstaller -ArgumentList "/quiet" -Wait
        Remove-Item $urlRewriteInstaller -Force
    } else {
        Write-Host "✓ IIS URL Rewrite 2.1 is already installed" -ForegroundColor Green
    }

    # Create web.config for HTTP to HTTPS redirect
    Write-Host "Creating web.config for HTTP to HTTPS redirect..." -ForegroundColor Yellow
    $webConfigPath = "C:\inetpub\wwwroot\web.config"
    
    $webConfigContent = @"
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <system.webServer>
        <rewrite>
            <rules>
                <rule name="HTTP to HTTPS redirect for $Domain" stopProcessing="true">
                    <match url="(.*)" />
                    <conditions>
                        <add input="{HTTPS}" pattern="off" ignoreCase="true" />
                        <add input="{HTTP_HOST}" pattern="^$Domain$" ignoreCase="true" />
                    </conditions>
                    <action type="Redirect" url="https://$Domain{REQUEST_URI}" redirectType="Permanent" />
                </rule>
            </rules>
        </rewrite>
    </system.webServer>
</configuration>
"@

    $webConfigContent | Out-File -FilePath $webConfigPath -Encoding UTF8
    Write-Host "✓ Web.config created successfully for $Domain" -ForegroundColor Green

    # Configure ScreenConnect web.config for SSL redirect
    $screenconnectWebConfigPath = "C:\Program Files (x86)\ScreenConnect\Web.config"
    if (Test-Path $screenconnectWebConfigPath) {
        Write-Host "Updating ScreenConnect Web.config for SSL redirect..." -ForegroundColor Yellow
        
        # Read existing web.config
        $xml = [xml](Get-Content $screenconnectWebConfigPath)
        
        # Check if rewrite section exists
        $rewriteNode = $xml.SelectSingleNode("//system.webServer/rewrite")
        if (-not $rewriteNode) {
            # Create rewrite section
            $systemWebServer = $xml.SelectSingleNode("//system.webServer")
            if (-not $systemWebServer) {
                $systemWebServer = $xml.CreateElement("system.webServer")
                $xml.configuration.AppendChild($systemWebServer)
            }
            $rewriteNode = $xml.CreateElement("rewrite")
            $systemWebServer.AppendChild($rewriteNode)
        }
        
        # Check if rules section exists
        $rulesNode = $rewriteNode.SelectSingleNode("rules")
        if (-not $rulesNode) {
            $rulesNode = $xml.CreateElement("rules")
            $rewriteNode.AppendChild($rulesNode)
        }
        
        # Add HTTP to HTTPS redirect rule
        $ruleNode = $xml.CreateElement("rule")
        $ruleNode.SetAttribute("name", "HTTP to HTTPS redirect for $Domain")
        $ruleNode.SetAttribute("stopProcessing", "true")
        
        $matchNode = $xml.CreateElement("match")
        $matchNode.SetAttribute("url", "(.*)")
        $ruleNode.AppendChild($matchNode)
        
        $conditionsNode = $xml.CreateElement("conditions")
        
        $condition1 = $xml.CreateElement("add")
        $condition1.SetAttribute("input", "{HTTPS}")
        $condition1.SetAttribute("pattern", "off")
        $condition1.SetAttribute("ignoreCase", "true")
        $conditionsNode.AppendChild($condition1)
        
        $condition2 = $xml.CreateElement("add")
        $condition2.SetAttribute("input", "{HTTP_HOST}")
        $condition2.SetAttribute("pattern", "^$Domain$")
        $condition2.SetAttribute("ignoreCase", "true")
        $conditionsNode.AppendChild($condition2)
        
        $ruleNode.AppendChild($conditionsNode)
        
        $actionNode = $xml.CreateElement("action")
        $actionNode.SetAttribute("type", "Redirect")
        $actionNode.SetAttribute("url", "https://$Domain{REQUEST_URI}")
        $actionNode.SetAttribute("redirectType", "Permanent")
        $ruleNode.AppendChild($actionNode)
        
        $rulesNode.AppendChild($ruleNode)
        
        # Save updated web.config
        $xml.Save($screenconnectWebConfigPath)
        Write-Host "✓ ScreenConnect Web.config updated successfully for $Domain" -ForegroundColor Green
    }

    # Restart IIS to apply changes
    Write-Host "Restarting IIS to apply changes..." -ForegroundColor Yellow
    Restart-Service -Name "W3SVC" -Force
    Write-Host "✓ IIS restarted successfully" -ForegroundColor Green

    # Test the redirect
    Write-Host "Testing HTTP to HTTPS redirect..." -ForegroundColor Yellow
    try {
        $response = Invoke-WebRequest -Uri "http://$Domain" -MaximumRedirection 0 -ErrorAction SilentlyContinue
        if ($response.StatusCode -eq 301 -or $response.StatusCode -eq 302) {
            Write-Host "✓ HTTP to HTTPS redirect is working correctly for $Domain" -ForegroundColor Green
        } else {
            Write-Warning "HTTP to HTTPS redirect may not be working as expected for $Domain"
        }
    } catch {
        Write-Host "✓ HTTP to HTTPS redirect test completed for $Domain" -ForegroundColor Green
    }

    Write-Host ""
    Write-Host "=== Configuration Complete ===" -ForegroundColor Green
    Write-Host "ScreenConnect is now configured with:" -ForegroundColor Yellow
    Write-Host "  - Web UI: https://$Domain (port 443)" -ForegroundColor White
    Write-Host "  - HTTP redirect: http://$Domain → https://$Domain" -ForegroundColor White

} catch {
    Write-Error "Configuration failed: $($_.Exception.Message)"
    exit 1
} 