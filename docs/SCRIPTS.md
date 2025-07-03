# Scripts Documentation

This document provides an overview of all scripts in the Oracle Cloud ScreenConnect deployment.

## 📁 Script Categories

### 🔧 **Setup & Configuration**
- **`setup-secure-config.ps1`** - Create secure configuration files
- **`validate-prerequisites.ps1`** - Validate deployment prerequisites
- **`validate-deployment.ps1`** - Validate deployment configuration
- **`create-environment.ps1`** - Create new deployment environments

### 🔒 **Security & Hardening**
- **`harden-windows.ps1`** - Windows Server hardening automation
- **`validate-secrets.ps1`** - Validate secrets configuration
- **`manage-secrets.ps1`** - Manage Oracle Vault secrets
- **`setup-secrets.ps1`** - Initial secrets setup

### 🔄 **Maintenance & Updates**
- **`maintenance.ps1`** - Comprehensive maintenance automation
- **`update-screenconnect.ps1`** - ScreenConnect version updates
- **`ssl-management.ps1`** - SSL certificate management
- **`configure-ssl-redirect.ps1`** - HTTP to HTTPS redirect setup
- **`run-maintenance.bat`** - Easy maintenance execution interface

### 💾 **Backup & Recovery**
- **`scheduled-backup.ps1`** - Automated backup system
- **`manage-secrets.bat`** - Batch interface for secrets management

### 🌐 **Network & Connectivity**
- **`get-home-ips.ps1`** - Get current home IP addresses
- **`get-home-ips.bat`** - Batch interface for IP detection

### 🚀 **Release Management**
- **`release.ps1`** - Release automation and versioning

### 🔄 **Migration Tools**
- **`backup-screenconnect-simple.ps1`** - **Working backup script** for AWS server
- **`restore-screenconnect-simple.ps1`** - **Working restore script** for Oracle Cloud
- **`migration-plan.ps1`** - AWS to Oracle Cloud migration planning (⚠️ has syntax issues)
- **`aws-migration-assistant.ps1`** - Advanced migration configuration comparison

## 📋 **Script Usage Examples**

### Initial Setup
```powershell
# Validate prerequisites
.\scripts\validate-prerequisites.ps1

# Create secure configuration
.\scripts\setup-secure-config.ps1 -Environment "production" -Interactive

# Validate deployment
.\scripts\validate-deployment.ps1 -Environment "production"
```

### Security Hardening
```powershell
# Harden Windows VM (run as Administrator)
.\scripts\harden-windows.ps1

# Validate secrets
.\scripts\validate-secrets.ps1 -Environment "production" -Verbose
```

### Maintenance
```powershell
# Run comprehensive maintenance
.\scripts\maintenance.ps1 -Action "all"

# Update ScreenConnect
.\scripts\update-screenconnect.ps1 -NewVersion "24.2.0.8811"

# Manage SSL certificates
.\scripts\ssl-management.ps1 -Domain "remotesupport.yourdomain.com" -Email "admin@yourdomain.com"
```

### Migration
```powershell
# Create backup on AWS server
.\scripts\backup-screenconnect-simple.ps1

# Restore on Oracle Cloud instance
.\scripts\restore-screenconnect-simple.ps1 -BackupPath "C:\path\to\backup-file.zip"

# Compare configurations (advanced)
.\scripts\aws-migration-assistant.ps1 -SourceConfig "aws-config.json" -TargetConfig "oracle-config.json"
```

## 🔧 **Script Parameters**

### Common Parameters
- **`-Environment`** - Target environment (production, staging, development)
- **`-Verbose`** - Enable verbose output
- **`-DryRun`** - Show what would be done without making changes
- **`-Force`** - Skip confirmation prompts

### Security Parameters
- **`-Domain`** - Target domain for SSL certificates
- **`-Email`** - Email for Let's Encrypt notifications
- **`-ForceRenewal`** - Force SSL certificate renewal

### Migration Parameters
- **`-SourceServer`** - Source AWS server hostname/IP
- **`-SourceBackupPath`** - Path to backup file
- **`-Action`** - Migration action (plan, backup, restore)

## 📚 **Related Documentation**

- **[Deployment Guide](../DEPLOYMENT_GUIDE.md)** - Step-by-step deployment instructions
- **[Security Guide](SECURITY_GUIDE.md)** - Security configuration and best practices
- **[Windows Hardening Guide](WINDOWS_HARDENING.md)** - Windows Server hardening
- **[AWS Migration Guide](AWS_MIGRATION.md)** - Migration from AWS to Oracle Cloud
- **[Update Guide](../UPDATE_GUIDE.md)** - Version updates and release management

## 🛠️ **Troubleshooting**

### Common Issues
1. **Execution Policy** - Use `-ExecutionPolicy RemoteSigned` for PowerShell scripts
2. **Permissions** - Some scripts require Administrator privileges
3. **Network Access** - Ensure internet connectivity for SSL and updates
4. **Oracle Cloud CLI** - Install and configure OCI CLI for cloud operations

### Log Files
- **Maintenance Log:** `C:\screenconnect_maintenance_log.txt`
- **SSL Management Log:** `C:\ssl_management_log.txt`
- **Backup Log:** `C:\backup_log.txt`
- **Validation Log:** `C:\validation_log.txt`

## 🔄 **Script Dependencies**

### Required Tools
- **PowerShell 5.1+** - All PowerShell scripts
- **Terraform** - Infrastructure deployment
- **Oracle Cloud CLI** - Cloud operations
- **Cloudflare API** - DNS management
- **Win-Acme** - SSL certificate management

### Optional Tools
- **Git** - Version control
- **7-Zip** - Backup compression
- **Chocolatey** - Package management

---

**For detailed usage of individual scripts, see the inline documentation in each script file.** 