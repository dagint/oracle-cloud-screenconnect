# Oracle Cloud Compute Module Outputs

output "instance_id" {
  description = "The OCID of the compute instance"
  value       = oci_core_instance.screenconnect.id
}

output "public_ip" {
  description = "The public IP address of the compute instance"
  value       = oci_core_instance.screenconnect.public_ip
}

output "private_ip" {
  description = "The private IP address of the compute instance"
  value       = oci_core_instance.screenconnect.private_ip
}

output "display_name" {
  description = "The display name of the compute instance"
  value       = oci_core_instance.screenconnect.display_name
} 