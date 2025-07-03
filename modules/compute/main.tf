# Oracle Cloud Compute Module
# Single Windows instance for ScreenConnect deployment

# Compute instance
resource "oci_core_instance" "screenconnect" {
  availability_domain = var.availability_domain
  compartment_id      = var.compartment_ocid
  display_name        = "${var.project_name}-${var.environment}"
  shape               = var.instance_shape

  shape_config {
    ocpus         = var.ocpus
    memory_in_gbs = var.memory_in_gbs
  }

  create_vnic_details {
    subnet_id        = var.subnet_id
    assign_public_ip = true
  }

  source_details {
    source_type = "image"
    source_id   = local.windows_image_id
  }

  metadata = {
    ssh_authorized_keys = file(var.ssh_public_key_path)
    user_data = base64encode(templatefile("${path.module}/user_data.tpl", {
      screenconnect_license_key = var.screenconnect_license_key
      admin_password           = var.admin_password
      backup_bucket_name       = var.backup_bucket_name
      backup_retention         = var.backup_retention
      vault_id                 = var.vault_id
      primary_domain           = var.primary_domain
      relay_domain             = var.relay_domain
    }))
  }

  freeform_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    Service     = "screenconnect"
  })

  # Validation to ensure Windows image is available
  lifecycle {
    precondition {
      condition     = local.windows_image_id != null
      error_message = "No Windows Server 2022 image found in the compartment. Please check your Oracle Cloud region and compartment settings."
    }
  }
}

# Data source for Windows images
data "oci_core_images" "windows_images" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Windows"
  operating_system_version = "2022"
  state                    = "AVAILABLE"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
  
  # Filter for the most recent Windows Server 2022 image
  filter {
    name   = "display_name"
    values = ["Windows-Server-2022-*"]
    regex  = true
  }
}

# Local to get the most recent Windows Server 2022 image
locals {
  windows_image_id = length(data.oci_core_images.windows_images.images) > 0 ? data.oci_core_images.windows_images.images[0].id : null
} 