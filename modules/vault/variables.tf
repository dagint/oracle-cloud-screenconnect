# Oracle Cloud Vault Module Variables

variable "compartment_ocid" {
  description = "The OCID of the compartment where the vault will be created"
  type        = string
}

variable "vault_name" {
  description = "Name of the vault"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "screenconnect"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}

# Secrets Management Configuration
variable "store_screenconnect_license" {
  description = "Whether to store ScreenConnect license in vault"
  type        = bool
  default     = true
}

variable "store_admin_password" {
  description = "Whether to store admin password in vault"
  type        = bool
  default     = true
}

variable "store_cloudflare_token" {
  description = "Whether to store Cloudflare API token in vault"
  type        = bool
  default     = true
}

variable "store_cloudflare_zone_id" {
  description = "Whether to store Cloudflare zone ID in vault"
  type        = bool
  default     = true
}

# Secret Values (only used if storing in vault)
variable "screenconnect_license_key" {
  description = "ScreenConnect license key (only used if storing in vault)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "admin_password" {
  description = "Admin password (only used if storing in vault)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "cloudflare_api_token" {
  description = "Cloudflare API token (only used if storing in vault)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "cloudflare_zone_id" {
  description = "Cloudflare zone ID (only used if storing in vault)"
  type        = string
  default     = ""
  sensitive   = true
} 