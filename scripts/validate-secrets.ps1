# Secrets Validation Script
# This script validates that sensitive configuration is properly set up

param(
    [string]$Environment = "production",
    [switch]$Verbose
)

Write-Host "=== Secrets Validation ===" -ForegroundColor Green
Write-Host "Environment: $Environment" -ForegroundColor Yellow
Write-Host ""

# Security: Validate script is running from expected location
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$expectedRoot = Split-Path -Parent $scriptDir
if (-not (Test-Path (Join-Path $expectedRoot "VERSION"))) {
    Write-Error "Script must be run from the repository root directory"
    exit 1
}

$configPath = "environments/$Environment/terraform.tfvars"
$errors = @()
$warnings = @()
$info = @()

try {
    # Check if configuration file exists
    if (-not (Test-Path $configPath)) {
        $errors += "Configuration file not found: $configPath"
        Write-Host "Run: .\scripts\setup-secure-config.ps1 -Environment $Environment" -ForegroundColor Yellow
        exit 1
    }
    
    Write-Host "Validating configuration file: $configPath" -ForegroundColor Yellow
    
    # Read configuration file
    $configContent = Get-Content $configPath -Raw
    
    # Define required variables and their validation patterns
    $requiredVariables = @{
        # Oracle Cloud Configuration
        "tenancy_ocid" = @{
            Pattern = '^ocid1\.tenancy\.oc1\..*'
            Description = "Oracle Cloud tenancy OCID"
            Example = "ocid1.tenancy.oc1..your-tenancy-ocid"
        }
        "compartment_ocid" = @{
            Pattern = '^ocid1\.compartment\.oc1\..*'
            Description = "Oracle Cloud compartment OCID"
            Example = "ocid1.compartment.oc1..your-compartment-ocid"
        }
        "user_ocid" = @{
            Pattern = '^ocid1\.user\.oc1\..*'
            Description = "Oracle Cloud user OCID"
            Example = "ocid1.user.oc1..your-user-ocid"
        }
        "fingerprint" = @{
            Pattern = '^[a-f0-9:]+$'
            Description = "Oracle Cloud API key fingerprint"
            Example = "xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx"
        }
        "private_key_path" = @{
            Pattern = '^[^"]+\.pem$'
            Description = "Path to Oracle Cloud private key"
            Example = "~/.oci/oci_api_key.pem"
        }
        "region" = @{
            Pattern = '^[a-z-]+-\d+$'
            Description = "Oracle Cloud region"
            Example = "us-ashburn-1"
        }
        
        # SSH Configuration
        "ssh_public_key_path" = @{
            Pattern = '^[^"]+\.pub$'
            Description = "Path to SSH public key"
            Example = "~/.ssh/id_rsa.pub"
        }
        
        # ScreenConnect Configuration
        "screenconnect_license_key" = @{
            Pattern = '^[a-zA-Z0-9-]+$'
            Description = "ScreenConnect license key"
            Example = "your-screenconnect-license-key"
        }
        "admin_password" = @{
            Pattern = '^[^"]{8,}$'
            Description = "Admin password (minimum 8 characters)"
            Example = "your-secure-admin-password"
        }
        
        # Domain Configuration
        "primary_domain" = @{
            Pattern = '^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
            Description = "Primary domain for ScreenConnect web UI"
            Example = "help.yourdomain.com"
        }
        "relay_domain" = @{
            Pattern = '^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
            Description = "Relay domain for ScreenConnect"
            Example = "relay.yourdomain.com"
        }
        
        # Cloudflare Configuration
        "cloudflare_api_token" = @{
            Pattern = '^[a-zA-Z0-9_-]+$'
            Description = "Cloudflare API token"
            Example = "your-cloudflare-api-token"
        }
        "cloudflare_zone_id" = @{
            Pattern = '^[a-f0-9]{32}$'
            Description = "Cloudflare zone ID"
            Example = "your-cloudflare-zone-id"
        }
    }
    
    # Validate each required variable
    foreach ($variable in $requiredVariables.Keys) {
        $pattern = $requiredVariables[$variable].Pattern
        $description = $requiredVariables[$variable].Description
        $example = $requiredVariables[$variable].Example
        
        # Check if variable is defined
        if ($configContent -match "$variable\s*=\s*`"([^`"]*)`"") {
            $value = $matches[1]
            
            # Check if value is placeholder
            if ($value -match "your-.*" -or $value -match "example.*" -or $value -eq "") {
                $errors += "$description ($variable) is not configured"
                if ($Verbose) {
                    $info += "Expected format: $variable = `"$example`""
                }
            }
            # Validate format
            elseif ($value -notmatch $pattern) {
                $warnings += "$description ($variable) format may be incorrect"
                if ($Verbose) {
                    $info += "Expected format: $variable = `"$example`""
                }
            }
            else {
                $info += "✓ $description configured"
            }
        }
        else {
            $errors += "$description ($variable) is missing"
            if ($Verbose) {
                $info += "Add: $variable = `"$example`""
            }
        }
    }
    
    # Check for security best practices
    Write-Host "Checking security configuration..." -ForegroundColor Yellow
    
    # Check if Oracle Vault is enabled
    if ($configContent -match 'use_vault_for_secrets\s*=\s*true') {
        $info += "✓ Oracle Vault integration enabled"
    }
    else {
        $warnings += "Oracle Vault integration not enabled (use_vault_for_secrets = true)"
    }
    
    # Check RDP access configuration
    if ($configContent -match 'enable_rdp_access\s*=\s*true') {
        if ($configContent -match 'additional_rdp_ips\s*=\s*\[[^\]]*203\.0\.113\.1[^\]]*\]') {
            $warnings += "RDP access includes example IP (203.0.113.1) - replace with your actual IP"
        }
        else {
            $info += "✓ RDP access configured"
        }
    }
    else {
        $warnings += "RDP access disabled - you may need this for administration"
    }
    
    # Check Cloudflare configuration
    if ($configContent -match 'enable_cloudflare_proxy\s*=\s*true') {
        $info += "✓ Cloudflare proxy enabled"
    }
    else {
        $warnings += "Cloudflare proxy not enabled (enable_cloudflare_proxy = true)"
    }
    
    if ($configContent -match 'cloudflare_ssl_mode\s*=\s*"full"') {
        $info += "✓ Cloudflare SSL mode set to full"
    }
    else {
        $warnings += "Cloudflare SSL mode not set to full (cloudflare_ssl_mode = `"full`")"
    }
    
    # Check for hardcoded secrets
    $secretPatterns = @(
        'password\s*=\s*"[^"]{1,20}"',  # Short passwords
        'key\s*=\s*"[^"]{1,20}"',       # Short keys
        'token\s*=\s*"[^"]{1,20}"'      # Short tokens
    )
    
    foreach ($pattern in $secretPatterns) {
        if ($configContent -match $pattern) {
            $warnings += "Potential hardcoded secret found - ensure values are secure"
        }
    }
    
    # Display results
    Write-Host ""
    Write-Host "=== Validation Results ===" -ForegroundColor Green
    
    if ($errors.Count -eq 0) {
        Write-Host "✓ All required variables are configured!" -ForegroundColor Green
    }
    else {
        Write-Host "✗ Configuration errors found:" -ForegroundColor Red
        foreach ($err in $errors) {
            Write-Host "  - $err" -ForegroundColor Red
        }
    }
    
    if ($warnings.Count -gt 0) {
        Write-Host ""
        Write-Host "⚠ Warnings:" -ForegroundColor Yellow
        foreach ($warning in $warnings) {
            Write-Host "  - $warning" -ForegroundColor Yellow
        }
    }
    
    if ($Verbose -and $info.Count -gt 0) {
        Write-Host ""
        Write-Host "ℹ Information:" -ForegroundColor Cyan
        foreach ($infoItem in $info) {
            Write-Host "  - $infoItem" -ForegroundColor Cyan
        }
    }
    
    Write-Host ""
    Write-Host "Summary:" -ForegroundColor Green
    Write-Host "  Errors: $($errors.Count)" -ForegroundColor $(if ($errors.Count -eq 0) { "Green" } else { "Red" })
    Write-Host "  Warnings: $($warnings.Count)" -ForegroundColor $(if ($warnings.Count -eq 0) { "Green" } else { "Yellow" })
    Write-Host "  Info: $($info.Count)" -ForegroundColor Cyan
    
    if ($errors.Count -eq 0) {
        Write-Host ""
        Write-Host "✅ Configuration validation passed!" -ForegroundColor Green
        Write-Host "You can proceed with deployment." -ForegroundColor Green
        exit 0
    }
    else {
        Write-Host ""
        Write-Host "❌ Configuration validation failed." -ForegroundColor Red
        Write-Host "Please fix the errors before proceeding." -ForegroundColor Red
        exit 1
    }
    
} catch {
    Write-Error "Validation failed: $($_.Exception.Message)"
    exit 1
} 