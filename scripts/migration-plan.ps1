# ScreenConnect Migration Planning Tool
# AWS to Oracle Cloud Migration Assistant

param(
    [string]$Action = "plan",
    [string]$SourceServer = "",
    [string]$SourceAdminPassword = "",
    [string]$SourceBackupPath = "",
    [switch]$DryRun = $true,
    [switch]$IncludeCustomizations = $true,
    [string]$OutputPath = "migration-plan.txt"
)

# Function to validate source server connectivity
function Test-SourceServerConnectivity {
    param([string]$Server)
    
    Write-Host "Testing connectivity to source server: $Server" -ForegroundColor Cyan
    
    try {
        # Test basic connectivity
        $ping = Test-Connection -ComputerName $Server -Count 1 -Quiet
        if (-not $ping) {
            Write-Error "Cannot reach source server: $Server"
            return $false
        }
        
        # Test HTTPS connectivity
        $httpsTest = Invoke-WebRequest -Uri "https://$Server" -TimeoutSec 10 -UseBasicParsing
        if ($httpsTest.StatusCode -eq 200) {
            Write-Host "✓ HTTPS connectivity confirmed" -ForegroundColor Green
        }
        
        return $true
    }
    catch {
        Write-Warning "Connectivity test failed: $($_.Exception.Message)"
        return $false
    }
}

# Function to gather source server information
function Get-SourceServerInfo {
    param([string]$Server, [string]$AdminPassword)
    
    Write-Host "`nGathering source server information..." -ForegroundColor Cyan
    
    $serverInfo = @{
        ServerName = $Server
        ScreenConnectVersion = "Unknown"
        IISVersion = "Unknown"
        SSLConfiguration = @()
        CustomSettings = @()
        DatabaseInfo = "Unknown"
        BackupLocation = ""
        CustomFiles = @()
    }
    
    try {
        # Try to get ScreenConnect version via API
        $versionUrl = "https://$Server/ScreenConnect/Info"
        $versionResponse = Invoke-WebRequest -Uri $versionUrl -UseBasicParsing -ErrorAction SilentlyContinue
        if ($versionResponse) {
            $serverInfo.ScreenConnectVersion = $versionResponse.Content
        }
        
        # Check for common customizations
        $customPaths = @(
            "/ScreenConnect/App_Data/Custom",
            "/ScreenConnect/App_Data/Logs",
            "/ScreenConnect/App_Data/Config"
        )
        
        foreach ($path in $customPaths) {
            $customUrl = "https://$Server$path"
            try {
                $response = Invoke-WebRequest -Uri $customUrl -UseBasicParsing -ErrorAction SilentlyContinue
                if ($response) {
                    $serverInfo.CustomFiles += $path
                }
            }
            catch {
                # Path doesn't exist or not accessible
            }
        }
        
        Write-Host "✓ Source server information gathered" -ForegroundColor Green
    }
    catch {
        Write-Warning "Could not gather complete server information: $($_.Exception.Message)"
    }
    
    return $serverInfo
}

# Function to create migration plan
function New-MigrationPlan {
    param(
        [hashtable]$SourceInfo,
        [string]$OutputFile
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    $plan = @"
# ScreenConnect Migration Plan
# Generated on: $timestamp
# Source: $($SourceInfo.ServerName)
# Target: Oracle Cloud Infrastructure

## Migration Overview
This plan outlines the migration from AWS-hosted ScreenConnect to Oracle Cloud.

## Pre-Migration Checklist

### 1. Source Server Assessment
- [ ] Source server: $($SourceInfo.ServerName)
- [ ] ScreenConnect version: $($SourceInfo.ScreenConnectVersion)
- [ ] IIS configuration documented
- [ ] SSL certificates identified
- [ ] Custom configurations identified
- [ ] Database backup created
- [ ] User sessions scheduled for downtime

### 2. Oracle Cloud Preparation
- [ ] Oracle Cloud account configured
- [ ] API keys generated
- [ ] Compartment created
- [ ] Terraform configuration prepared
- [ ] DNS records prepared for cutover
- [ ] SSL certificates ready for new domain

### 3. Network Configuration
- [ ] DNS records for new domains:
  - remotesupport.yourdomain.com (web UI)
- relay.yourdomain.com (relay protocol)
- [ ] Cloudflare configuration prepared
- [ ] RDP access configured for your IPs
- [ ] Firewall rules documented

## Migration Steps

### Phase 1: Preparation (1-2 days before)
1. Create full backup of source server
2. Document all custom configurations
3. Prepare Oracle Cloud environment
4. Test new environment with sample data

### Phase 2: Deployment (Day of migration)
1. Deploy Oracle Cloud infrastructure
2. Restore ScreenConnect from backup
3. Configure SSL certificates
4. Update DNS records
5. Test functionality

### Phase 3: Cutover (Scheduled downtime)
1. Stop services on source server
2. Final data synchronization
3. Update DNS to point to new server
4. Start services on new server
5. Verify all functionality

### Phase 4: Validation (Post-migration)
1. Test all ScreenConnect features
2. Verify SSL certificates
3. Check backup functionality
4. Monitor performance
5. Update documentation

## Risk Mitigation

### High Risk Items
- Data loss during migration
- SSL certificate issues
- DNS propagation delays
- Custom configuration loss

### Mitigation Strategies
- Multiple backup copies
- Parallel environment testing
- DNS TTL reduction before migration
- Detailed configuration documentation
- Rollback plan prepared

## Rollback Plan

If issues occur during migration:
1. Revert DNS records to source server
2. Restart services on source server
3. Investigate issues in Oracle Cloud environment
4. Fix issues and retry migration

## Post-Migration Tasks

### Immediate (Day 1)
- [ ] Verify all ScreenConnect functionality
- [ ] Test SSL certificates
- [ ] Check backup system
- [ ] Monitor performance
- [ ] Update user documentation

### Short Term (Week 1)
- [ ] Performance optimization
- [ ] Security hardening
- [ ] Monitoring setup
- [ ] User training if needed
- [ ] Documentation updates

### Long Term (Month 1)
- [ ] Decommission AWS resources
- [ ] Cost analysis and optimization
- [ ] Performance review
- [ ] Security audit
- [ ] Backup strategy review

## Custom Configurations to Migrate

Based on source server analysis:
"@

    if ($SourceInfo.CustomFiles.Count -gt 0) {
        $plan += "`n`n### Custom Files Found:`n"
        foreach ($file in $SourceInfo.CustomFiles) {
            $plan += "- $file`n"
        }
    } else {
        $plan += "`n`n### Custom Files: None detected`n"
    }

    $plan += @"

## SSL Certificate Migration

### Current Certificates
- [ ] Identify all SSL certificates in use
- [ ] Export certificates and private keys
- [ ] Note certificate expiration dates
- [ ] Plan for certificate renewal

### New Certificate Strategy
- [ ] Let's Encrypt certificates for new domains
- [ ] Cloudflare SSL configuration
- [ ] Certificate auto-renewal setup

## Database Migration

### Backup Strategy
- [ ] Full ScreenConnect backup
- [ ] Database backup (if separate)
- [ ] Configuration backup
- [ ] Custom files backup

### Restore Process
- [ ] Restore to Oracle Cloud instance
- [ ] Update connection strings
- [ ] Verify data integrity
- [ ] Test all functionality

## Network Considerations

### DNS Changes
- [ ] Reduce TTL before migration
- [ ] Prepare DNS records for new server
- [ ] Plan for DNS propagation time
- [ ] Monitor DNS resolution

### SSL/TLS Configuration
- [ ] Configure Cloudflare SSL mode
- [ ] Set up Let's Encrypt certificates
- [ ] Test SSL configuration
- [ ] Verify certificate chain

## Monitoring and Validation

### Key Metrics to Monitor
- [ ] Response times
- [ ] Connection success rates
- [ ] SSL certificate status
- [ ] Backup success rates
- [ ] System resource usage

### Validation Checklist
- [ ] Web UI accessible
- [ ] Relay protocol working
- [ ] SSL certificates valid
- [ ] Backups running
- [ ] Performance acceptable
- [ ] All custom features working

## Communication Plan

### Stakeholders to Notify
- [ ] IT team
- [ ] End users
- [ ] Management
- [ ] Support team

### Communication Timeline
- [ ] 1 week before: Initial notification
- [ ] 1 day before: Reminder
- [ ] Day of: Status updates
- [ ] Post-migration: Success notification

## Success Criteria

Migration will be considered successful when:
- [ ] All ScreenConnect features working
- [ ] Performance meets or exceeds source
- [ ] SSL certificates properly configured
- [ ] Backups running successfully
- [ ] Users can access system normally
- [ ] Monitoring shows healthy status

## Notes

- Estimated downtime: 2-4 hours
- Rollback time: 30 minutes
- DNS propagation: Up to 24 hours (typically 1-2 hours)
- Testing time: 1-2 days post-migration

"@

    $plan | Out-File -FilePath $OutputFile -Encoding UTF8
    Write-Host "Migration plan written to: $OutputFile" -ForegroundColor Green
}

# Function to create backup script
function New-BackupScript {
    param([string]$SourceServer, [string]$OutputFile)
    
    $backupScript = @"
# ScreenConnect Backup Script for Migration
# Source Server: $SourceServer
# Generated on: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

Write-Host "Starting ScreenConnect backup for migration..." -ForegroundColor Green

# Create backup directory
`$backupDir = "C:\ScreenConnect-Migration-Backup-`$(Get-Date -Format 'yyyy-MM-dd-HHmm')"
New-Item -ItemType Directory -Path `$backupDir -Force | Out-Null

Write-Host "Backup directory: `$backupDir" -ForegroundColor Cyan

# Stop ScreenConnect services
Write-Host "Stopping ScreenConnect services..." -ForegroundColor Yellow
Stop-Service -Name "ScreenConnect" -Force -ErrorAction SilentlyContinue
Stop-Service -Name "ScreenConnectRelay" -Force -ErrorAction SilentlyContinue

# Wait for services to stop
Start-Sleep -Seconds 10

# Backup ScreenConnect installation
Write-Host "Backing up ScreenConnect installation..." -ForegroundColor Yellow
`$screenConnectPath = "C:\Program Files (x86)\ScreenConnect"
if (Test-Path `$screenConnectPath) {
    Copy-Item -Path `$screenConnectPath -Destination "`$backupDir\ScreenConnect" -Recurse -Force
    Write-Host "✓ ScreenConnect files backed up" -ForegroundColor Green
} else {
    Write-Warning "ScreenConnect installation not found at expected location"
}

# Backup IIS configuration
Write-Host "Backing up IIS configuration..." -ForegroundColor Yellow
`$iisConfigPath = "C:\Windows\System32\inetsrv\config"
if (Test-Path `$iisConfigPath) {
    Copy-Item -Path `$iisConfigPath -Destination "`$backupDir\IIS-Config" -Recurse -Force
    Write-Host "✓ IIS configuration backed up" -ForegroundColor Green
}

# Export IIS sites and applications
Write-Host "Exporting IIS configuration..." -ForegroundColor Yellow
`$iisExportPath = "`$backupDir\IIS-Export"
New-Item -ItemType Directory -Path `$iisExportPath -Force | Out-Null

# Export application pools
Get-IISAppPool | ForEach-Object {
    `$poolName = `$_.Name
    `$_.GetConfiguration() | Export-WebConfiguration -FilePath "`$iisExportPath\AppPool-`$poolName.xml"
}

# Export sites
Get-IISWebsite | ForEach-Object {
    `$siteName = `$_.Name
    `$_.GetConfiguration() | Export-WebConfiguration -FilePath "`$iisExportPath\Site-`$siteName.xml"
}

Write-Host "✓ IIS configuration exported" -ForegroundColor Green

# Backup SSL certificates
Write-Host "Backing up SSL certificates..." -ForegroundColor Yellow
`$certBackupPath = "`$backupDir\Certificates"
New-Item -ItemType Directory -Path `$certBackupPath -Force | Out-Null

# Export certificates from personal store
Get-ChildItem -Path Cert:\LocalMachine\My | ForEach-Object {
    `$certName = `$_.Subject -replace '[^a-zA-Z0-9]', '_'
    `$certPath = "`$certBackupPath\`$certName.cer"
    `$_.Export('Cert') | Out-File -FilePath `$certPath -Encoding Binary
}

# Export private keys (if accessible)
Get-ChildItem -Path Cert:\LocalMachine\My | ForEach-Object {
    try {
        `$certName = `$_.Subject -replace '[^a-zA-Z0-9]', '_'
        `$pfxPath = "`$certBackupPath\`$certName.pfx"
        `$_.Export('PFX', 'password123') | Out-File -FilePath `$pfxPath -Encoding Binary
    }
    catch {
        Write-Warning "Could not export private key for certificate: `$(`$_.Subject)"
    }
}

Write-Host "✓ SSL certificates backed up" -ForegroundColor Green

# Backup Windows Registry (ScreenConnect related)
Write-Host "Backing up registry settings..." -ForegroundColor Yellow
`$regBackupPath = "`$backupDir\Registry"
New-Item -ItemType Directory -Path `$regBackupPath -Force | Out-Null

# Export ScreenConnect registry keys
`$regKeys = @(
    "HKLM:\SOFTWARE\ScreenConnect",
    "HKLM:\SOFTWARE\WOW6432Node\ScreenConnect"
)

foreach (`$key in `$regKeys) {
    if (Test-Path `$key) {
        `$keyName = `$key.Split('\')[-1]
        reg export `$key "`$regBackupPath\`$keyName.reg" /y | Out-Null
    }
}

Write-Host "✓ Registry settings backed up" -ForegroundColor Green

# Create system information report
Write-Host "Creating system information report..." -ForegroundColor Yellow
`$sysInfoPath = "`$backupDir\System-Info.txt"

`$sysInfo = @"
ScreenConnect Migration Backup Report
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Source Server: $SourceServer

System Information:
- OS Version: `$((Get-WmiObject -Class Win32_OperatingSystem).Caption)
- ScreenConnect Version: `$(Get-ItemProperty -Path "HKLM:\SOFTWARE\ScreenConnect" -Name "Version" -ErrorAction SilentlyContinue).Version
- IIS Version: `$(Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\InetStp" -Name "MajorVersion" -ErrorAction SilentlyContinue).MajorVersion

Installed Services:
`$(Get-Service | Where-Object {`$_.Name -like "*ScreenConnect*"} | ForEach-Object {"- `$(`$_.Name): `$(`$_.Status)"})

IIS Sites:
`$(Get-IISWebsite | ForEach-Object {"- `$(`$_.Name): `$(`$_.State)"})

SSL Certificates:
`$(Get-ChildItem -Path Cert:\LocalMachine\My | ForEach-Object {"- `$(`$_.Subject) (Expires: `$(`$_.NotAfter))"})

"@

`$sysInfo | Out-File -FilePath `$sysInfoPath -Encoding UTF8
Write-Host "✓ System information report created" -ForegroundColor Green

# Restart ScreenConnect services
Write-Host "Restarting ScreenConnect services..." -ForegroundColor Yellow
Start-Service -Name "ScreenConnect" -ErrorAction SilentlyContinue
Start-Service -Name "ScreenConnectRelay" -ErrorAction SilentlyContinue

# Create compressed backup
Write-Host "Creating compressed backup archive..." -ForegroundColor Yellow
`$archivePath = "`$backupDir.zip"
Compress-Archive -Path `$backupDir -DestinationPath `$archivePath -Force

Write-Host "✓ Backup completed successfully!" -ForegroundColor Green
Write-Host "Backup location: `$archivePath" -ForegroundColor Cyan
Write-Host "Backup size: `$((Get-Item `$archivePath).Length / 1MB) MB" -ForegroundColor Cyan

# Cleanup temporary directory
Remove-Item -Path `$backupDir -Recurse -Force

Write-Host "`nNext steps:" -ForegroundColor Green
Write-Host "1. Copy the backup file to a secure location" -ForegroundColor White
Write-Host "2. Test the backup on a test environment" -ForegroundColor White
Write-Host "3. Proceed with Oracle Cloud deployment" -ForegroundColor White
"@

    $backupScript | Out-File -FilePath $OutputFile -Encoding UTF8
    Write-Host "Backup script written to: $OutputFile" -ForegroundColor Green
}

# Function to create restore script
function New-RestoreScript {
    param([string]$BackupPath, [string]$OutputFile)
    
    # Generate restore script
    $restoreScriptContent = @"
# Restore ScreenConnect from backup
# This script is generated by migration-plan.ps1

param(
    [Parameter(Mandatory=`$true)]
    [string]`$BackupPath,
    
    [Parameter(Mandatory=`$false)]
    [string]`$ScreenConnectPath = "C:\Program Files (x86)\ScreenConnect"
)

Write-Host "Restoring ScreenConnect from backup..." -ForegroundColor Cyan

# Stop ScreenConnect services
Get-Service -Name "ScreenConnect*" | Stop-Service -Force

# Extract backup
Expand-Archive -Path `$BackupPath -DestinationPath "C:\temp\screenconnect-restore" -Force

# Restore files (customize based on your backup structure)
# Copy-Item -Path "C:\temp\screenconnect-restore\*" -Destination `$ScreenConnectPath -Recurse -Force

# Start services
Get-Service -Name "ScreenConnect*" | Start-Service

Write-Host "Restore completed. Please verify ScreenConnect is working correctly." -ForegroundColor Green
"@

    $restoreScriptContent | Out-File -FilePath $OutputFile -Encoding UTF8
    Write-Host "Restore script written to: $OutputFile" -ForegroundColor Green
}

# Main execution
Write-Host "=== ScreenConnect Migration Planning Tool ===" -ForegroundColor Green
Write-Host "AWS to Oracle Cloud Migration Assistant" -ForegroundColor Yellow

switch ($Action.ToLower()) {
    "plan" {
        if ([string]::IsNullOrEmpty($SourceServer)) {
            Write-Host "`nUsage:" -ForegroundColor Green
            Write-Host "  .\migration-plan.ps1 -Action plan -SourceServer 'your-aws-server.com'" -ForegroundColor White
            Write-Host "  .\migration-plan.ps1 -Action backup -SourceServer 'your-aws-server.com'" -ForegroundColor White
            Write-Host "  .\migration-plan.ps1 -Action restore -SourceBackupPath 'path\to\backup.zip'" -ForegroundColor White
            exit 1
        }
        
        Write-Host "`nCreating migration plan for: $SourceServer" -ForegroundColor Cyan
        
        # Test connectivity
        if (-not (Test-SourceServerConnectivity -Server $SourceServer)) {
            Write-Error "Cannot connect to source server. Please check connectivity and try again."
            exit 1
        }
        
        # Gather server information
        $serverInfo = Get-SourceServerInfo -Server $SourceServer -AdminPassword $SourceAdminPassword
        
        # Create migration plan
        New-MigrationPlan -SourceInfo $serverInfo -OutputFile $OutputPath
        
        Write-Host "`nMigration planning completed!" -ForegroundColor Green
        Write-Host "Review the plan at: $OutputPath" -ForegroundColor Cyan
    }
    
    "backup" {
        if ([string]::IsNullOrEmpty($SourceServer)) {
            Write-Error "SourceServer parameter is required for backup action"
            exit 1
        }
        
        Write-Host "`nCreating backup script for: $SourceServer" -ForegroundColor Cyan
        $backupScriptPath = "backup-screenconnect.ps1"
        New-BackupScript -SourceServer $SourceServer -OutputFile $backupScriptPath
        
        Write-Host "`nBackup script created: $backupScriptPath" -ForegroundColor Green
        Write-Host "Run this script on your AWS server to create a backup." -ForegroundColor Cyan
    }
    
    "restore" {
        if ([string]::IsNullOrEmpty($SourceBackupPath)) {
            Write-Error "SourceBackupPath parameter is required for restore action"
            exit 1
        }
        
        Write-Host "`nCreating restore script for backup: $SourceBackupPath" -ForegroundColor Cyan
        $restoreScriptPath = "restore-screenconnect.ps1"
        New-RestoreScript -BackupPath $SourceBackupPath -OutputFile $restoreScriptPath
        
        Write-Host "`nRestore script created: $restoreScriptPath" -ForegroundColor Green
        Write-Host "Run this script on your Oracle Cloud instance after deployment." -ForegroundColor Cyan
    }
    
    default {
        Write-Host "`nUsage:" -ForegroundColor Green
        Write-Host "  .\migration-plan.ps1 -Action plan -SourceServer 'your-aws-server.com'" -ForegroundColor White
        Write-Host "  .\migration-plan.ps1 -Action backup -SourceServer 'your-aws-server.com'" -ForegroundColor White
        Write-Host "  .\migration-plan.ps1 -Action restore -SourceBackupPath 'path\to\backup.zip'" -ForegroundColor White
        Write-Host "`nActions:" -ForegroundColor Green
        Write-Host "  plan     - Create comprehensive migration plan" -ForegroundColor White
        Write-Host "  backup   - Generate backup script for source server" -ForegroundColor White
        Write-Host "  restore  - Generate restore script for Oracle Cloud" -ForegroundColor White
    }
}

Write-Host "`n=== Migration Notes ===" -ForegroundColor Yellow
Write-Host "• Plan for 2-4 hours of downtime during migration" -ForegroundColor White
Write-Host "• Test the migration process in a non-production environment first" -ForegroundColor White
Write-Host "• Ensure all custom configurations are documented" -ForegroundColor White
Write-Host "• Have a rollback plan ready" -ForegroundColor White
Write-Host "• Coordinate with users for scheduled downtime" -ForegroundColor White 