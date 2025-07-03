# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [24.1.0.8811] - 2024-01-15

### Added
- ScreenConnect 24.1.0.8811 support
- HTTP to HTTPS redirect configuration
- Automatic IIS URL Rewrite module installation
- Domain variable configuration (primary_domain and relay_domain)
- Prerequisites validation script
- Comprehensive deployment guide
- Oracle Vault integration for secrets management
- Cloudflare DNS integration
- Automated backup system
- SSL certificate management
- Maintenance automation scripts

### Changed
- Updated ScreenConnect configuration to use domain variables
- Improved error handling in user data template
- Enhanced Windows image selection with better filtering
- Updated security configuration (removed WinRM)
- Improved documentation structure

### Fixed
- Missing SSH key variable in main configuration
- Subnet reference logic for conditional RDP access
- Windows image data source reliability
- Conditional resource creation dependencies
- ScreenConnect configuration with proper domain settings

### Security
- Removed WinRM ports (5985, 5986) to reduce attack surface
- Restricted RDP access to specified IP addresses only
- Implemented Oracle Vault for secure secrets storage
- Added SSL/TLS encryption for web UI
- Configured proper firewall rules

### Documentation
- Added comprehensive README with architecture diagrams
- Created step-by-step deployment guide
- Added security guide and cost analysis
- Included troubleshooting section
- Added port configuration documentation

## [23.9.8.8811] - 2024-01-01

### Added
- Initial ScreenConnect deployment on Oracle Cloud
- Basic Terraform infrastructure
- Windows Server 2022 instance
- Basic networking configuration
- Simple backup system

### Changed
- Basic ScreenConnect installation
- Standard security configuration

### Fixed
- Initial deployment issues
- Basic configuration problems

---

## Version History

### ScreenConnect Versions
- **24.1.0.8811** - Current (Latest stable)
- **23.9.8.8811** - Previous (Initial deployment)

### Terraform Versions
- **>= 1.0** - Required Terraform version
- **~> 5.0** - Oracle Cloud provider
- **~> 4.0** - Cloudflare provider
- **~> 3.0** - HTTP provider
- **~> 2.0** - Local provider

### Windows Server Versions
- **2022** - Current Windows Server version

---

## Migration Notes

### From 23.9.8.8811 to 24.1.0.8811
1. Update ScreenConnect to version 24.1.0.8811
2. Configure domain variables (primary_domain, relay_domain)
3. Remove WinRM configuration for security
4. Update SSL configuration for HTTP to HTTPS redirect
5. Review and update secrets management configuration

---

## Breaking Changes

### Version 24.1.0.8811
- **Domain Configuration**: Now requires explicit primary_domain and relay_domain variables
- **WinRM Removal**: WinRM ports no longer available (security improvement)
- **SSL Configuration**: HTTP to HTTPS redirect now required

---

## Deprecation Notices

### Version 24.1.0.8811
- **WinRM Access**: Deprecated and removed for security reasons
- **Hardcoded Domains**: Deprecated in favor of variable-based configuration
- **Basic Secrets**: Deprecated in favor of Oracle Vault integration

---

## Future Roadmap

### Planned Features
- [ ] Multi-environment support (staging, development)
- [ ] Automated testing framework
- [ ] CI/CD pipeline integration
- [ ] Enhanced monitoring and alerting
- [ ] Backup verification and testing
- [ ] Performance optimization
- [ ] Additional security hardening

### Known Issues
- None currently identified

---

## Support

For issues and questions:
1. Check the troubleshooting section in README.md
2. Review the deployment guide
3. Check the security guide for configuration issues
4. Verify Oracle Cloud console for resource status 