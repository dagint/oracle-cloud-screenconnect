# AWS to Oracle Cloud Migration Assistant
# Focuses on careful file merging and configuration comparison
# Rather than direct copy replacement

param(
    [string]$Action = "analyze",
    [string]$SourceServer = "",
    [string]$SourceAdminPassword = "",
    [string]$SourceBackupPath = "",
    [string]$OracleConfigPath = "",
    [switch]$DryRun = $true,
    [switch]$Interactive = $true,
    [string]$OutputPath = "aws-migration-analysis.txt"
)

# Function to write logs
function Write-Log {
    param($Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    Write-Output $logMessage
    Add-Content -Path $OutputPath -Value $logMessage
}

# Function to compare configuration files
function Compare-Configurations {
    param(
        [string]$SourceConfig,
        [string]$TargetConfig,
        [string]$ConfigType
    )
    
    Write-Log "Comparing $ConfigType configurations..." "INFO"
    
    $comparison = @{
        Type = $ConfigType
        SourceFile = $SourceConfig
        TargetFile = $TargetConfig
        Differences = @()
        Conflicts = @()
        Recommendations = @()
    }
    
    try {
        if (Test-Path $SourceConfig) {
            $sourceContent = Get-Content $SourceConfig -Raw
            $targetContent = Get-Content $TargetConfig -Raw
            
            # Compare content
            if ($sourceContent -eq $targetContent) {
                Write-Log "✓ Configurations are identical" "SUCCESS"
                $comparison.Recommendations += "Direct copy is safe"
            } else {
                Write-Log "⚠ Configurations differ - manual review required" "WARNING"
                $comparison.Differences += "Content differs between source and target"
                $comparison.Recommendations += "Manual merge required"
            }
        } else {
            Write-Log "Source configuration not found: $SourceConfig" "WARNING"
            $comparison.Conflicts += "Source file missing"
        }
    }
    catch {
        Write-Log "Error comparing configurations: $($_.Exception.Message)" "ERROR"
        $comparison.Conflicts += "Comparison failed: $($_.Exception.Message)"
    }
    
    return $comparison
}

# Function to analyze AWS-specific configurations
function Analyze-AWSConfigurations {
    param([string]$SourceServer)
    
    Write-Log "Analyzing AWS-specific configurations..." "INFO"
    
    $awsConfigs = @{
        IISConfig = @()
        ScreenConnectConfig = @()
        SSLConfig = @()
        BackupConfig = @()
        CustomFiles = @()
    }
    
    try {
        # Check for AWS-specific IIS configurations
        $iisPaths = @(
            "C:\inetpub\wwwroot\web.config",
            "C:\Program Files (x86)\ScreenConnect\App_Web.config",
            "C:\Program Files (x86)\ScreenConnect\ScreenConnect.Service.exe.config"
        )
        
        foreach ($path in $iisPaths) {
            if (Test-Path $path) {
                $content = Get-Content $path -Raw
                
                # Look for AWS-specific settings
                if ($content -match "AWS|amazonaws|EC2|S3") {
                    $awsConfigs.IISConfig += @{
                        File = $path
                        AWSReferences = ($content | Select-String -Pattern "AWS|amazonaws|EC2|S3" -AllMatches).Matches.Value
                    }
                }
            }
        }
        
        # Check for AWS backup configurations
        $backupPaths = @(
            "C:\Program Files (x86)\ScreenConnect\App_Data\Backups",
            "C:\ScreenConnect\Backups"
        )
        
        foreach ($path in $backupPaths) {
            if (Test-Path $path) {
                $backupFiles = Get-ChildItem $path -Filter "*.config" -Recurse
                foreach ($file in $backupFiles) {
                    $content = Get-Content $file.FullName -Raw
                    if ($content -match "AWS|S3|amazonaws") {
                        $awsConfigs.BackupConfig += @{
                            File = $file.FullName
                            AWSReferences = ($content | Select-String -Pattern "AWS|S3|amazonaws" -AllMatches).Matches.Value
                        }
                    }
                }
            }
        }
        
        Write-Log "✓ AWS configuration analysis completed" "SUCCESS"
    }
    catch {
        Write-Log "Error analyzing AWS configurations: $($_.Exception.Message)" "ERROR"
    }
    
    return $awsConfigs
}

# Function to create migration merge plan
function New-MigrationMergePlan {
    param(
        [hashtable]$AWSConfigs,
        [hashtable]$OracleConfigs,
        [string]$OutputFile
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    $mergePlan = @"
# AWS to Oracle Cloud Migration Merge Plan
# Generated on: $timestamp
# Focus: Careful file merging vs direct replacement

## Migration Strategy Overview

This migration uses a **careful merge approach** rather than direct file replacement to preserve customizations and ensure compatibility.

## Phase 1: Configuration Analysis

### AWS-Specific Configurations Found
"@

    if ($AWSConfigs.IISConfig.Count -gt 0) {
        $mergePlan += "`n`n### IIS Configurations with AWS References:"
        foreach ($config in $AWSConfigs.IISConfig) {
            $mergePlan += "`n- **File:** $($config.File)"
            $mergePlan += "`n  - AWS References: $($config.AWSReferences -join ', ')"
            $mergePlan += "`n  - **Action:** Manual review required"
        }
    }
    
    if ($AWSConfigs.BackupConfig.Count -gt 0) {
        $mergePlan += "`n`n### Backup Configurations with AWS References:"
        foreach ($config in $AWSConfigs.BackupConfig) {
            $mergePlan += "`n- **File:** $($config.File)"
            $mergePlan += "`n  - AWS References: $($config.AWSReferences -join ', ')"
            $mergePlan += "`n  - **Action:** Update to Oracle Cloud Object Storage"
        }
    }

    $mergePlan += @"

## Phase 2: File Migration Strategy

### Safe Direct Copy (No AWS Dependencies)
- ScreenConnect application files
- User data and sessions
- Custom themes and branding
- Log files (for analysis)

### Manual Merge Required (AWS Dependencies)
- Web.config files
- Service configuration files
- Backup configuration files
- SSL certificate configurations

### Oracle Cloud Specific Updates
- Backup storage endpoints (S3 → Object Storage)
- SSL certificate paths
- Domain configurations
- Firewall rules

## Phase 3: Configuration Migration Steps

### Step 1: Backup Current Configurations
```powershell
# Create backup of current configurations
Copy-Item "C:\Program Files (x86)\ScreenConnect\App_Web.config" "C:\backup\App_Web.config.aws"
Copy-Item "C:\Program Files (x86)\ScreenConnect\ScreenConnect.Service.exe.config" "C:\backup\Service.config.aws"
```

### Step 2: Identify Custom Settings
```powershell
# Extract custom settings from AWS configurations
Get-Content "C:\backup\App_Web.config.aws" | Select-String -Pattern "add key|connectionString|appSettings"
```

### Step 3: Merge with Oracle Cloud Configuration
```powershell
# Apply Oracle Cloud base configuration
Copy-Item "C:\oracle-config\App_Web.config.oracle" "C:\Program Files (x86)\ScreenConnect\App_Web.config"

# Manually add custom settings from AWS backup
# (Use text editor to merge specific sections)
```

### Step 4: Update Storage Endpoints
```powershell
# Update backup configuration from AWS S3 to Oracle Object Storage
# Replace: s3.amazonaws.com
# With:   objectstorage.us-ashburn-1.oraclecloud.com
```

## Phase 4: Validation Checklist

### Pre-Migration Validation
- [ ] All AWS-specific configurations identified
- [ ] Custom settings documented
- [ ] Oracle Cloud configuration prepared
- [ ] Backup of current system completed
- [ ] Test environment configured

### During Migration
- [ ] Stop ScreenConnect services
- [ ] Backup current configurations
- [ ] Apply Oracle Cloud base configuration
- [ ] Merge custom settings manually
- [ ] Update storage endpoints
- [ ] Test configuration syntax

### Post-Migration Validation
- [ ] ScreenConnect services start successfully
- [ ] Web interface accessible
- [ ] SSL certificates working
- [ ] Backup system functional
- [ ] All custom features working
- [ ] Performance acceptable

## Risk Mitigation

### High Risk Areas
1. **Configuration Conflicts** - AWS-specific settings may conflict with Oracle Cloud
2. **Storage Endpoints** - S3 URLs need to be updated to Object Storage
3. **SSL Certificates** - Certificate paths may differ
4. **Custom Code** - Any custom modifications need careful migration

### Mitigation Strategies
1. **Incremental Migration** - Test each configuration change individually
2. **Rollback Plan** - Keep AWS backup for quick rollback
3. **Parallel Testing** - Test Oracle Cloud configuration before cutover
4. **Documentation** - Document every change made during migration

## Oracle Cloud Specific Considerations

### Storage Migration
- **AWS S3** → **Oracle Object Storage**
- **Endpoint:** s3.amazonaws.com → objectstorage.{region}.oraclecloud.com
- **Authentication:** Access keys → OCI API keys
- **Bucket naming:** May need to adjust for Oracle Cloud requirements

### Network Configuration
- **Security Groups** → **Security Lists**
- **VPC** → **VCN**
- **Subnets** → **Subnets (same concept)**
- **Route Tables** → **Route Tables**

### SSL/TLS Configuration
- **Certificate storage:** May differ between AWS and Oracle Cloud
- **Certificate renewal:** Update automation scripts
- **Domain validation:** May need to re-validate with new infrastructure

## Rollback Plan

If issues occur during migration:

1. **Immediate Rollback:**
   - Restore AWS configuration backups
   - Restart ScreenConnect services
   - Verify functionality

2. **Investigation:**
   - Review migration logs
   - Identify specific configuration issues
   - Test fixes in isolated environment

3. **Retry Migration:**
   - Apply fixes to Oracle Cloud configuration
   - Re-run migration process
   - Validate each step

## Post-Migration Optimization

### Performance Tuning
- Monitor Oracle Cloud instance performance
- Adjust compute resources if needed
- Optimize backup schedules for Object Storage

### Security Hardening
- Review Oracle Cloud security lists
- Update SSL certificate configurations
- Implement Oracle Cloud monitoring

### Cost Optimization
- Monitor Oracle Cloud usage
- Optimize storage usage
- Consider reserved instances for cost savings

## Support and Documentation

### Migration Logs
- All migration steps logged to: $OutputPath
- Configuration backups stored in: C:\backup\
- Oracle Cloud configuration in: $OracleConfigPath

### Contact Information
- Oracle Cloud Support: https://support.oracle.com
- ScreenConnect Support: https://docs.connectwise.com
- Migration Documentation: See README.md

---

**Important:** This migration requires careful attention to detail. Always test changes in a non-production environment first.
"@

    $mergePlan | Out-File -FilePath $OutputFile -Encoding UTF8
    Write-Log "Migration merge plan written to: $OutputFile" "SUCCESS"
}

# Function to create configuration comparison report
function New-ConfigurationComparison {
    param(
        [string]$SourcePath,
        [string]$TargetPath,
        [string]$OutputFile
    )
    
    Write-Log "Creating configuration comparison report..." "INFO"
    
    $comparison = @{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        SourcePath = $SourcePath
        TargetPath = $TargetPath
        Files = @()
    }
    
    try {
        # Compare common configuration files
        $configFiles = @(
            "App_Web.config",
            "ScreenConnect.Service.exe.config",
            "web.config",
            "appsettings.json"
        )
        
        foreach ($file in $configFiles) {
            $sourceFile = Join-Path $SourcePath $file
            $targetFile = Join-Path $TargetPath $file
            
            if (Test-Path $sourceFile) {
                $fileComparison = Compare-Configurations -SourceConfig $sourceFile -TargetConfig $targetFile -ConfigType $file
                $comparison.Files += $fileComparison
            }
        }
        
        # Generate comparison report
        $report = @"
# Configuration Comparison Report
# Generated on: $($comparison.Timestamp)

## Comparison Summary
- Source Path: $($comparison.SourcePath)
- Target Path: $($comparison.TargetPath)
- Files Analyzed: $($comparison.Files.Count)

## File-by-File Analysis
"@

        foreach ($file in $comparison.Files) {
            $report += "`n`n### $($file.Type)"
            $report += "`n- Source: $($file.SourceFile)"
            $report += "`n- Target: $($file.TargetFile)"
            
            if ($file.Differences.Count -gt 0) {
                $report += "`n- **Status:** ⚠ Differences Found"
                $report += "`n- Differences: $($file.Differences -join ', ')"
            } else {
                $report += "`n- **Status:** ✓ Identical"
            }
            
            if ($file.Recommendations.Count -gt 0) {
                $report += "`n- Recommendations: $($file.Recommendations -join ', ')"
            }
        }
        
        $report | Out-File -FilePath $OutputFile -Encoding UTF8
        Write-Log "Configuration comparison report written to: $OutputFile" "SUCCESS"
    }
    catch {
        Write-Log "Error creating configuration comparison: $($_.Exception.Message)" "ERROR"
    }
}

# Main execution
Write-Log "=== AWS to Oracle Cloud Migration Assistant ===" "INFO"
Write-Log "Focus: Careful file merging and configuration comparison" "INFO"

switch ($Action.ToLower()) {
    "analyze" {
        if ([string]::IsNullOrEmpty($SourceServer)) {
            Write-Log "Usage: .\aws-migration-assistant.ps1 -Action analyze -SourceServer 'your-aws-server.com'" "ERROR"
            exit 1
        }
        
        Write-Log "Analyzing AWS server: $SourceServer" "INFO"
        
        # Analyze AWS configurations
        $awsConfigs = Analyze-AWSConfigurations -SourceServer $SourceServer
        
        # Create migration merge plan
        $mergePlanPath = "aws-migration-merge-plan.md"
        New-MigrationMergePlan -AWSConfigs $awsConfigs -OracleConfigs @{} -OutputFile $mergePlanPath
        
        Write-Log "Analysis completed. Review: $mergePlanPath" "SUCCESS"
    }
    
    "compare" {
        if ([string]::IsNullOrEmpty($SourceBackupPath) -or [string]::IsNullOrEmpty($OracleConfigPath)) {
            Write-Log "Usage: .\aws-migration-assistant.ps1 -Action compare -SourceBackupPath 'path\to\aws\backup' -OracleConfigPath 'path\to\oracle\config'" "ERROR"
            exit 1
        }
        
        Write-Log "Comparing AWS backup with Oracle Cloud configuration..." "INFO"
        
        # Create configuration comparison
        $comparisonPath = "configuration-comparison.md"
        New-ConfigurationComparison -SourcePath $SourceBackupPath -TargetPath $OracleConfigPath -OutputFile $comparisonPath
        
        Write-Log "Comparison completed. Review: $comparisonPath" "SUCCESS"
    }
    
    "merge" {
        if ([string]::IsNullOrEmpty($SourceBackupPath) -or [string]::IsNullOrEmpty($OracleConfigPath)) {
            Write-Log "Usage: .\aws-migration-assistant.ps1 -Action merge -SourceBackupPath 'path\to\aws\backup' -OracleConfigPath 'path\to\oracle\config'" "ERROR"
            exit 1
        }
        
        Write-Log "Starting configuration merge process..." "INFO"
        
        if ($Interactive) {
            $confirm = Read-Host "This will merge AWS configurations with Oracle Cloud. Continue? (y/N)"
            if ($confirm -ne "y" -and $confirm -ne "Y") {
                Write-Log "Merge cancelled by user" "INFO"
                exit 0
            }
        }
        
        # Create merge plan
        $mergePlanPath = "configuration-merge-plan.md"
        New-MigrationMergePlan -AWSConfigs @{} -OracleConfigs @{} -OutputFile $mergePlanPath
        
        Write-Log "Merge plan created. Review: $mergePlanPath" "SUCCESS"
        Write-Log "Manual review and merge required for AWS-specific configurations" "WARNING"
    }
    
    default {
        Write-Log "Usage:" "INFO"
        Write-Log "  .\aws-migration-assistant.ps1 -Action analyze -SourceServer 'your-aws-server.com'" "INFO"
        Write-Log "  .\aws-migration-assistant.ps1 -Action compare -SourceBackupPath 'path\to\aws\backup' -OracleConfigPath 'path\to\oracle\config'" "INFO"
        Write-Log "  .\aws-migration-assistant.ps1 -Action merge -SourceBackupPath 'path\to\aws\backup' -OracleConfigPath 'path\to\oracle\config'" "INFO"
        Write-Log "" "INFO"
        Write-Log "Actions:" "INFO"
        Write-Log "  analyze  - Analyze AWS server for migration requirements" "INFO"
        Write-Log "  compare  - Compare AWS backup with Oracle Cloud configuration" "INFO"
        Write-Log "  merge    - Create merge plan for configuration migration" "INFO"
    }
}

Write-Log "=== Migration Notes ===" "INFO"
Write-Log "• Always backup before making changes" "INFO"
Write-Log "• Test configurations in non-production environment" "INFO"
Write-Log "• Document all custom settings before migration" "INFO"
Write-Log "• Plan for 2-4 hours of downtime during cutover" "INFO"
Write-Log "• Have rollback plan ready" "INFO" 