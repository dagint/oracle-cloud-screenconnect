# Environment Creation Script
# This script creates new environments from the production template

param(
    [Parameter(Mandatory=$true)]
    [ValidatePattern('^[a-z0-9-]+$')]
    [string]$EnvironmentName,
    
    [ValidatePattern('^[a-z0-9-]+$')]
    [string]$SourceEnvironment = "production",
    [switch]$Force,
    [switch]$DryRun
)

# Security: Validate script is running from expected location
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$expectedRoot = Split-Path -Parent $scriptDir
if (-not (Test-Path (Join-Path $expectedRoot "VERSION"))) {
    Write-Error "Script must be run from the repository root directory"
    exit 1
}

# Security: Prevent creation of reserved environment names
$reservedNames = @("production", "prod", "live", "main", "master")
if ($EnvironmentName -in $reservedNames) {
    Write-Error "Environment name '$EnvironmentName' is reserved. Please choose a different name."
    exit 1
}

Write-Host "=== Environment Creation ===" -ForegroundColor Green
Write-Host "Source Environment: $SourceEnvironment" -ForegroundColor Yellow
Write-Host "New Environment: $EnvironmentName" -ForegroundColor Yellow
Write-Host ""

# Validate environment name
if ($EnvironmentName -notmatch '^[a-z0-9-]+$') {
    Write-Error "Invalid environment name. Use only lowercase letters, numbers, and hyphens."
    exit 1
}

# Check if environment already exists
$newEnvPath = "environments/$EnvironmentName"
if (Test-Path $newEnvPath -and -not $Force) {
    Write-Error "Environment '$EnvironmentName' already exists. Use -Force to overwrite."
    exit 1
}

# Check if source environment exists
$sourceEnvPath = "environments/$SourceEnvironment"
if (-not (Test-Path $sourceEnvPath)) {
    Write-Error "Source environment '$SourceEnvironment' not found."
    exit 1
}

try {
    Write-Host "Creating environment '$EnvironmentName' from '$SourceEnvironment'..." -ForegroundColor Yellow
    
    if ($DryRun) {
        Write-Host "DRY RUN MODE - No changes will be made" -ForegroundColor Cyan
    }
    
    # Create new environment directory
    if (-not $DryRun) {
        if (Test-Path $newEnvPath) {
            Remove-Item $newEnvPath -Recurse -Force
        }
        New-Item -Path $newEnvPath -ItemType Directory -Force | Out-Null
    }
    
    # Copy files from source environment
    $filesToCopy = @(
        "main.tf",
        "variables.tf",
        "terraform.tfvars.example"
    )
    
    foreach ($file in $filesToCopy) {
        $sourceFile = "$sourceEnvPath/$file"
        $destFile = "$newEnvPath/$file"
        
        if (Test-Path $sourceFile) {
            if (-not $DryRun) {
                Copy-Item $sourceFile $destFile
            }
            Write-Host "✓ Copied $file" -ForegroundColor Green
        } else {
            Write-Warning "Source file not found: $sourceFile"
        }
    }
    
    # Create environment-specific terraform.tfvars
    $tfvarsContent = @"
# Oracle Cloud ScreenConnect Deployment - $EnvironmentName Environment
# Generated from $SourceEnvironment template

# Oracle Cloud Configuration
tenancy_ocid     = "ocid1.tenancy.oc1..your-tenancy-ocid"
compartment_ocid = "ocid1.compartment.oc1..your-compartment-ocid"
user_ocid        = "ocid1.user.oc1..your-user-ocid"
fingerprint      = "your-fingerprint"
private_key_path = "~/.oci/oci_api_key.pem"
region           = "us-ashburn-1"

# SSH Configuration
ssh_public_key_path = "~/.ssh/id_rsa.pub"

# Project Configuration
project_name = "screenconnect"
environment  = "$EnvironmentName"

# Network Configuration
vcn_cidr_block    = "10.0.0.0/16"
subnet_cidr_block = "10.0.1.0/24"

# RDP Access Configuration
enable_rdp_access = true
auto_detect_home_ip = true
additional_rdp_ips = [
  # Add your IP addresses here
]

# Secrets Management Configuration
use_vault_for_secrets = true

# Compute Configuration
instance_shape = "VM.Standard.A1.Flex"
ocpus          = 1
memory_in_gbs  = 6

# ScreenConnect Configuration
screenconnect_license_key = "your-screenconnect-license-key"
admin_password           = "your-admin-password"

# Domain Configuration
primary_domain = "remotesupport.yourdomain.com"  # Change to your domain
relay_domain   = "relay.yourdomain.com"  # Change to your domain

# Cloudflare Configuration
cloudflare_api_token = "your-cloudflare-api-token"
cloudflare_zone_id   = "your-cloudflare-zone-id"
enable_cloudflare_proxy = true
cloudflare_ssl_mode = "full"

# Backup Configuration
backup_bucket_name = "screenconnect-backups-$EnvironmentName"
backup_retention   = 5

# Tags
tags = {
  Project     = "screenconnect"
  Environment = "$EnvironmentName"
  Purpose     = "remote-support"
  Owner       = "your-name"
}
"@
    
    if (-not $DryRun) {
        $tfvarsContent | Out-File -FilePath "$newEnvPath/terraform.tfvars" -Encoding UTF8
    }
    Write-Host "✓ Created terraform.tfvars for $EnvironmentName" -ForegroundColor Green
    
    # Create environment-specific README
    $readmeContent = @"
# ScreenConnect Deployment - $EnvironmentName Environment

This environment was created from the $SourceEnvironment template.

## Configuration

- **Environment**: $EnvironmentName
- **Source**: $SourceEnvironment
- **Created**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## Quick Start

1. **Configure the environment**:
   ```bash
   cd environments/$EnvironmentName
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   ```

2. **Validate the configuration**:
   ```powershell
   ..\..\scripts\validate-deployment.ps1 -Environment $EnvironmentName
   ```

3. **Deploy the infrastructure**:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

## Environment-Specific Notes

- This environment uses the same configuration as $SourceEnvironment
- Modify terraform.tfvars to customize for your needs
- Consider using different domains for each environment
- Backup bucket name includes environment suffix: screenconnect-backups-$EnvironmentName

## Security Considerations

- Use different domains for each environment
- Consider using different Oracle Cloud compartments
- Use environment-specific secrets in Oracle Vault
- Review and adjust RDP access IPs for each environment

## Maintenance

- Run validation before each deployment
- Test changes in this environment before production
- Keep environment-specific backups
- Monitor costs for each environment separately
"@
    
    if (-not $DryRun) {
        $readmeContent | Out-File -FilePath "$newEnvPath/README.md" -Encoding UTF8
    }
    Write-Host "✓ Created README.md for $EnvironmentName" -ForegroundColor Green
    
    # Update main README to include new environment
    if (-not $DryRun) {
        $mainReadmePath = "README.md"
        if (Test-Path $mainReadmePath) {
            $mainReadmeContent = Get-Content $mainReadmePath -Raw
            if ($mainReadmeContent -notmatch "environments/$EnvironmentName") {
                # Add environment to the environments list if it exists
                $mainReadmeContent = $mainReadmeContent -replace "environments/\$EnvironmentName", "environments/$EnvironmentName"
                $mainReadmeContent | Set-Content $mainReadmePath -NoNewline
            }
        }
    }
    
    Write-Host ""
    Write-Host "=== Environment Creation Complete ===" -ForegroundColor Green
    Write-Host "Environment '$EnvironmentName' has been created successfully!" -ForegroundColor Green
    
    if (-not $DryRun) {
        Write-Host ""
        Write-Host "Next steps:" -ForegroundColor Yellow
        Write-Host "1. Navigate to the new environment: cd environments/$EnvironmentName" -ForegroundColor White
        Write-Host "2. Configure terraform.tfvars with your values" -ForegroundColor White
        Write-Host "3. Run validation: ..\..\scripts\validate-deployment.ps1 -Environment $EnvironmentName" -ForegroundColor White
        Write-Host "4. Deploy: terraform init && terraform plan && terraform apply" -ForegroundColor White
        Write-Host ""
        Write-Host "Environment files created:" -ForegroundColor Cyan
        Write-Host "  - $newEnvPath/main.tf" -ForegroundColor White
        Write-Host "  - $newEnvPath/variables.tf" -ForegroundColor White
        Write-Host "  - $newEnvPath/terraform.tfvars" -ForegroundColor White
        Write-Host "  - $newEnvPath/README.md" -ForegroundColor White
    }
    
} catch {
    Write-Error "Environment creation failed: $($_.Exception.Message)"
    exit 1
} 