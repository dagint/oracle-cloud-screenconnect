# Oracle Cloud Vault Module
# Vault for secrets management

# Vault
resource "oci_kms_vault" "screenconnect_vault" {
  compartment_id = var.compartment_ocid
  display_name   = var.vault_name
  vault_type     = "DEFAULT"

  freeform_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    Service     = "screenconnect-secrets"
  })
}

# Master encryption key
resource "oci_kms_key" "master_key" {
  compartment_id = var.compartment_ocid
  display_name   = "${var.vault_name}-master-key"
  key_shape {
    algorithm = "AES"
    length    = 32
  }
  management_endpoint = oci_kms_vault.screenconnect_vault.management_endpoint

  freeform_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    Service     = "screenconnect-encryption"
  })
}

# Secrets for sensitive configuration
resource "oci_vault_secret" "screenconnect_license" {
  count = var.store_screenconnect_license ? 1 : 0
  
  compartment_id = var.compartment_ocid
  vault_id       = oci_kms_vault.screenconnect_vault.id
  key_id         = oci_kms_key.master_key.id
  secret_name    = "${var.vault_name}-screenconnect-license"
  description    = "ScreenConnect license key"
  secret_content {
    content_type = "BASE64"
    content      = base64encode(var.screenconnect_license_key)
  }

  freeform_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    SecretType  = "license"
  })
}

resource "oci_vault_secret" "admin_password" {
  count = var.store_admin_password ? 1 : 0
  
  compartment_id = var.compartment_ocid
  vault_id       = oci_kms_vault.screenconnect_vault.id
  key_id         = oci_kms_key.master_key.id
  secret_name    = "${var.vault_name}-admin-password"
  description    = "ScreenConnect admin password"
  secret_content {
    content_type = "BASE64"
    content      = base64encode(var.admin_password)
  }

  freeform_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    SecretType  = "password"
  })
}

resource "oci_vault_secret" "cloudflare_api_token" {
  count = var.store_cloudflare_token ? 1 : 0
  
  compartment_id = var.compartment_ocid
  vault_id       = oci_kms_vault.screenconnect_vault.id
  key_id         = oci_kms_key.master_key.id
  secret_name    = "${var.vault_name}-cloudflare-api-token"
  description    = "Cloudflare API token for DNS management"
  secret_content {
    content_type = "BASE64"
    content      = base64encode(var.cloudflare_api_token)
  }

  freeform_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    SecretType  = "api-token"
  })
}

resource "oci_vault_secret" "cloudflare_zone_id" {
  count = var.store_cloudflare_zone_id ? 1 : 0
  
  compartment_id = var.compartment_ocid
  vault_id       = oci_kms_vault.screenconnect_vault.id
  key_id         = oci_kms_key.master_key.id
  secret_name    = "${var.vault_name}-cloudflare-zone-id"
  description    = "Cloudflare zone ID for DNS management"
  secret_content {
    content_type = "BASE64"
    content      = base64encode(var.cloudflare_zone_id)
  }

  freeform_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    SecretType  = "zone-id"
  })
}

# Data sources to retrieve secrets (for use in other modules)
data "oci_vault_secret" "screenconnect_license_data" {
  count = var.store_screenconnect_license ? 1 : 0
  secret_id = oci_vault_secret.screenconnect_license[0].id
}

data "oci_vault_secret" "admin_password_data" {
  count = var.store_admin_password ? 1 : 0
  secret_id = oci_vault_secret.admin_password[0].id
}

data "oci_vault_secret" "cloudflare_api_token_data" {
  count = var.store_cloudflare_token ? 1 : 0
  secret_id = oci_vault_secret.cloudflare_api_token[0].id
}

data "oci_vault_secret" "cloudflare_zone_id_data" {
  count = var.store_cloudflare_zone_id ? 1 : 0
  secret_id = oci_vault_secret.cloudflare_zone_id[0].id
} 