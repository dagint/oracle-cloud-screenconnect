# Oracle Cloud Storage Module
# Object Storage bucket for ScreenConnect backups

# Object Storage bucket
resource "oci_objectstorage_bucket" "backup_bucket" {
  compartment_id = var.compartment_ocid
  name           = var.bucket_name
  namespace      = data.oci_objectstorage_namespace.ns.namespace
  access_type    = "NoPublicAccess"
  versioning     = "Enabled"

  freeform_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    Service     = "screenconnect-backups"
  })
}

# Data source for namespace
data "oci_objectstorage_namespace" "ns" {
  compartment_id = var.compartment_ocid
} 