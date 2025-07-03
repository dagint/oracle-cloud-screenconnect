# Secure Configuration Setup Script
# This script helps you create a secure terraform.tfvars file

param(
    [string]$Environment = "production",
    [switch]$Interactive,
    [switch]$DryRun
)

Write-Host "=== Secure Configuration Setup ===" -ForegroundColor Green
Write-Host "Environment: $Environment" -ForegroundColor Yellow
Write-Host ""

# Security: Validate script is running from expected location
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$expectedRoot = Split-Path -Parent $scriptDir
if (-not (Test-Path (Join-Path $expectedRoot "VERSION"))) {
    Write-Error "Script must be run from the repository root directory"
    exit 1
}

$secureTemplatePath = "environments/$Environment/terraform.tfvars.secure"
$targetPath = "environments/$Environment/terraform.tfvars"

# Check if secure template exists
if (-not (Test-Path $secureTemplatePath)) {
    Write-Error "Secure template not found: $secureTemplatePath"
    Write-Host "Please ensure you have the terraform.tfvars.secure file" -ForegroundColor Red
    exit 1
}

# Check if target file already exists
if (Test-Path $targetPath) {
    Write-Warning "Target file already exists: $targetPath"
    $overwrite = Read-Host "Do you want to overwrite it? (y/N)"
    if ($overwrite -ne "y" -and $overwrite -ne "Y") {
        Write-Host "Setup cancelled." -ForegroundColor Yellow
        exit 0
    }
}

try {
    Write-Host "Setting up secure configuration for $Environment..." -ForegroundColor Yellow
    
    if ($DryRun) {
        Write-Host "DRY RUN MODE - No changes will be made" -ForegroundColor Cyan
    }
    
    # Copy the secure template
    if (-not $DryRun) {
        Copy-Item $secureTemplatePath $targetPath
        Write-Host "✓ Created $targetPath from template" -ForegroundColor Green
    }
    
    # Open the file for editing if interactive mode
    if ($Interactive -and -not $DryRun) {
        Write-Host ""
        Write-Host "Opening configuration file for editing..." -ForegroundColor Yellow
        Write-Host "Please update the following values:" -ForegroundColor Cyan
        Write-Host "  - Oracle Cloud credentials (tenancy_ocid, compartment_ocid, etc.)" -ForegroundColor White
        Write-Host "  - ScreenConnect license key" -ForegroundColor White
        Write-Host "  - Admin password" -ForegroundColor White
        Write-Host "  - Cloudflare API token and zone ID" -ForegroundColor White
        Write-Host "  - Your domain names" -ForegroundColor White
        Write-Host "  - Your WAN IP addresses for RDP access" -ForegroundColor White
        Write-Host ""
        
        # Try to open with default editor
        try {
            Start-Process $targetPath
        } catch {
            Write-Host "Could not open file automatically. Please edit: $targetPath" -ForegroundColor Yellow
        }
    }
    
    # Display next steps
    Write-Host ""
    Write-Host "=== Next Steps ===" -ForegroundColor Green
    
    if (-not $Interactive) {
        Write-Host "1. Edit the configuration file:" -ForegroundColor White
        Write-Host "   notepad $targetPath" -ForegroundColor Cyan
        Write-Host ""
    }
    
    Write-Host "2. Update the following required values:" -ForegroundColor White
    Write-Host "   - Oracle Cloud credentials" -ForegroundColor Cyan
    Write-Host "   - ScreenConnect license key" -ForegroundColor Cyan
    Write-Host "   - Admin password" -ForegroundColor Cyan
    Write-Host "   - Cloudflare API token and zone ID" -ForegroundColor Cyan
    Write-Host "   - Your domain names" -ForegroundColor Cyan
    Write-Host "   - Your WAN IP addresses" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "3. Validate your configuration:" -ForegroundColor White
    Write-Host "   .\scripts\validate-deployment.ps1 -Environment $Environment" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "4. Deploy your infrastructure:" -ForegroundColor White
    Write-Host "   cd environments/$Environment" -ForegroundColor Cyan
    Write-Host "   terraform init" -ForegroundColor Cyan
    Write-Host "   terraform plan" -ForegroundColor Cyan
    Write-Host "   terraform apply" -ForegroundColor Cyan
    Write-Host ""
    
    # Security reminders
    Write-Host "=== Security Reminders ===" -ForegroundColor Yellow
    Write-Host "✓ The terraform.tfvars file is in .gitignore and won't be committed" -ForegroundColor Green
    Write-Host "✓ Use Oracle Vault for production secrets (use_vault_for_secrets = true)" -ForegroundColor Green
    Write-Host "✓ Restrict RDP access to your specific IP addresses only" -ForegroundColor Green
    Write-Host "✓ Use strong, unique passwords" -ForegroundColor Green
    Write-Host "✓ Enable Cloudflare proxy for additional security" -ForegroundColor Green
    Write-Host ""
    
    # Show file location
    Write-Host "Configuration file created at:" -ForegroundColor Cyan
    Write-Host "  $targetPath" -ForegroundColor White
    
    if (-not $DryRun) {
        Write-Host ""
        Write-Host "✅ Secure configuration setup complete!" -ForegroundColor Green
    }
    
} catch {
    Write-Error "Setup failed: $($_.Exception.Message)"
    exit 1
} 