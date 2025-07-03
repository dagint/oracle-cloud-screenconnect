# Oracle Cloud Vault Module Outputs

output "vault_id" {
  description = "The OCID of the vault"
  value       = oci_kms_vault.screenconnect_vault.id
}

output "vault_name" {
  description = "The name of the vault"
  value       = oci_kms_vault.screenconnect_vault.display_name
}

output "master_key_id" {
  description = "The OCID of the master encryption key"
  value       = oci_kms_key.master_key.id
}

output "management_endpoint" {
  description = "The management endpoint of the vault"
  value       = oci_kms_vault.screenconnect_vault.management_endpoint
}

# Secret outputs
output "screenconnect_license_secret_id" {
  description = "The OCID of the ScreenConnect license secret"
  value       = var.store_screenconnect_license ? oci_vault_secret.screenconnect_license[0].id : null
}

output "admin_password_secret_id" {
  description = "The OCID of the admin password secret"
  value       = var.store_admin_password ? oci_vault_secret.admin_password[0].id : null
}

output "cloudflare_api_token_secret_id" {
  description = "The OCID of the Cloudflare API token secret"
  value       = var.store_cloudflare_token ? oci_vault_secret.cloudflare_api_token[0].id : null
}

output "cloudflare_zone_id_secret_id" {
  description = "The OCID of the Cloudflare zone ID secret"
  value       = var.store_cloudflare_zone_id ? oci_vault_secret.cloudflare_zone_id[0].id : null
}

# Secret values (for use in other modules)
output "screenconnect_license_key" {
  description = "The ScreenConnect license key (from vault or variable)"
  value       = var.store_screenconnect_license ? base64decode(oci_vault_secret.screenconnect_license[0].secret_content[0].content) : var.screenconnect_license_key
  sensitive   = true
}

output "admin_password" {
  description = "The admin password (from vault or variable)"
  value       = var.store_admin_password ? base64decode(oci_vault_secret.admin_password[0].secret_content[0].content) : var.admin_password
  sensitive   = true
}

output "cloudflare_api_token" {
  description = "The Cloudflare API token (from vault or variable)"
  value       = var.store_cloudflare_token ? base64decode(oci_vault_secret.cloudflare_api_token[0].secret_content[0].content) : var.cloudflare_api_token
  sensitive   = true
}

output "cloudflare_zone_id" {
  description = "The Cloudflare zone ID (from vault or variable)"
  value       = var.store_cloudflare_zone_id ? base64decode(oci_vault_secret.cloudflare_zone_id[0].secret_content[0].content) : var.cloudflare_zone_id
  sensitive   = true
} 