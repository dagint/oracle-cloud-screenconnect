# ScreenConnect Deployment Prerequisites Validation Script
# This script checks all required components before deployment

param(
    [string]$TerraformPath = "terraform",
    [string]$ConfigPath = "terraform.tfvars"
)

Write-Host "=== ScreenConnect Deployment Prerequisites Validation ===" -ForegroundColor Green
Write-Host ""

$errors = @()
$warnings = @()

# Check if Terraform is installed
Write-Host "Checking Terraform installation..." -ForegroundColor Yellow
try {
    $terraformVersion = & $TerraformPath version
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Terraform is installed" -ForegroundColor Green
        Write-Host "  Version: $($terraformVersion[0])" -ForegroundColor Gray
    } else {
        $errors += "Terraform is not properly installed or not in PATH"
    }
} catch {
    $errors += "Terraform is not installed or not in PATH"
}

# Check if terraform.tfvars exists
Write-Host "Checking configuration file..." -ForegroundColor Yellow
if (Test-Path $ConfigPath) {
    Write-Host "✓ Configuration file found: $ConfigPath" -ForegroundColor Green
} else {
    $errors += "Configuration file not found: $ConfigPath"
}

# Check SSH key
Write-Host "Checking SSH key..." -ForegroundColor Yellow
$sshKeyPath = "~/.ssh/id_rsa.pub"
if (Test-Path $sshKeyPath) {
    Write-Host "✓ SSH public key found: $sshKeyPath" -ForegroundColor Green
} else {
    $warnings += "SSH public key not found at default location: $sshKeyPath"
}

# Check Oracle Cloud CLI configuration
Write-Host "Checking Oracle Cloud configuration..." -ForegroundColor Yellow
$ociConfigPath = "~/.oci/config"
if (Test-Path $ociConfigPath) {
    Write-Host "✓ Oracle Cloud configuration found: $ociConfigPath" -ForegroundColor Green
} else {
    $warnings += "Oracle Cloud configuration not found at: $ociConfigPath"
}

# Check internet connectivity
Write-Host "Checking internet connectivity..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "https://api.ipify.org" -UseBasicParsing -TimeoutSec 10
    if ($response.StatusCode -eq 200) {
        Write-Host "✓ Internet connectivity confirmed" -ForegroundColor Green
        Write-Host "  Current public IP: $($response.Content)" -ForegroundColor Gray
    } else {
        $errors += "Internet connectivity test failed"
    }
} catch {
    $errors += "Internet connectivity test failed: $($_.Exception.Message)"
}

# Check PowerShell version
Write-Host "Checking PowerShell version..." -ForegroundColor Yellow
$psVersion = $PSVersionTable.PSVersion
if ($psVersion.Major -ge 5) {
    Write-Host "✓ PowerShell version is compatible: $($psVersion.ToString())" -ForegroundColor Green
} else {
    $errors += "PowerShell version 5.1 or higher is required. Current version: $($psVersion.ToString())"
}

# Check execution policy
Write-Host "Checking PowerShell execution policy..." -ForegroundColor Yellow
$executionPolicy = Get-ExecutionPolicy
if ($executionPolicy -eq "RemoteSigned" -or $executionPolicy -eq "Unrestricted" -or $executionPolicy -eq "Bypass") {
    Write-Host "✓ PowerShell execution policy is compatible: $executionPolicy" -ForegroundColor Green
} else {
    $warnings += "PowerShell execution policy is restrictive: $executionPolicy"
}

# Display results
Write-Host ""
Write-Host "=== Validation Results ===" -ForegroundColor Green

if ($errors.Count -eq 0) {
    Write-Host "✓ All critical checks passed!" -ForegroundColor Green
} else {
    Write-Host "✗ Critical issues found:" -ForegroundColor Red
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

Write-Host ""
if ($errors.Count -eq 0) {
    Write-Host "You can proceed with deployment!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "Please fix the critical issues before proceeding with deployment." -ForegroundColor Red
    exit 1
} 