# Update and Release Management Guide

This guide covers how to manage updates, releases, and version changes in the ScreenConnect deployment.

## Overview

The repository now includes comprehensive automation for:
- **Version Management**: Automated ScreenConnect version updates
- **Release Process**: Streamlined release creation and deployment
- **Environment Management**: Easy creation of new environments
- **Validation**: Pre-deployment validation and security checks

## Version Management

### Current Version

The current ScreenConnect version is tracked in:
- `VERSION` file (single source of truth)
- `modules/compute/user_data.tpl` (download URL)
- `CHANGELOG.md` (version history)

### Updating ScreenConnect Version

#### Automated Update

```powershell
# Update to a new version
.\scripts\update-screenconnect.ps1 -NewVersion "24.2.0.8811"

# Dry run to see what would change
.\scripts\update-screenconnect.ps1 -NewVersion "24.2.0.8811" -DryRun

# Force update even if version is the same
.\scripts\update-screenconnect.ps1 -NewVersion "24.2.0.8811" -Force
```

#### Manual Update

If you need to update manually:

1. **Update VERSION file**:
   ```bash
   echo "24.2.0.8811" > VERSION
   ```

2. **Update user_data.tpl**:
   ```bash
   # Find and replace the download URL
   sed -i 's/ScreenConnect_24.1.0.8811/ScreenConnect_24.2.0.8811/g' modules/compute/user_data.tpl
   ```

3. **Update CHANGELOG.md**:
   Add a new entry for the version change

### Version Validation

```powershell
# Validate version consistency
.\scripts\validate-deployment.ps1 -Environment "production"
```

## Release Process

### Creating a Release

#### Automated Release

```powershell
# Create a complete release
.\scripts\release.ps1 -ReleaseVersion "24.2.0.8811" -CreateTag

# Dry run to see what would happen
.\scripts\release.ps1 -ReleaseVersion "24.2.0.8811" -DryRun

# Skip validation (not recommended)
.\scripts\release.ps1 -ReleaseVersion "24.2.0.8811" -SkipValidation
```

#### Release Steps

The automated release process:

1. **Updates ScreenConnect version**
2. **Validates deployment configuration**
3. **Updates changelog**
4. **Creates release notes**
5. **Commits changes**
6. **Creates git tag**
7. **Generates deployment summary**

### Release Files

Each release creates:
- `RELEASE_NOTES_[VERSION].md` - Detailed release notes
- `DEPLOYMENT_SUMMARY_[VERSION].md` - Deployment instructions
- Updated `CHANGELOG.md` - Version history
- Updated `VERSION` - Current version

### Deploying a Release

```bash
# Navigate to environment
cd environments/production

# Review changes
terraform plan

# Deploy
terraform apply

# Verify deployment
# Check ScreenConnect web UI
# Test relay functionality
# Verify SSL certificates
```

## Environment Management

### Creating New Environments

```powershell
# Create staging environment
.\scripts\create-environment.ps1 -EnvironmentName "staging"

# Create development environment
.\scripts\create-environment.ps1 -EnvironmentName "development"

# Create from different source
.\scripts\create-environment.ps1 -EnvironmentName "testing" -SourceEnvironment "staging"

# Dry run to see what would be created
.\scripts\create-environment.ps1 -EnvironmentName "staging" -DryRun
```

### Environment Structure

Each environment includes:
- `main.tf` - Terraform configuration
- `variables.tf` - Variable definitions
- `terraform.tfvars` - Environment-specific values
- `README.md` - Environment documentation

### Environment-Specific Configuration

Key differences between environments:
- **Backup bucket name**: Includes environment suffix
- **Domain configuration**: Different domains per environment
- **Tags**: Environment-specific tagging
- **Resource naming**: Includes environment name

## Validation and Testing

### Pre-Deployment Validation

```powershell
# Full validation
.\scripts\validate-deployment.ps1 -Environment "production"

# Verbose output
.\scripts\validate-deployment.ps1 -Environment "production" -Verbose

# Skip specific checks
.\scripts\validate-deployment.ps1 -Environment "production" -SkipSecurityChecks
.\scripts\validate-deployment.ps1 -Environment "production" -SkipTerraformValidation
```

### Validation Checks

The validation script checks:
- **File structure**: All required files exist
- **Version consistency**: VERSION matches user_data.tpl
- **Terraform configuration**: Valid syntax and configuration
- **Security**: No hardcoded secrets, WinRM removed
- **Variables**: All required variables defined
- **Module structure**: Complete module files
- **Documentation**: Sufficient documentation

### Prerequisites Validation

```powershell
# Check prerequisites
.\scripts\validate-prerequisites.ps1

# Check with custom paths
.\scripts\validate-prerequisites.ps1 -TerraformPath "terraform" -ConfigPath "terraform.tfvars"
```

## Update Workflow

### Standard Update Process

1. **Check for new ScreenConnect version**
   ```powershell
   # Check current version
   Get-Content VERSION
   ```

2. **Update to new version**
   ```powershell
   .\scripts\update-screenconnect.ps1 -NewVersion "24.2.0.8811"
   ```

3. **Validate changes**
   ```powershell
   .\scripts\validate-deployment.ps1 -Environment "production"
   ```

4. **Test in staging**
   ```powershell
   .\scripts\create-environment.ps1 -EnvironmentName "staging"
   cd environments/staging
   terraform apply
   ```

5. **Create release**
   ```powershell
   .\scripts\release.ps1 -ReleaseVersion "24.2.0.8811" -CreateTag
   ```

6. **Deploy to production**
   ```bash
   cd environments/production
   terraform apply
   ```

### Emergency Updates

For critical security updates:

```powershell
# Quick update without full validation
.\scripts\update-screenconnect.ps1 -NewVersion "24.2.0.8811" -Force

# Deploy immediately
cd environments/production
terraform apply -auto-approve
```

## Rollback Process

### Rolling Back a Release

1. **Check git history**
   ```bash
   git log --oneline -10
   ```

2. **Revert to previous version**
   ```bash
   git checkout v[previous-version]
   ```

3. **Redeploy**
   ```bash
   cd environments/production
   terraform apply
   ```

### Rolling Back ScreenConnect Version

```powershell
# Update to previous version
.\scripts\update-screenconnect.ps1 -NewVersion "24.1.0.8811" -Force

# Deploy
cd environments/production
terraform apply
```

## Best Practices

### Version Management

- **Always use the update script** for version changes
- **Test in staging** before production
- **Keep changelog updated** with all changes
- **Use semantic versioning** for releases

### Release Management

- **Create releases for all changes** to production
- **Use git tags** for version tracking
- **Document breaking changes** clearly
- **Test rollback procedures** regularly

### Environment Management

- **Use different domains** for each environment
- **Separate Oracle Cloud compartments** when possible
- **Environment-specific secrets** in Oracle Vault
- **Monitor costs** per environment

### Validation

- **Always validate** before deployment
- **Run security checks** regularly
- **Test in staging** before production
- **Monitor deployment** after changes

## Troubleshooting

### Common Issues

#### Version Mismatch
```powershell
# Check version consistency
.\scripts\validate-deployment.ps1 -Environment "production"
```

#### Validation Failures
```powershell
# Run with verbose output
.\scripts\validate-deployment.ps1 -Environment "production" -Verbose
```

#### Update Failures
```powershell
# Check file permissions
# Ensure git is available
# Verify network connectivity
```

### Getting Help

1. **Check the changelog** for known issues
2. **Review validation output** for specific errors
3. **Check Terraform state** for deployment issues
4. **Review Windows Event Logs** for application issues

## Automation Scripts Reference

### Update Scripts

- `update-screenconnect.ps1` - Update ScreenConnect version
- `release.ps1` - Create and manage releases
- `create-environment.ps1` - Create new environments

### Validation Scripts

- `validate-deployment.ps1` - Validate deployment configuration
- `validate-prerequisites.ps1` - Check prerequisites

### Maintenance Scripts

- `maintenance.ps1` - System maintenance
- `ssl-management.ps1` - SSL certificate management
- `scheduled-backup.ps1` - Backup management

---

**For more information, see the main README.md and DEPLOYMENT_GUIDE.md** 