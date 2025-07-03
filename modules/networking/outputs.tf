# Oracle Cloud Networking Module Outputs

output "vcn_id" {
  description = "The OCID of the VCN"
  value       = oci_core_vcn.vcn.id
}

output "vcn_cidr_block" {
  description = "The CIDR block of the VCN"
  value       = oci_core_vcn.vcn.cidr_blocks[0]
}

output "public_subnet_id" {
  description = "The OCID of the public subnet"
  value       = oci_core_subnet.public_subnet.id
}

output "private_subnet_id" {
  description = "The OCID of the private subnet"
  value       = oci_core_subnet.private_subnet.id
}

output "subnet_id" {
  description = "The OCID of the subnet"
  value       = oci_core_subnet.subnet.id
}

output "subnet_cidr_block" {
  description = "The CIDR block of the subnet"
  value       = oci_core_subnet.subnet.cidr_block
}

output "security_list_id" {
  description = "The OCID of the security list"
  value       = oci_core_security_list.security_list.id
}

output "route_table_id" {
  description = "The OCID of the route table"
  value       = oci_core_route_table.route_table.id
}

output "internet_gateway_id" {
  description = "The OCID of the internet gateway"
  value       = oci_core_internet_gateway.internet_gateway.id
}

output "detected_public_ip" {
  description = "The detected public IP address"
  value       = var.auto_detect_home_ip ? data.http.current_ip[0].response_body : null
}

output "rdp_access_enabled" {
  description = "Whether RDP access is enabled"
  value       = var.enable_rdp_access
}

output "rdp_access_info" {
  description = "Information about RDP access configuration"
  value = {
    enabled           = var.enable_rdp_access
    auto_detect_ip    = var.auto_detect_home_ip
    detected_ip       = var.auto_detect_home_ip ? "${data.http.current_ip[0].response_body}/32" : null
    timestamp         = var.auto_detect_home_ip ? timestamp() : null
  }
} 