# AWS to Oracle Cloud Migration Guide

This guide explains how to migrate your ScreenConnect deployment from AWS to Oracle Cloud Infrastructure (OCI) using the provided automation, scripts, and best practices. The process is designed to ensure a careful, secure migration that preserves all customizations and avoids direct file replacement.

---

## Overview

- **Careful merge, not direct copy:** The migration process identifies customizations and configuration differences, and guides you through a careful merge rather than a direct overwrite.
- **Automated planning:** Scripts generate a migration plan, backup, and restore scripts tailored to your environment.
- **Validation and rollback:** The process includes validation steps and a rollback plan for safety.

---

## Prerequisites

- Access to your AWS ScreenConnect server (RDP/PowerShell)
- Oracle Cloud account with API access
- Cloudflare account (for DNS)
- ScreenConnect license key
- PowerShell 5.1+ on your management workstation

---

## Migration Steps

### 1. Backup Your AWS Server

On your AWS ScreenConnect server, run the backup script:

```powershell
# On AWS server
cd C:\path\to\scripts

# Create a backup using the working script
.\backup-screenconnect-simple.ps1
```

- This will create a full backup of your ScreenConnect installation, including:
  - ScreenConnect files and configuration
  - IIS configuration and sites
  - SSL certificates
  - Registry settings
  - System information report
- Copy the backup file to a secure location and verify its integrity.

---

### 2. Prepare Oracle Cloud Environment

On your management workstation:

```powershell
# Validate prerequisites
.\scripts\validate-prerequisites.ps1

# Setup secure configuration for Oracle Cloud
.\scripts\setup-secure-config.ps1 -Environment 'production' -Interactive

# Edit terraform.tfvars with your actual values (tenancy OCID, domains, etc.)
```

- Follow the prompts to configure your Oracle Cloud environment.
- Ensure all required variables and secrets are set.

---

### 3. Deploy Oracle Cloud Infrastructure

In the `environments/production` directory:

```bash
terraform init
terraform plan
terraform apply
```

- This will provision the Windows VM, networking, storage, and secrets management in Oracle Cloud.

---

### 4. Restore ScreenConnect on Oracle Cloud

Copy your AWS backup file to the new Oracle Cloud VM (via RDP, WinSCP, etc.).

On the Oracle Cloud VM:

```powershell
# Run the restore script
cd C:\path\to\scripts

# Restore from backup
.\restore-screenconnect-simple.ps1 -BackupPath "C:\path\to\your-backup-file.zip"
```

- This will extract the backup and restore ScreenConnect, custom files, and configurations.
- The script will automatically update configuration for Oracle Cloud environment.

---

### 5. Update DNS and SSL

- Update your Cloudflare DNS records to point to the new Oracle Cloud VM.
- Run the SSL management script to issue/renew certificates:

```powershell
.\scripts\ssl-management.ps1 -Domain 'remotesupport.yourdomain.com' -Email 'admin@yourdomain.com'
```

---

### 6. Validate and Cut Over

- Test all ScreenConnect functionality on the new server.
- Validate SSL, RDP, and backup systems.
- Schedule downtime and perform the final cutover:
  - Stop services on AWS
  - Final sync/backup if needed
  - Update DNS
  - Start services on Oracle Cloud

---

### 7. Post-Migration Tasks

- Monitor the new deployment for issues
- Update documentation
- Decommission AWS resources when ready

---

### 8. Advanced: Manual Merge (if needed)

If you need to manually merge customizations:

```powershell
# On your management workstation
.\scripts\aws-migration-assistant.ps1 -Action compare -SourceBackupPath 'C:\path\to\aws\backup' -OracleConfigPath 'C:\path\to\oracle\config'
```

- Review the generated comparison report.
- Manually merge custom settings, connection strings, and SSL configs as needed.

---

## Rollback Plan

If issues occur:
- Revert DNS to AWS
- Restore services on AWS
- Investigate and retry migration as needed

---

## Advanced: Automated Merge Planning

You can use the `aws-migration-assistant.ps1` script for advanced analysis and merge planning:

```powershell
# Analyze AWS server for migration requirements
./aws-migration-assistant.ps1 -Action analyze -SourceServer 'your-aws-server.com'

# Create a merge plan for configuration migration
./aws-migration-assistant.ps1 -Action merge -SourceBackupPath 'C:\path\to\aws\backup' -OracleConfigPath 'C:\path\to\oracle\config'
```

---

## References

The following scripts are provided to assist with migration:

- [backup-screenconnect-simple.ps1](../scripts/backup-screenconnect-simple.ps1): **Working backup script** for AWS server
- [restore-screenconnect-simple.ps1](../scripts/restore-screenconnect-simple.ps1): **Working restore script** for Oracle Cloud
- [aws-migration-assistant.ps1](../scripts/aws-migration-assistant.ps1): Advanced config comparison/merge tool
- [ssl-management.ps1](../scripts/ssl-management.ps1): SSL certificate management
- [setup-secure-config.ps1](../scripts/setup-secure-config.ps1): Secure config setup
- [validate-deployment.ps1](../scripts/validate-deployment.ps1): Deployment validation

**Note:** The `migration-plan.ps1` script has syntax issues and is not recommended for use. Use the simple backup/restore scripts instead.

---

**Always test in a non-production environment first.**

For questions, see the main README or contact project maintainers. 