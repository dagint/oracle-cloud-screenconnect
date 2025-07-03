# Get Home IP Addresses for Oracle Cloud ScreenConnect RDP Access
# Designed for UniFi Dream Machine SE with dual WAN (active/active)

param(
    [string]$UnifiController = "192.168.1.1",
    [string]$UnifiUsername = "admin",
    [string]$UnifiPassword,
    [switch]$UsePublicIPDetection = $true,
    [string[]]$AdditionalIPs = @(),
    [string]$OutputFile = "home-ips.txt",
    [switch]$GenerateTerraformVars = $false
)

# Function to get public IP from various services
function Get-PublicIP {
    param([string]$Service)
    
    try {
        switch ($Service) {
            "ipify" { 
                $response = Invoke-RestMethod -Uri "https://api.ipify.org" -TimeoutSec 10
                return $response
            }
            "icanhazip" { 
                $response = Invoke-RestMethod -Uri "https://icanhazip.com" -TimeoutSec 10
                return $response.Trim()
            }
            "ifconfig" { 
                $response = Invoke-RestMethod -Uri "https://ifconfig.me" -TimeoutSec 10
                return $response.Trim()
            }
            default { 
                $response = Invoke-RestMethod -Uri "https://api.ipify.org" -TimeoutSec 10
                return $response
            }
        }
    }
    catch {
        Write-Warning "Failed to get IP from $Service`: $($_.Exception.Message)"
        return $null
    }
}

# Function to get UniFi WAN IPs
function Get-UnifiWANIPs {
    param(
        [string]$Controller,
        [string]$Username,
        [string]$Password
    )
    
    try {
        # Note: This requires UniFi API access
        # You may need to adjust based on your UniFi controller version
        Write-Host "Attempting to get WAN IPs from UniFi controller at $Controller..."
        
        # This is a placeholder - you'll need to implement the actual UniFi API call
        # based on your controller version and API access
        Write-Warning "UniFi API integration not implemented. Please manually specify WAN IPs."
        return @()
    }
    catch {
        Write-Warning "Failed to get UniFi WAN IPs: $($_.Exception.Message)"
        return @()
    }
}

# Function to validate IP address
function Test-ValidIP {
    param([string]$IP)
    
    try {
        $null = [System.Net.IPAddress]::Parse($IP)
        return $true
    }
    catch {
        return $false
    }
}

# Function to generate Terraform variables
function Write-TerraformVars {
    param(
        [string[]]$IPs,
        [string]$OutputFile
    )
    
    $content = @"
# Auto-generated Terraform variables for RDP access
# Generated on: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

# RDP Access Configuration
enable_rdp_access = true
auto_detect_home_ip = false  # Set to false since we're manually specifying IPs

# Your home IP addresses (CIDR notation)
additional_rdp_ips = [
"@

    foreach ($ip in $IPs) {
        if (Test-ValidIP $ip) {
            $content += "`n  `"$ip/32`","
        }
    }
    
    $content += @"
]

# Other required variables (fill these in manually)
tenancy_ocid = "ocid1.tenancy.oc1..your-tenancy-ocid"
compartment_ocid = "ocid1.compartment.oc1..your-compartment-ocid"
user_ocid = "ocid1.user.oc1..your-user-ocid"
fingerprint = "your-fingerprint"
private_key_path = "~/.oci/oci_api_key.pem"
region = "us-ashburn-1"

# ScreenConnect Configuration
screenconnect_license_key = "your-license-key"
admin_password = "your-admin-password"

# Cloudflare Configuration
cloudflare_api_token = "your-cloudflare-api-token"
cloudflare_zone_id = "your-zone-id"
"@

    $content | Out-File -FilePath $OutputFile -Encoding UTF8
    Write-Host "Terraform variables written to: $OutputFile"
}

# Main execution
Write-Host "=== Home IP Detection for Oracle Cloud ScreenConnect ===" -ForegroundColor Green
Write-Host "Detecting your home IP addresses for RDP access..." -ForegroundColor Yellow

$detectedIPs = @()

# Get public IPs from multiple services
if ($UsePublicIPDetection) {
    Write-Host "`nDetecting public IP addresses..." -ForegroundColor Cyan
    
    $services = @("ipify", "icanhazip", "ifconfig")
    $publicIPs = @()
    
    foreach ($service in $services) {
        $ip = Get-PublicIP -Service $service
        if ($ip -and (Test-ValidIP $ip)) {
            $publicIPs += $ip
            Write-Host "  $service`: $ip" -ForegroundColor Green
        }
    }
    
    # Remove duplicates and add to detected IPs
    $uniquePublicIPs = $publicIPs | Sort-Object -Unique
    $detectedIPs += $uniquePublicIPs
    
    Write-Host "`nUnique public IPs detected: $($uniquePublicIPs.Count)" -ForegroundColor Green
    foreach ($ip in $uniquePublicIPs) {
        Write-Host "  $ip" -ForegroundColor Green
    }
}

# Get UniFi WAN IPs if credentials provided
if ($UnifiPassword) {
    Write-Host "`nAttempting to get UniFi WAN IPs..." -ForegroundColor Cyan
    $unifiIPs = Get-UnifiWANIPs -Controller $UnifiController -Username $UnifiUsername -Password $UnifiPassword
    $detectedIPs += $unifiIPs
}

# Add manually specified IPs
if ($AdditionalIPs.Count -gt 0) {
    Write-Host "`nAdding manually specified IPs..." -ForegroundColor Cyan
    foreach ($ip in $AdditionalIPs) {
        if (Test-ValidIP $ip) {
            $detectedIPs += $ip
            Write-Host "  $ip" -ForegroundColor Green
        } else {
            Write-Warning "Invalid IP address: $ip"
        }
    }
}

# Remove duplicates and sort
$finalIPs = $detectedIPs | Sort-Object -Unique

# Output results
Write-Host "`n=== Final Results ===" -ForegroundColor Green
Write-Host "Total unique IP addresses: $($finalIPs.Count)" -ForegroundColor Yellow

if ($finalIPs.Count -eq 0) {
    Write-Host "No valid IP addresses detected!" -ForegroundColor Red
    Write-Host "Please check your internet connection or manually specify IPs using -AdditionalIPs parameter." -ForegroundColor Yellow
    exit 1
}

Write-Host "`nIP addresses for RDP access:" -ForegroundColor Cyan
foreach ($ip in $finalIPs) {
    Write-Host "  $ip/32" -ForegroundColor White
}

# Save to file
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$fileContent = @"
# Home IP Addresses for Oracle Cloud ScreenConnect RDP Access
# Generated on: $timestamp
# Total IPs: $($finalIPs.Count)

# IP Addresses (CIDR notation for Terraform)
"@

foreach ($ip in $finalIPs) {
    $fileContent += "`n$ip/32"
}

$fileContent += @"

# Usage in terraform.tfvars:
# additional_rdp_ips = [
"@

foreach ($ip in $finalIPs) {
    $fileContent += "`n#   `"$ip/32`","
}

$fileContent += @"
# ]

# Notes:
# - These IPs will be allowed to RDP to your ScreenConnect instance
# - Update this file whenever your IP addresses change
# - Consider using a dynamic DNS service for more stable access
"@

$fileContent | Out-File -FilePath $OutputFile -Encoding UTF8
Write-Host "`nResults saved to: $OutputFile" -ForegroundColor Green

# Generate Terraform variables if requested
if ($GenerateTerraformVars) {
    $tfVarsFile = "terraform.tfvars.generated"
    Write-TerraformVars -IPs $finalIPs -OutputFile $tfVarsFile
}

Write-Host "`n=== Next Steps ===" -ForegroundColor Green
Write-Host "1. Review the detected IP addresses above" -ForegroundColor White
Write-Host "2. Add them to your terraform.tfvars file:" -ForegroundColor White
Write-Host "   additional_rdp_ips = [`"$($finalIPs[0])/32`", `"$($finalIPs[1])/32`"]" -ForegroundColor Cyan
Write-Host "3. Run: terraform plan" -ForegroundColor White
Write-Host "4. Run: terraform apply" -ForegroundColor White
Write-Host "`nNote: Update these IPs whenever your WAN IPs change!" -ForegroundColor Yellow 