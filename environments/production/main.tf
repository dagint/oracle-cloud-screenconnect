# Oracle Cloud ScreenConnect Deployment
# Cost optimized configuration for production

terraform {
  required_version = ">= 1.0"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 5.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

# Configure Oracle Cloud Provider
provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region
}

# Configure Cloudflare provider
provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

# Data sources
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}

# Get first availability domain
locals {
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
}

# Networking Module
module "networking" {
  source = "../../modules/networking"

  compartment_ocid     = var.compartment_ocid
  project_name         = var.project_name
  environment          = var.environment
  vcn_cidr_block       = var.vcn_cidr_block
  subnet_cidr_block    = var.subnet_cidr_block
  availability_domain  = local.availability_domain
  enable_rdp_access    = var.enable_rdp_access
  auto_detect_home_ip  = var.auto_detect_home_ip
  tags                 = var.tags
}

# Storage Module
module "storage" {
  source = "../../modules/storage"

  compartment_ocid = var.compartment_ocid
  project_name     = var.project_name
  environment      = var.environment
  bucket_name      = var.backup_bucket_name
  tags             = var.tags
}

# Vault Module (with secrets management)
module "vault" {
  source = "../../modules/vault"

  compartment_ocid         = var.compartment_ocid
  project_name             = var.project_name
  environment              = var.environment
  vault_name               = "${var.project_name}-${var.environment}-vault"
  
  # Secrets management configuration
  store_screenconnect_license = var.use_vault_for_secrets
  store_admin_password        = var.use_vault_for_secrets
  store_cloudflare_token      = var.use_vault_for_secrets
  store_cloudflare_zone_id    = var.use_vault_for_secrets
  
  # Secret values (only used if storing in vault)
  screenconnect_license_key = var.screenconnect_license_key
  admin_password           = var.admin_password
  cloudflare_api_token     = var.cloudflare_api_token
  cloudflare_zone_id       = var.cloudflare_zone_id
  
  tags = var.tags
}

# Compute Module
module "compute" {
  source = "../../modules/compute"

  compartment_ocid         = var.compartment_ocid
  project_name             = var.project_name
  environment              = var.environment
  availability_domain      = local.availability_domain
  subnet_id                = var.enable_rdp_access ? oci_core_subnet.subnet_with_rdp[0].id : module.networking.subnet_id
  instance_shape           = var.instance_shape
  ocpus                    = var.ocpus
  memory_in_gbs            = var.memory_in_gbs
  ssh_public_key_path      = var.ssh_public_key_path
  
  # Use secrets from vault or direct variables
  screenconnect_license_key = var.use_vault_for_secrets ? module.vault.screenconnect_license_key : var.screenconnect_license_key
  admin_password           = var.use_vault_for_secrets ? module.vault.admin_password : var.admin_password
  backup_bucket_name       = var.backup_bucket_name
  backup_retention         = var.backup_retention
  vault_id                 = module.vault.vault_id
  primary_domain           = var.primary_domain
  relay_domain             = var.relay_domain
  tags                     = var.tags
}

# Cloudflare DNS Module
module "cloudflare_dns" {
  source = "../../modules/cloudflare_dns"

  zone_id        = var.use_vault_for_secrets ? module.vault.cloudflare_zone_id : var.cloudflare_zone_id
  primary_domain = var.primary_domain
  relay_domain   = var.relay_domain
  public_ip      = module.compute.public_ip
  private_ip     = module.compute.private_ip
  enable_proxy   = var.enable_cloudflare_proxy
  ssl_mode       = var.cloudflare_ssl_mode
}

# Create RDP-specific security list for restricted access
resource "oci_core_security_list" "rdp_security_list" {
  count          = var.enable_rdp_access ? 1 : 0
  compartment_id = var.compartment_ocid
  vcn_id         = module.networking.vcn_id
  display_name   = "${var.project_name}-${var.environment}-rdp-security-list"

  # Egress rules - allow all outbound traffic
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }

  # RDP access from detected IP
  dynamic "ingress_security_rules" {
    for_each = var.auto_detect_home_ip ? [1] : []
    content {
      protocol    = "6" # TCP
      source      = "${module.networking.detected_public_ip}/32"
      source_type = "CIDR_BLOCK"
      tcp_options {
        min = 3389
        max = 3389
      }
    }
  }

  # RDP access from additional specified IPs
  dynamic "ingress_security_rules" {
    for_each = var.additional_rdp_ips
    content {
      protocol    = "6" # TCP
      source      = ingress_security_rules.value
      source_type = "CIDR_BLOCK"
      tcp_options {
        min = 3389
        max = 3389
      }
    }
  }

  freeform_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    Purpose     = "RDP access control"
  })
}

# Update subnet to include RDP security list
resource "oci_core_subnet" "subnet_with_rdp" {
  count               = var.enable_rdp_access ? 1 : 0
  compartment_id      = var.compartment_ocid
  vcn_id              = module.networking.vcn_id
  cidr_block          = var.subnet_cidr_block
  display_name        = "${var.project_name}-${var.environment}-subnet-with-rdp"
  dns_label           = "${var.project_name}${var.environment}rdp"
  route_table_id      = module.networking.route_table_id
  security_list_ids   = [module.networking.security_list_id, oci_core_security_list.rdp_security_list[0].id]

  freeform_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    Purpose     = "ScreenConnect with RDP access"
  })

  depends_on = [module.networking, oci_core_security_list.rdp_security_list]
}

# Output deployment information
output "deployment_info" {
  description = "Deployment information"
  value = {
    project_name        = var.project_name
    environment         = var.environment
    instance_public_ip  = module.compute.public_ip
    primary_domain      = var.primary_domain
    relay_domain        = var.relay_domain
    rdp_access_enabled  = var.enable_rdp_access
    detected_home_ip    = var.auto_detect_home_ip ? module.networking.detected_public_ip : null
    additional_rdp_ips  = var.additional_rdp_ips
    backup_bucket       = module.storage.bucket_name
    vault_name          = module.vault.vault_name
    secrets_managed     = var.use_vault_for_secrets
  }
}

output "rdp_connection_info" {
  description = "RDP connection information"
  value = {
    instance_ip         = module.compute.public_ip
    rdp_port           = 3389
    allowed_ips        = concat(
      var.auto_detect_home_ip ? ["${module.networking.detected_public_ip}/32"] : [],
      var.additional_rdp_ips
    )
    connection_command = "mstsc /v:${module.compute.public_ip}:3389"
  }
}

output "secrets_info" {
  description = "Information about secrets management"
  value = {
    vault_used          = var.use_vault_for_secrets
    vault_name          = module.vault.vault_name
    secrets_stored      = var.use_vault_for_secrets ? [
      "screenconnect_license",
      "admin_password", 
      "cloudflare_api_token",
      "cloudflare_zone_id"
    ] : []
  }
  sensitive = true
} 