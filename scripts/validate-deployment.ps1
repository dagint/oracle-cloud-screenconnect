# Deployment Validation Script
# This script validates the deployment configuration before applying

param(
    [string]$Environment = "production",
    [string]$TerraformPath = "terraform",
    [switch]$SkipTerraformValidation,
    [switch]$SkipSecurityChecks,
    [switch]$Verbose
)

Write-Host "=== Deployment Validation ===" -ForegroundColor Green
Write-Host "Environment: $Environment" -ForegroundColor Yellow
Write-Host ""

$errors = @()
$warnings = @()
$info = @()

# Function to add validation results
function Add-ValidationResult {
    param([string]$Type, [string]$Message, [string]$Category = "Info")
    
    switch ($Category) {
        "Error" { $errors += $Message }
        "Warning" { $warnings += $Message }
        "Info" { $info += $Message }
    }
}

try {
    # 1. Check file structure
    Write-Host "Validating file structure..." -ForegroundColor Yellow
    
    $requiredFiles = @(
        "VERSION",
        "CHANGELOG.md",
        "README.md",
        "DEPLOYMENT_GUIDE.md",
        "environments/$Environment/main.tf",
        "environments/$Environment/variables.tf",
        "environments/$Environment/terraform.tfvars.example",
        "modules/compute/main.tf",
        "modules/compute/variables.tf",
        "modules/compute/outputs.tf",
        "modules/compute/user_data.tpl",
        "modules/networking/main.tf",
        "modules/networking/variables.tf",
        "modules/networking/outputs.tf",
        "modules/storage/main.tf",
        "modules/vault/main.tf",
        "modules/cloudflare_dns/main.tf"
    )
    
    foreach ($file in $requiredFiles) {
        if (Test-Path $file) {
            Add-ValidationResult -Type "File" -Message "✓ $file exists" -Category "Info"
        } else {
            Add-ValidationResult -Type "File" -Message "✗ Missing required file: $file" -Category "Error"
        }
    }
    
    # 2. Validate VERSION file
    Write-Host "Validating version information..." -ForegroundColor Yellow
    if (Test-Path "VERSION") {
        $version = Get-Content "VERSION"
        if ($version -match '^\d+\.\d+\.\d+\.\d+$') {
            Add-ValidationResult -Type "Version" -Message "✓ Version format valid: $version" -Category "Info"
        } else {
            Add-ValidationResult -Type "Version" -Message "✗ Invalid version format: $version" -Category "Error"
        }
    }
    
    # 3. Check ScreenConnect version consistency
    Write-Host "Validating ScreenConnect version consistency..." -ForegroundColor Yellow
    $userDataContent = Get-Content "modules/compute/user_data.tpl" -Raw
    $versionPattern = 'ScreenConnect_(\d+\.\d+\.\d+\.\d+)\.msi'
    
    if ($userDataContent -match $versionPattern) {
        $userDataVersion = $matches[1]
        $fileVersion = Get-Content "VERSION"
        
        if ($userDataVersion -eq $fileVersion) {
            Add-ValidationResult -Type "Version" -Message "✓ ScreenConnect version consistent: $userDataVersion" -Category "Info"
        } else {
            Add-ValidationResult -Type "Version" -Message "✗ Version mismatch: VERSION=$fileVersion, user_data.tpl=$userDataVersion" -Category "Error"
        }
    }
    
    # 4. Validate Terraform configuration
    if (-not $SkipTerraformValidation) {
        Write-Host "Validating Terraform configuration..." -ForegroundColor Yellow
        
        # Check if terraform is available
        try {
            $terraformVersion = & $TerraformPath version
            if ($LASTEXITCODE -eq 0) {
                Add-ValidationResult -Type "Terraform" -Message "✓ Terraform available: $($terraformVersion[0])" -Category "Info"
            } else {
                Add-ValidationResult -Type "Terraform" -Message "✗ Terraform not available" -Category "Error"
            }
        } catch {
            Add-ValidationResult -Type "Terraform" -Message "✗ Terraform not found in PATH" -Category "Error"
        }
        
        # Validate Terraform configuration
        if (Test-Path "environments/$Environment") {
            Push-Location "environments/$Environment"
            try {
                $validateOutput = & $TerraformPath validate 2>&1
                if ($LASTEXITCODE -eq 0) {
                    Add-ValidationResult -Type "Terraform" -Message "✓ Terraform configuration is valid" -Category "Info"
                } else {
                    Add-ValidationResult -Type "Terraform" -Message "✗ Terraform validation failed: $validateOutput" -Category "Error"
                }
            } catch {
                Add-ValidationResult -Type "Terraform" -Message "✗ Terraform validation error: $($_.Exception.Message)" -Category "Error"
            }
            Pop-Location
        }
    }
    
    # 5. Security validation
    if (-not $SkipSecurityChecks) {
        Write-Host "Validating security configuration..." -ForegroundColor Yellow
        
        # Check for WinRM references (should be removed)
        $filesToCheck = @(
            "modules/networking/main.tf",
            "environments/$Environment/main.tf",
            "README.md",
            "DEPLOYMENT_GUIDE.md"
        )
        
        foreach ($file in $filesToCheck) {
            if (Test-Path $file) {
                $content = Get-Content $file -Raw
                if ($content -match '5985|5986|WinRM|winrm') {
                    Add-ValidationResult -Type "Security" -Message "⚠ WinRM references found in $file" -Category "Warning"
                }
            }
        }
        
        # Check for hardcoded secrets
        $secretPatterns = @(
            'password.*=.*["''][^"''\s]+["'']',
            'key.*=.*["''][^"''\s]+["'']',
            'token.*=.*["''][^"''\s]+["'']'
        )
        
        foreach ($file in $filesToCheck) {
            if (Test-Path $file) {
                $content = Get-Content $file -Raw
                foreach ($pattern in $secretPatterns) {
                    if ($content -match $pattern) {
                        Add-ValidationResult -Type "Security" -Message "⚠ Potential hardcoded secret found in $file" -Category "Warning"
                    }
                }
            }
        }
        
        # Check for proper domain configuration
        $terraformVarsPath = "environments/$Environment/terraform.tfvars.example"
        if (Test-Path $terraformVarsPath) {
            $content = Get-Content $terraformVarsPath -Raw
            if ($content -match 'primary_domain.*=.*"help\.yourdomain\.com"') {
                Add-ValidationResult -Type "Security" -Message "⚠ Using example domain in terraform.tfvars.example" -Category "Warning"
            }
        }
    }
    
    # 6. Check for required variables
    Write-Host "Validating required variables..." -ForegroundColor Yellow
    
    $requiredVariables = @(
        "tenancy_ocid",
        "compartment_ocid", 
        "user_ocid",
        "fingerprint",
        "screenconnect_license_key",
        "admin_password",
        "primary_domain",
        "relay_domain",
        "cloudflare_api_token",
        "cloudflare_zone_id"
    )
    
    $variablesFile = "environments/$Environment/variables.tf"
    if (Test-Path $variablesFile) {
        $content = Get-Content $variablesFile -Raw
        foreach ($variable in $requiredVariables) {
            if ($content -match "variable `"$variable`"") {
                Add-ValidationResult -Type "Variables" -Message "✓ Required variable defined: $variable" -Category "Info"
            } else {
                Add-ValidationResult -Type "Variables" -Message "✗ Missing required variable: $variable" -Category "Error"
            }
        }
    }
    
    # 7. Check module structure
    Write-Host "Validating module structure..." -ForegroundColor Yellow
    
    $modules = @("compute", "networking", "storage", "vault", "cloudflare_dns")
    foreach ($module in $modules) {
        $modulePath = "modules/$module"
        if (Test-Path $modulePath) {
            $hasMain = Test-Path "$modulePath/main.tf"
            $hasVariables = Test-Path "$modulePath/variables.tf"
            $hasOutputs = Test-Path "$modulePath/outputs.tf"
            
            if ($hasMain -and $hasVariables -and $hasOutputs) {
                Add-ValidationResult -Type "Modules" -Message "✓ Module $module has complete structure" -Category "Info"
            } else {
                Add-ValidationResult -Type "Modules" -Message "⚠ Module $module missing files (main: $hasMain, vars: $hasVariables, outputs: $hasOutputs)" -Category "Warning"
            }
        } else {
            Add-ValidationResult -Type "Modules" -Message "✗ Missing module: $module" -Category "Error"
        }
    }
    
    # 8. Check documentation
    Write-Host "Validating documentation..." -ForegroundColor Yellow
    
    $docs = @("README.md", "DEPLOYMENT_GUIDE.md", "CHANGELOG.md")
    foreach ($doc in $docs) {
        if (Test-Path $doc) {
            $content = Get-Content $doc -Raw
            $wordCount = ($content -split '\s+').Count
            if ($wordCount -gt 100) {
                Add-ValidationResult -Type "Documentation" -Message "✓ $doc has sufficient content ($wordCount words)" -Category "Info"
            } else {
                Add-ValidationResult -Type "Documentation" -Message "⚠ $doc may need more content ($wordCount words)" -Category "Warning"
            }
        } else {
            Add-ValidationResult -Type "Documentation" -Message "✗ Missing documentation: $doc" -Category "Error"
        }
    }
    
} catch {
    Add-ValidationResult -Type "System" -Message "✗ Validation error: $($_.Exception.Message)" -Category "Error"
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
    Write-Host "✅ Deployment validation passed! You can proceed with deployment." -ForegroundColor Green
    exit 0
} else {
    Write-Host ""
    Write-Host "❌ Deployment validation failed. Please fix the errors before proceeding." -ForegroundColor Red
    exit 1
} 