# Oracle Cloud ScreenConnect Deployment

A cost-optimized, production-ready ScreenConnect deployment on Oracle Cloud Infrastructure (OCI) with automatic backups, SSL management, secure RDP access, and enterprise-grade secrets management.

## Features

- **Cost Optimized**: Leverages Oracle Cloud's Always Free tier for significant cost savings
- **Single Instance**: Simplified deployment with one Windows VM
- **Automatic Backups**: Weekly backups to Oracle Object Storage with retention management
- **SSL Management**: Automatic Let's Encrypt certificate management
- **DNS Integration**: Cloudflare DNS management with security rules
- **Secrets Management**: Oracle Vault integration for secure credential storage
- **RDP Access Control**: Dynamic IP-based RDP access for secure remote management
- **Dual WAN Support**: Designed for UniFi Dream Machine SE with active/active WAN
- **Enterprise Security**: Production-ready secrets management with encryption
- **Port Configuration**: Optimized port setup:
  - Web UI: Primary domain (e.g., remotesupport.yourdomain.com) on port 443 (HTTPS)
- Relay: Relay domain (e.g., relay.yourdomain.com) on port 8041
  - HTTP to HTTPS redirect: Port 80 → 443
  - Both domains are configurable variables
  - **Security**: WinRM removed to reduce attack surface
- **Automated Updates**: Version management and automated release process
- **Multi-Environment Support**: Easy creation of staging, development environments
- **Comprehensive Validation**: Pre-deployment validation and security checks

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Your Home     │    │   Oracle Cloud   │    │   Cloudflare    │
│   Network       │    │   Infrastructure  │    │     DNS         │
│                 │    │                  │    │                 │
│ ┌─────────────┐ │    │ ┌──────────────┐ │    │ ┌─────────────┐ │
│ │ Primary WAN │◄┼────┼►│ Windows VM   │◄┼────┼►│ remotesuppor│ │
│ │ IP: x.x.x.x │ │    │ │ ScreenConnect│ │    │ │ t.yourdomain│ │
│ └─────────────┘ │    │ └──────────────┘ │    │ └─────────────┘ │
│                 │    │                  │    │                 │
│ ┌─────────────┐ │    │ ┌──────────────┐ │    │ ┌─────────────┐ │
│ │Secondary WAN│◄┼────┼►│ Oracle Vault │ │    │ │ relay.yourd│ │
│ │ IP: y.y.y.y │ │    │ │ (Secrets)    │ │    │ │ omain.com  │ │
│ └─────────────┘ │    │ └──────────────┘ │    │ └─────────────┘ │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

## Prerequisites

- Oracle Cloud account with API access
- Cloudflare account with API token
- ScreenConnect license
- PowerShell 5.1+ (for IP detection scripts)

## Quick Start

### 1. Clone and Setup

```bash
git clone <repository-url>
cd oracle-cloud-screenconnect/environments/production
```

### 2. Validate Prerequisites

```powershell
# Run the validation script
.\scripts\validate-prerequisites.ps1
```

### 3. Setup Secure Configuration

```powershell
# Create secure configuration file
.\scripts\setup-secure-config.ps1 -Environment "production" -Interactive

# Or create without interactive mode
.\scripts\setup-secure-config.ps1 -Environment "production"
```

This will:
- Create `terraform.tfvars` from the secure template
- Open the file for editing (if using -Interactive)
- Guide you through required configuration

### 4. Configure Your Values

Edit the `terraform.tfvars` file with your actual values:

```hcl
# Oracle Cloud Configuration
tenancy_ocid     = "ocid1.tenancy.oc1..your-actual-tenancy-ocid"
compartment_ocid = "ocid1.compartment.oc1..your-actual-compartment-ocid"
user_ocid        = "ocid1.user.oc1..your-actual-user-ocid"
fingerprint      = "your-actual-fingerprint"
private_key_path = "~/.oci/oci_api_key.pem"
region           = "us-ashburn-1"

# ScreenConnect Configuration
screenconnect_license_key = "your-actual-license-key"
admin_password           = "your-secure-admin-password"

# Domain Configuration
primary_domain = "remotesupport.yourdomain.com"  # Your actual domain
relay_domain   = "relay.yourdomain.com"  # Your actual relay domain

# Cloudflare Configuration
cloudflare_api_token = "your-actual-api-token"
cloudflare_zone_id   = "your-actual-zone-id"

# RDP Access Configuration
additional_rdp_ips = [
  "203.0.113.1/32",  # Your actual primary WAN IP
  "198.51.100.1/32", # Your actual secondary WAN IP
]
```

### 5. Validate Configuration

```powershell
# Validate your configuration
.\scripts\validate-secrets.ps1 -Environment "production" -Verbose
```

### 6. Deploy

```bash
# Initialize Terraform
terraform init

# Plan the deployment
terraform plan

# Apply the configuration
terraform apply
```

## Automation and Updates

### Version Management

The repository includes automated version management:

```powershell
# Update ScreenConnect to a new version
.\scripts\update-screenconnect.ps1 -NewVersion "24.2.0.8811"

# Create a new release
.\scripts\release.ps1 -ReleaseVersion "24.2.0.8811" -CreateTag
```

### Environment Management

Create new environments easily:

```powershell
# Create a staging environment
.\scripts\create-environment.ps1 -EnvironmentName "staging"

# Create a development environment
.\scripts\create-environment.ps1 -EnvironmentName "development"
```

### Validation and Testing

Comprehensive validation before deployment:

```powershell
# Validate deployment configuration
.\scripts\validate-deployment.ps1 -Environment "production"

# Validate with verbose output
.\scripts\validate-deployment.ps1 -Environment "production" -Verbose

# Skip specific checks
.\scripts\validate-deployment.ps1 -Environment "production" -SkipSecurityChecks
```

### 6. Access Your ScreenConnect Instance

After deployment, you can access:

- **Web UI**: https://remotesupport.yourdomain.com
- **RDP**: Use the IP and credentials from the output

## Secrets Management

### Oracle Vault Integration

The deployment includes enterprise-grade secrets management:

- **Encrypted Storage**: All sensitive data encrypted with AES-256
- **Access Control**: IAM-based access to secrets
- **Audit Logging**: Complete audit trail for secret access
- **Automatic Rotation**: Framework for secret rotation

### Security Levels

#### Level 1: Oracle Vault (Recommended for Production)
```hcl
use_vault_for_secrets = true
```
- Secrets stored in Oracle Vault with encryption
- Access controlled by IAM policies
- Audit logging enabled
- No secrets in Terraform state

#### Level 2: Terraform Variables (Development Only)
```hcl
use_vault_for_secrets = false
```
- Secrets stored in Terraform state
- Less secure, suitable for development only
- Not recommended for production

### Managing Secrets

#### Check Secrets Status
```powershell
.\scripts\manage-secrets.ps1 -Action check
```

#### Generate Secure Configuration
```powershell
.\scripts\manage-secrets.ps1 -Action generate
```

#### Environment Variables (CI/CD)
```powershell
# PowerShell
$env:SCREENCONNECT_LICENSE = "your-license-key"
$env:ADMIN_PASSWORD = "your-admin-password"
$env:CLOUDFLARE_API_TOKEN = "your-api-token"
$env:CLOUDFLARE_ZONE_ID = "your-zone-id"

# Bash/Linux
export SCREENCONNECT_LICENSE="your-license-key"
export ADMIN_PASSWORD="your-admin-password"
export CLOUDFLARE_API_TOKEN="your-api-token"
export CLOUDFLARE_ZONE_ID="your-zone-id"
```

## RDP Access Management

### Automatic IP Detection

The deployment includes automatic IP detection that:

1. **During Deployment**: Detects your current public IP and allows RDP access
2. **Dynamic Updates**: Can be updated by re-running the IP detection script
3. **Multiple IPs**: Supports both primary and secondary WAN IPs

### Manual IP Management

For more control, you can manually specify IPs:

```hcl
enable_rdp_access = true
auto_detect_home_ip = false
additional_rdp_ips = [
  "203.0.113.1/32",  # Primary WAN
  "198.51.100.1/32", # Secondary WAN
  "192.0.2.1/32",    # VPN IP
]
```

### Updating IP Addresses

When your WAN IPs change:

1. **Re-run IP detection**:
   ```powershell
   .\scripts\get-home-ips.ps1
   ```

2. **Update terraform.tfvars** with new IPs

3. **Apply changes**:
   ```bash
   terraform plan
   terraform apply
   ```

## Backup System

### Automatic Backups

- **Frequency**: Weekly (configurable)
- **Retention**: 5 backups (configurable)
- **Storage**: Oracle Object Storage
- **Encryption**: Server-side encryption

### Manual Backup

```powershell
# Create backup
.\scripts\scheduled-backup.ps1

# Check backup status
.\scripts\check-backup-status.ps1
```

### Restore from Backup

```powershell
# Restore from backup
.\scripts\restore-backup.ps1 -BackupFile "backup-2024-01-15.zip"
```

## SSL Management

### Automatic Certificate Management

The deployment includes automatic SSL certificate management:

- **Provider**: Let's Encrypt
- **Client**: Win-Acme
- **Domains**: remotesupport.yourdomain.com, relay.yourdomain.com
- **Auto-renewal**: Monthly

### Manual SSL Management

```powershell
# Update SSL certificates
.\scripts\ssl-management.ps1

# Check certificate status
.\scripts\ssl-management.ps1 -CheckOnly
```

## Maintenance

### System Updates

```powershell
# Run maintenance tasks
.\scripts\maintenance.ps1

# Or use the batch file
.\scripts\run-maintenance.bat
```

### Agent Installation

The maintenance script can install:

- **Atera Agent**: Remote monitoring and management
- **Antivirus**: Windows Defender updates
- **ScreenConnect Updates**: Latest version installation

## Security Features

### Network Security

- **RDP Access**: Restricted to specified IP addresses
- **Firewall Rules**: Minimal required ports open
- **Cloudflare Protection**: DDoS protection and security rules

### Data Protection

- **Backup Encryption**: Server-side encryption
- **Secrets Management**: Oracle Vault integration with encryption
- **SSL/TLS**: End-to-end encryption
- **Access Control**: IAM-based permissions

### Secrets Security

- **Oracle Vault**: Enterprise-grade secrets storage
- **Encryption**: AES-256 encryption for all secrets
- **Access Control**: IAM policies for secret access
- **Audit Logging**: Complete audit trail
- **No Plain Text**: Secrets never stored in plain text

## Cost Optimization

### Always Free Tier

This deployment is optimized for Oracle Cloud's Always Free tier:

- **Compute**: VM.Standard.A1.Flex (1 OCPU, 6GB RAM)
- **Storage**: 200GB Object Storage
- **Networking**: VCN, Internet Gateway
- **Vault**: Basic secrets management

### Production Tier Costs

For production workloads:

- **Compute**: ~$7.26/month (VM.Standard.A1.Flex)
- **Storage**: ~$0.0255/GB/month
- **Vault**: ~$0.50/month
- **Total**: ~$8-10/month

## Troubleshooting

### Common Issues

1. **RDP Access Denied**
   - Check if your IP is in the allowed list
   - Re-run IP detection script
   - Verify firewall rules

2. **SSL Certificate Issues**
   - Run SSL management script
   - Check Cloudflare DNS settings
   - Verify domain configuration

3. **Backup Failures**
   - Check Object Storage permissions
   - Verify vault credentials
   - Review backup logs

4. **Secrets Management Issues**
   - Verify Oracle Vault permissions
   - Check IAM policies
   - Review audit logs

### Logs and Monitoring

- **ScreenConnect Logs**: `C:\Program Files (x86)\ScreenConnect\App_Data\Logs`
- **Windows Event Logs**: Event Viewer
- **Terraform State**: `terraform.tfstate`
- **Oracle Vault Logs**: Oracle Cloud Console

## Security Best Practices

### Production Deployment

1. **Use Oracle Vault**: Always enable `use_vault_for_secrets = true`
2. **Strong Passwords**: Use complex, unique passwords
3. **IP Restrictions**: Limit RDP access to specific IPs only
4. **Regular Updates**: Keep systems and secrets updated
5. **Audit Logging**: Monitor access and changes
6. **Backup Encryption**: Ensure backups are encrypted
7. **SSL/TLS**: Use full SSL mode with Cloudflare

### Development vs Production

| Feature | Development | Production |
|---------|-------------|------------|
| Secrets Storage | Terraform Variables | Oracle Vault |
| RDP Access | Broad IP ranges | Specific IPs only |
| SSL Mode | Flexible | Full/Full Strict |
| Audit Logging | Basic | Comprehensive |
| Backup Retention | 3 copies | 5+ copies |

## Support

For issues and questions:

1. Check the troubleshooting section
2. Review Terraform outputs for connection information
3. Check Windows Event Logs for errors
4. Verify Oracle Cloud console for resource status
5. Review Oracle Vault audit logs for secrets access

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## 📁 Project Structure

```
oracle-cloud-screenconnect/
├── environments/
│   └── production/
│       ├── main.tf              # Main Terraform configuration
│       ├── variables.tf         # Variable definitions
│       ├── terraform.tfvars.secure # Secure configuration template
│       └── terraform.tfvars     # Variable values (create from secure template)
├── modules/
│   ├── compute/                 # Compute instance module
│   ├── networking/              # Network infrastructure
│   ├── storage/                 # Object Storage for backups
│   ├── vault/                   # Secrets management
│   └── cloudflare_dns/          # Cloudflare DNS management
├── scripts/
│   ├── maintenance.ps1          # Comprehensive maintenance script
│   ├── ssl-management.ps1       # SSL certificate management
│   ├── run-maintenance.bat      # Easy maintenance execution
│   ├── scheduled-backup.ps1     # Automated backup script
│   ├── setup-secrets.ps1        # Secrets management setup
│   ├── upload-to-storage.ps1    # Backup upload script
│   ├── update-screenconnect.ps1 # ScreenConnect version updates
│   ├── release.ps1              # Release automation
│   ├── create-environment.ps1   # Environment creation
│   ├── validate-deployment.ps1  # Deployment validation
│   ├── validate-prerequisites.ps1 # Prerequisites validation
│   ├── setup-secure-config.ps1  # Secure configuration setup
│   └── validate-secrets.ps1     # Secrets validation
├── docs/
│   ├── SECURITY_GUIDE.md        # Security configuration guide
│   └── COST_ANALYSIS.md         # Cost analysis and optimization
├── backups/                     # Version backup storage
├── .vscode/                     # VS Code configuration
├── .gitignore                   # Git ignore rules
├── VERSION                      # Current ScreenConnect version
├── CHANGELOG.md                 # Version history and changes
├── UPDATE_GUIDE.md              # Update and release management
├── SECURITY_BEST_PRACTICES.md   # Security best practices
└── README.md                    # This file
```

## 🔧 Configuration

### Required Variables
```hcl
# Oracle Cloud Configuration
tenancy_ocid = "ocid1.tenancy.oc1..example"
compartment_ocid = "ocid1.compartment.oc1..example"
user_ocid = "ocid1.user.oc1..example"
fingerprint = "xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx"
private_key_path = "~/.oci/oci_api_key.pem"
region = "us-ashburn-1"

# ScreenConnect Configuration
screenconnect_license_key = "your-license-key"
admin_password = "secure-admin-password"

# Domain Configuration
primary_domain = "remotesupport.yourdomain.com"
relay_domain = "relay.yourdomain.com"

# Cloudflare Configuration
cloudflare_api_token = "your-cloudflare-api-token"
cloudflare_zone_id = "your-zone-id"
```

### Optional Variables
```hcl
# Instance Configuration
instance_shape = "VM.Standard.A1.Flex"
ocpus = 1
memory_in_gbs = 6

# Backup Configuration
backup_bucket_name = "screenconnect-backups"
backup_retention = 5
```

## 🔄 Maintenance

### Automated Maintenance
The deployment includes comprehensive maintenance automation:

#### Monthly Updates
```powershell
# Run all maintenance tasks
powershell.exe -ExecutionPolicy Bypass -File "C:\scripts\maintenance.ps1" -Action "all"
```

#### Agent Installation
```powershell
# Install Atera agent
powershell.exe -ExecutionPolicy Bypass -File "C:\scripts\maintenance.ps1" -Action "agent" -AgentType "atera" -AgentConfig '{"accountKey":"your-key","siteKey":"your-site"}'

# Install monitoring agent
powershell.exe -ExecutionPolicy Bypass -File "C:\scripts\maintenance.ps1" -Action "agent" -AgentType "monitoring" -AgentConfig '{"type":"custom","interval":300}'
```

#### SSL Certificate Management
```powershell
# Initial SSL setup for web UI only
powershell.exe -ExecutionPolicy Bypass -File "C:\scripts\ssl-management.ps1" -Domain "remotesupport.yourdomain.com" -Email "admin@yourdomain.com"

# Force renewal
powershell.exe -ExecutionPolicy Bypass -File "C:\scripts\ssl-management.ps1" -Domain "remotesupport.yourdomain.com" -Email "admin@yourdomain.com" -ForceRenewal
```

### Easy Maintenance Interface
Use the batch file for easy maintenance:
```cmd
# Run maintenance interface
run-maintenance.bat
```

## 🔒 Security Features

### Windows Instance Hardening
- **Follow the [Windows Hardening Guide](docs/WINDOWS_HARDENING.md)** after deployment.
- **Run the hardening script:**
  ```powershell
  # Run as Administrator on the ScreenConnect VM
  .\scripts\harden-windows.ps1
  ```

### Cloudflare Security
- **DDoS Protection** - Basic DDoS protection included
- **SSL/TLS** - Full (strict) encryption for web UI
- **Security Headers** - Basic security headers
- **DNS Management** - Automatic DNS record management

### Oracle Cloud Security
- **Network Security** - Basic security lists
- **Secrets Management** - Oracle Vault for credentials
- **Encryption** - Data at rest and in transit

### ScreenConnect Security
- **Authentication** - Standard authentication
- **Session Management** - Configurable timeouts
- **Access Control** - Role-based permissions

## 📊 Monitoring

### Basic Monitoring
- **Oracle Cloud Monitoring** - CPU, memory, disk usage
- **Cloudflare Analytics** - Basic traffic analytics
- **Health Checks** - Basic system health monitoring

### Automated Tasks
- Monthly ScreenConnect updates
- Weekly SSL certificate checks
- Daily system health monitoring
- Automated backup management

## 💰 Cost Analysis

### Always Free Tier (Recommended)
- **Compute:** 2 AMD-based Compute VMs (1 OCPU, 6 GB memory each)
- **Storage:** 200 GB total storage
- **Networking:** 10 TB outbound data transfer
- **Vault:** 20 secrets
- **Object Storage:** 20 GB storage, 50,000 API calls

**Monthly Cost: $0** (Always Free tier)

### Production Deployment
- **Compute:** VM.Standard.A1.Flex (1 OCPU, 6 GB memory)
- **Storage:** 100 GB boot volume + 50 GB data volume
- **Object Storage:** 5 GB for backups
- **Vault:** 5 secrets

**Monthly Cost: ~$6-8** (cost optimized)

## 🔧 Troubleshooting

### Common Issues

#### SSL Certificate Issues
```powershell
# Check certificate status
Get-ChildItem -Path "Cert:\LocalMachine\My" | Where-Object { $_.Subject -like "*remotesupport.yourdomain.com*" }

# Force certificate renewal
powershell.exe -ExecutionPolicy Bypass -File "C:\scripts\ssl-management.ps1" -Domain "remotesupport.yourdomain.com" -ForceRenewal
```

#### ScreenConnect Service Issues
```powershell
# Check service status
Get-Service -Name "ScreenConnect*"

# Restart service
Restart-Service -Name "ScreenConnect*"
```

#### Backup Issues
```powershell
# Check backup status
powershell.exe -ExecutionPolicy Bypass -File "C:\scripts\check-backup-status.ps1"

# Manual backup
powershell.exe -ExecutionPolicy Bypass -File "C:\scripts\scheduled-backup.ps1"
```

### Log Files
- **Maintenance Log:** `C:\screenconnect_maintenance_log.txt`
- **SSL Management Log:** `C:\ssl_management_log.txt`
- **Backup Log:** `C:\backup_log.txt`
- **ScreenConnect Log:** `C:\Program Files (x86)\ScreenConnect\App_Data\Logs\`

## 📚 Documentation

- **[Deployment Guide](DEPLOYMENT_GUIDE.md)** - Step-by-step deployment instructions
- **[Security Guide](docs/SECURITY_GUIDE.md)** - Security configuration and best practices
- **[Windows Hardening Guide](docs/WINDOWS_HARDENING.md)** - Windows Server hardening
- **[AWS Migration Guide](docs/AWS_MIGRATION.md)** - Migration from AWS to Oracle Cloud
- **[Scripts Documentation](docs/SCRIPTS.md)** - Complete script reference and usage
- **[Cost Analysis](docs/COST_ANALYSIS.md)** - Cost breakdown and optimization
- **[Oracle Cloud Documentation](https://docs.oracle.com)** - Official Oracle Cloud docs
- **[ScreenConnect Documentation](https://docs.connectwise.com)** - Official ScreenConnect docs

## 🤝 Support

### Emergency Contacts
- **Oracle Cloud Support:** 24/7 support available
- **Cloudflare Support:** 24/7 support available
- **ScreenConnect Support:** Business hours support

### Community Resources
- **Oracle Cloud Community:** [community.oracle.com](https://community.oracle.com)
- **Cloudflare Community:** [community.cloudflare.com](https://community.cloudflare.com)
- **ScreenConnect Community:** [community.connectwise.com](https://community.connectwise.com)

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔄 Updates

### Version History
- **v1.0.0** - Initial deployment with basic features
- **v1.1.0** - Added Cloudflare DNS integration
- **v1.2.0** - Added SSL certificate management
- **v1.3.0** - Added comprehensive maintenance automation
- **v1.4.0** - Cost optimization and simplification

### Upcoming Features
- **Performance Optimization** - Additional performance tuning
- **Enhanced Monitoring** - Basic monitoring improvements
- **Security Hardening** - Additional security features

---

**This deployment provides a cost-optimized ScreenConnect environment with essential security and automated maintenance on Oracle Cloud Infrastructure.** 