# Oracle Cloud ScreenConnect Secrets Management
# Secure secrets management using Oracle Vault

param(
    [string]$Action = "check",
    [string]$SecretName,
    [string]$SecretValue,
    [switch]$UseVault = $true
)

# Function to check secrets status
function Test-SecretsStatus {
    Write-Host "=== Secrets Management Status ===" -ForegroundColor Green
    
    $secrets = @{
        "ScreenConnect License" = $false
        "Admin Password" = $false
        "Cloudflare API Token" = $false
        "Cloudflare Zone ID" = $false
    }
    
    # Check if secrets are provided
    if (-not [string]::IsNullOrEmpty($env:SCREENCONNECT_LICENSE)) {
        $secrets["ScreenConnect License"] = $true
    }
    
    if (-not [string]::IsNullOrEmpty($env:ADMIN_PASSWORD)) {
        $secrets["Admin Password"] = $true
    }
    
    if (-not [string]::IsNullOrEmpty($env:CLOUDFLARE_API_TOKEN)) {
        $secrets["Cloudflare API Token"] = $true
    }
    
    if (-not [string]::IsNullOrEmpty($env:CLOUDFLARE_ZONE_ID)) {
        $secrets["Cloudflare Zone ID"] = $true
    }
    
    Write-Host "`nSecret Status:" -ForegroundColor Cyan
    foreach ($secret in $secrets.GetEnumerator()) {
        $status = if ($secret.Value) { "✓ Configured" } else { "✗ Missing" }
        $color = if ($secret.Value) { "Green" } else { "Red" }
        Write-Host "  $($secret.Key): $status" -ForegroundColor $color
    }
    
    Write-Host "`nVault Usage: $(if ($UseVault) { 'Enabled' } else { 'Disabled' })" -ForegroundColor Cyan
    Write-Host "Recommendation: Use Oracle Vault for production deployments" -ForegroundColor Yellow
}

# Function to provide security recommendations
function Show-SecurityRecommendations {
    Write-Host "`n=== Security Recommendations ===" -ForegroundColor Green
    
    $recommendations = @(
        "✓ Use Oracle Vault for secrets storage (use_vault_for_secrets = true)",
        "✓ Store terraform.tfvars securely and never commit to version control",
        "✓ Use environment variables for sensitive data in CI/CD pipelines",
        "✓ Regularly rotate API tokens and passwords",
        "✓ Enable Cloudflare proxy for additional security",
        "✓ Restrict RDP access to specific IP addresses only",
        "✓ Use strong, unique passwords for all accounts",
        "✓ Enable audit logging for Oracle Cloud resources"
    )
    
    foreach ($rec in $recommendations) {
        Write-Host "  $rec" -ForegroundColor White
    }
    
    Write-Host "`n=== Environment Variables Setup ===" -ForegroundColor Green
    Write-Host "For CI/CD or secure environments, set these environment variables:" -ForegroundColor Cyan
    Write-Host "`n# PowerShell:" -ForegroundColor Yellow
    Write-Host '$env:SCREENCONNECT_LICENSE = "your-license-key"' -ForegroundColor Gray
    Write-Host '$env:ADMIN_PASSWORD = "your-admin-password"' -ForegroundColor Gray
    Write-Host '$env:CLOUDFLARE_API_TOKEN = "your-api-token"' -ForegroundColor Gray
    Write-Host '$env:CLOUDFLARE_ZONE_ID = "your-zone-id"' -ForegroundColor Gray
    
    Write-Host "`n# Bash/Linux:" -ForegroundColor Yellow
    Write-Host 'export SCREENCONNECT_LICENSE="your-license-key"' -ForegroundColor Gray
    Write-Host 'export ADMIN_PASSWORD="your-admin-password"' -ForegroundColor Gray
    Write-Host 'export CLOUDFLARE_API_TOKEN="your-api-token"' -ForegroundColor Gray
    Write-Host 'export CLOUDFLARE_ZONE_ID="your-zone-id"' -ForegroundColor Gray
}

# Function to generate secure Terraform variables
function Write-SecureTerraformVars {
    param([string]$OutputFile)
    
    $content = @"
# Oracle Cloud ScreenConnect - Secure Configuration
# Generated on: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
# WARNING: This file contains sensitive information - keep secure!

# Secrets Management Configuration
use_vault_for_secrets = $UseVault

# Oracle Cloud Configuration
tenancy_ocid = "ocid1.tenancy.oc1..your-tenancy-ocid"
compartment_ocid = "ocid1.compartment.oc1..your-compartment-ocid"
user_ocid = "ocid1.user.oc1..your-user-ocid"
fingerprint = "your-fingerprint"
private_key_path = "~/.oci/oci_api_key.pem"
region = "us-ashburn-1"

# Project Configuration
project_name = "screenconnect"
environment = "production"

# Network Configuration
vcn_cidr_block = "10.0.0.0/16"
subnet_cidr_block = "10.0.1.0/24"

# RDP Access Configuration
enable_rdp_access = true
auto_detect_home_ip = true

# Your home IP addresses (use get-home-ips.ps1 to detect)
additional_rdp_ips = [
  # Add your IPs here
]

# Compute Configuration
instance_shape = "VM.Standard.A1.Flex"
ocpus = 1
memory_in_gbs = 6

# ScreenConnect Configuration
# SECURITY: These values will be stored in Oracle Vault if use_vault_for_secrets = true
screenconnect_license_key = "your-screenconnect-license-key"
admin_password = "your-admin-password"

# Domain Configuration
primary_domain = "help.yourdomain.com"
relay_domain = "relay.yourdomain.com"

# Cloudflare Configuration
# SECURITY: These values will be stored in Oracle Vault if use_vault_for_secrets = true
cloudflare_api_token = "your-cloudflare-api-token"
cloudflare_zone_id = "your-cloudflare-zone-id"
enable_cloudflare_proxy = true
cloudflare_ssl_mode = "full"

# Backup Configuration
backup_bucket_name = "screenconnect-backups"
backup_retention = 5

# Tags
tags = {
  Project     = "screenconnect"
  Environment = "production"
  Purpose     = "remote-support"
  Owner       = "your-name"
}
"@

    $content | Out-File -FilePath $OutputFile -Encoding UTF8
    Write-Host "Secure Terraform variables written to: $OutputFile" -ForegroundColor Green
}

# Main execution
Write-Host "=== Oracle Cloud ScreenConnect Secrets Management ===" -ForegroundColor Green
Write-Host "Secure secrets management for production deployments" -ForegroundColor Yellow

switch ($Action.ToLower()) {
    "check" {
        Test-SecretsStatus
        Show-SecurityRecommendations
    }
    
    "generate" {
        Write-Host "`nGenerating secure configuration..." -ForegroundColor Cyan
        $outputFile = "terraform.tfvars.secure"
        Write-SecureTerraformVars -OutputFile $outputFile
        
        Write-Host "`nNext steps:" -ForegroundColor Green
        Write-Host "1. Review the generated file: $outputFile" -ForegroundColor White
        Write-Host "2. Replace placeholder values with your actual secrets" -ForegroundColor White
        Write-Host "3. Copy to terraform.tfvars and run terraform plan" -ForegroundColor White
    }
    
    default {
        Write-Host "`nUsage:" -ForegroundColor Green
        Write-Host "  .\manage-secrets.ps1 -Action check" -ForegroundColor White
        Write-Host "  .\manage-secrets.ps1 -Action generate" -ForegroundColor White
        Write-Host "`nActions:" -ForegroundColor Green
        Write-Host "  check     - Check current secrets status and show recommendations" -ForegroundColor White
        Write-Host "  generate  - Generate secure terraform.tfvars template" -ForegroundColor White
    }
}

Write-Host "`n=== Security Note ===" -ForegroundColor Yellow
Write-Host "Always use Oracle Vault for production deployments to ensure secrets are" -ForegroundColor White
Write-Host "properly encrypted and managed. Never commit secrets to version control!" -ForegroundColor White 