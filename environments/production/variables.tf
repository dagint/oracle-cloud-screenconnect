# Oracle Cloud ScreenConnect Deployment Variables
# Cost optimized configuration

# Oracle Cloud Configuration
variable "tenancy_ocid" {
  description = "The OCID of your tenancy"
  type        = string
}

variable "compartment_ocid" {
  description = "The OCID of the compartment where resources will be created"
  type        = string
}

variable "user_ocid" {
  description = "The OCID of the user calling the API"
  type        = string
}

variable "fingerprint" {
  description = "The fingerprint for the key pair used for API signing"
  type        = string
}

variable "private_key_path" {
  description = "The path to the private key file"
  type        = string
  default     = "~/.oci/oci_api_key.pem"
}

variable "region" {
  description = "The Oracle Cloud region where resources will be created"
  type        = string
  default     = "us-ashburn-1"
}

# SSH Configuration
variable "ssh_public_key_path" {
  description = "Path to the SSH public key file for instance access"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

# Project Configuration
variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "screenconnect"
}

variable "environment" {
  description = "Environment name (e.g., production, staging, development)"
  type        = string
  default     = "production"
}

# Network Configuration
variable "vcn_cidr_block" {
  description = "CIDR block for the VCN"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr_block" {
  description = "CIDR block for the subnet"
  type        = string
  default     = "10.0.1.0/24"
}

# RDP Access Configuration
variable "enable_rdp_access" {
  description = "Whether to enable RDP access from specified IP addresses"
  type        = bool
  default     = true
}

variable "rdp_allowed_ips" {
  description = "List of IP addresses (CIDR notation) allowed to RDP to the instance"
  type        = list(string)
  default     = []
}

variable "auto_detect_home_ip" {
  description = "Whether to automatically detect and include current public IP for RDP access"
  type        = bool
  default     = true
}

variable "additional_rdp_ips" {
  description = "Additional IP addresses to allow RDP access (for secondary WAN, VPN, etc.)"
  type        = list(string)
  default     = []
}

# Secrets Management Configuration
variable "use_vault_for_secrets" {
  description = "Whether to store sensitive values in Oracle Vault (recommended for production)"
  type        = bool
  default     = true
}

# Compute Configuration - Optimized for cost
variable "instance_shape" {
  description = "The shape of the compute instance"
  type        = string
  default     = "VM.Standard.A1.Flex"
}

variable "ocpus" {
  description = "Number of OCPUs for the instance"
  type        = number
  default     = 1
}

variable "memory_in_gbs" {
  description = "Amount of memory in GB for the instance"
  type        = number
  default     = 6
}

# ScreenConnect Configuration
variable "screenconnect_license_key" {
  description = "ScreenConnect license key (stored in vault if use_vault_for_secrets is true)"
  type        = string
  sensitive   = true
}

variable "admin_password" {
  description = "Admin password for ScreenConnect (stored in vault if use_vault_for_secrets is true)"
  type        = string
  sensitive   = true
}

# Domain Configuration
variable "primary_domain" {
  description = "Primary domain for ScreenConnect web UI (remotesupport.yourdomain.com)"
type        = string
  default     = "remotesupport.yourdomain.com"
}

variable "relay_domain" {
  description = "Relay domain for ScreenConnect relay protocol (relay.yourdomain.com)"
type        = string
default     = "relay.yourdomain.com"
}

# Cloudflare Configuration
variable "cloudflare_api_token" {
  description = "Cloudflare API token for DNS management (stored in vault if use_vault_for_secrets is true)"
  type        = string
  sensitive   = true
}

variable "cloudflare_zone_id" {
  description = "Cloudflare zone ID for the domain (stored in vault if use_vault_for_secrets is true)"
  type        = string
  sensitive   = true
}

variable "enable_cloudflare_proxy" {
  description = "Whether to enable Cloudflare proxy (orange cloud)"
  type        = bool
  default     = true
}

variable "cloudflare_ssl_mode" {
  description = "Cloudflare SSL mode (flexible, full, full_strict)"
  type        = string
  default     = "full"
}

# Backup Configuration
variable "backup_bucket_name" {
  description = "Name of the Object Storage bucket for backups"
  type        = string
  default     = "screenconnect-backups"
}

variable "backup_retention" {
  description = "Number of backups to retain"
  type        = number
  default     = 5
}

# Tags
variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
} 