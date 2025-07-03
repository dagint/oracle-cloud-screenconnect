# Oracle Cloud Storage Module Outputs

output "bucket_id" {
  description = "The OCID of the Object Storage bucket"
  value       = oci_objectstorage_bucket.backup_bucket.id
}

output "bucket_name" {
  description = "The name of the Object Storage bucket"
  value       = oci_objectstorage_bucket.backup_bucket.name
}

output "namespace" {
  description = "The namespace of the Object Storage bucket"
  value       = oci_objectstorage_bucket.backup_bucket.namespace
} 