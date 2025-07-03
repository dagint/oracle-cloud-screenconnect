# ScreenConnect Deployment Guide

This guide walks you through deploying the fixed and improved ScreenConnect infrastructure on Oracle Cloud.

## ✅ Fixed Issues

The following critical issues have been resolved:

1. **Missing SSH Key Variable** - Added `ssh_public_key_path` variable to main configuration
2. **Subnet Reference Logic** - Fixed conditional subnet creation and references
3. **ScreenConnect Version** - Updated to latest version (24.1.0.8811)
4. **Windows Image Selection** - Improved image filtering and error handling
5. **Error Handling** - Added proper validation and error messages
6. **Prerequisites Validation** - Created validation script to check requirements
7. **Port Configuration** - Configured ScreenConnect with proper port setup:
   - Web UI: Primary domain (e.g., remotesupport.yourdomain.com) on port 443 (HTTPS)
- Relay: Relay domain (e.g., relay.yourdomain.com) on port 8041
   - HTTP to HTTPS redirect: Port 80 → 443
   - Both domains are configurable variables
   - **Security**: WinRM removed to reduce attack surface

## Prerequisites

### Required Software
- Terraform >= 1.0
- PowerShell 5.1+
- Oracle Cloud CLI (optional, for configuration)

### Required Accounts
- Oracle Cloud account with API access
- Cloudflare account with API token
- ScreenConnect license

### Required Files
- SSH public key (`~/.ssh/id_rsa.pub`)
- Oracle Cloud API key (`~/.oci/oci_api_key.pem`)

## Quick Deployment

### 1. Validate Prerequisites

```powershell
# Run the validation script
.\scripts\validate-prerequisites.ps1
```

### 2. Configure Deployment

```bash
cd environments/production

# Copy the example configuration
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
notepad terraform.tfvars
```

### 3. Required Configuration

**Oracle Cloud Configuration:**
```hcl
tenancy_ocid     = "ocid1.tenancy.oc1..your-tenancy-ocid"
compartment_ocid = "ocid1.compartment.oc1..your-compartment-ocid"
user_ocid        = "ocid1.user.oc1..your-user-ocid"
fingerprint      = "your-fingerprint"
private_key_path = "~/.oci/oci_api_key.pem"
region           = "us-ashburn-1"
```

**SSH Configuration:**
```hcl
ssh_public_key_path = "~/.ssh/id_rsa.pub"
```

**ScreenConnect Configuration:**
```hcl
screenconnect_license_key = "your-license-key"
admin_password           = "your-secure-password"
```

**Domain Configuration:**
```hcl
primary_domain = "remotesupport.yourdomain.com"  # Web UI domain (can be changed)
relay_domain   = "relay.yourdomain.com"  # Relay domain (can be changed)
```

**Note**: Both domains are configurable variables. The primary domain is used for the web UI, and the relay domain is used for the relay server. You can change these to any domains you own and have DNS control over.

**Cloudflare Configuration:**
```hcl
cloudflare_api_token = "your-api-token"
cloudflare_zone_id   = "your-zone-id"
```

### 4. Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Plan the deployment
terraform plan

# Apply the configuration
terraform apply
```

### 5. Post-Deployment Setup

After successful deployment:

1. **Access ScreenConnect Web UI**: https://remotesupport.yourdomain.com
2. **RDP Access**: Use the IP and credentials from Terraform output
3. **SSL Certificates**: Run SSL management script
4. **Harden the Windows VM**:
   - Follow the [Windows Hardening Guide](docs/WINDOWS_HARDENING.md)
   - Run the hardening script as Administrator:
     ```powershell
     .\scripts\harden-windows.ps1
     ```
5. **Backup Configuration**: Verify backup scripts are working

## Port Configuration

The deployment is configured with the following port setup:

### ScreenConnect Web UI
- **Domain**: Primary domain (e.g., remotesupport.yourdomain.com)
- **Port**: 443 (HTTPS)
- **Access**: https://[primary_domain]
- **HTTP Redirect**: http://[primary_domain] → https://[primary_domain]

### ScreenConnect Relay
- **Domain**: Relay domain (e.g., relay.yourdomain.com)
- **Port**: 8041
- **Protocol**: TCP
- **Purpose**: ScreenConnect relay protocol for client connections

### Network Security
- **Port 80**: Open for HTTP to HTTPS redirect
- **Port 443**: Open for ScreenConnect web UI
- **Port 8041**: Open for ScreenConnect relay
- **Port 3389**: RDP access (restricted to specified IPs)

### Domain Configuration
Both domains are configurable variables:
- **Primary Domain**: Used for the web UI (default: remotesupport.yourdomain.com)
- **Relay Domain**: Used for the relay server (default: relay.yourdomain.com)

### Automatic Configuration
The deployment automatically:
1. Configures ScreenConnect to use primary domain for web UI (port 443)
2. Sets up relay on relay domain (port 8041)
3. Installs IIS URL Rewrite module
4. Creates HTTP to HTTPS redirect rules for primary domain
5. Updates Windows Firewall rules
6. Restarts IIS services

## Troubleshooting

### Common Issues

#### 1. Windows Image Not Found
```
Error: No Windows Server 2022 image found in the compartment
```
**Solution**: Check your Oracle Cloud region and compartment settings. Ensure you have access to Windows Server 2022 images.

#### 2. SSH Key Not Found
```
Error: open ~/.ssh/id_rsa.pub: no such file or directory
```
**Solution**: Generate an SSH key pair:
```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa
```

#### 3. Oracle Cloud Authentication Failed
```
Error: Authentication failed
```
**Solution**: Verify your Oracle Cloud credentials and API key configuration.

#### 4. ScreenConnect Installation Failed
Check the Windows instance logs for installation errors. Common issues:
- Network connectivity problems
- Insufficient disk space
- Windows Update conflicts

### Validation Commands

```powershell
# Check Terraform version
terraform version

# Validate Terraform configuration
terraform validate

# Check Oracle Cloud connectivity
oci iam user get --user-id $env:USER_OCID

# Test SSH key
ssh-keygen -l -f ~/.ssh/id_rsa.pub
```

## Security Considerations

### Production Deployment
1. **Use Oracle Vault**: Set `use_vault_for_secrets = true`
2. **Restrict RDP Access**: Configure specific IP addresses only
3. **Strong Passwords**: Use complex, unique passwords
4. **SSL/TLS**: Enable full SSL mode with Cloudflare

### Network Security
- **RDP Access**: Restricted to specified IP addresses
- **Firewall Rules**: Minimal required ports open
- **Cloudflare Protection**: DDoS protection and security rules

## Monitoring and Maintenance

### Automated Tasks
- Monthly ScreenConnect updates
- Weekly SSL certificate checks
- Daily system health monitoring
- Automated backup management

### Manual Maintenance
```powershell
# Run maintenance tasks
.\scripts\maintenance.ps1

# Update SSL certificates
.\scripts\ssl-management.ps1

# Check backup status
.\scripts\scheduled-backup.ps1
```

## Cost Optimization

### Always Free Tier
- **Compute**: VM.Standard.A1.Flex (1 OCPU, 6GB RAM)
- **Storage**: 200GB Object Storage
- **Networking**: VCN, Internet Gateway
- **Vault**: Basic secrets management

**Monthly Cost: $0**

### Production Tier
- **Compute**: ~$7.26/month
- **Storage**: ~$0.0255/GB/month
- **Vault**: ~$0.50/month
- **Total**: ~$8-10/month

## Support

For issues and questions:
1. Check the troubleshooting section
2. Review Terraform outputs for connection information
3. Check Windows Event Logs for errors
4. Verify Oracle Cloud console for resource status

## Changelog

### v1.5.0 (Current)
- Fixed missing SSH key variable
- Improved Windows image selection
- Updated ScreenConnect to version 24.1.0.8811
- Added comprehensive error handling
- Created prerequisites validation script
- Fixed subnet reference logic
- Added deployment guide

### v1.4.0
- Cost optimization and simplification
- Added Cloudflare DNS integration
- Added SSL certificate management
- Added comprehensive maintenance automation

---

**This deployment is now production-ready with all critical issues resolved.** 