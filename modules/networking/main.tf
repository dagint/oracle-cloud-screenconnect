# Oracle Cloud Networking Module for ScreenConnect
# Cost optimized configuration

# VCN
resource "oci_core_vcn" "vcn" {
  compartment_id = var.compartment_ocid
  cidr_blocks    = [var.vcn_cidr_block]
  display_name   = "${var.project_name}-${var.environment}-vcn"
  dns_label      = "${var.project_name}${var.environment}"

  freeform_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    Purpose     = "ScreenConnect deployment"
  })
}

# Internet Gateway
resource "oci_core_internet_gateway" "internet_gateway" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "${var.project_name}-${var.environment}-igw"

  freeform_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
  })
}

# Route Table
resource "oci_core_route_table" "route_table" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "${var.project_name}-${var.environment}-route-table"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.internet_gateway.id
  }

  freeform_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
  })
}

# Subnet
resource "oci_core_subnet" "subnet" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vcn.id
  cidr_block     = var.subnet_cidr_block
  display_name   = "${var.project_name}-${var.environment}-subnet"
  dns_label      = "${var.project_name}${var.environment}"

  route_table_id    = oci_core_route_table.route_table.id
  security_list_ids = [oci_core_security_list.security_list.id]

  freeform_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
  })
}

# Security List
resource "oci_core_security_list" "security_list" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "${var.project_name}-${var.environment}-security-list"

  # Egress rules - allow all outbound traffic
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }

  # Ingress rules
  dynamic "ingress_security_rules" {
    for_each = var.enable_rdp_access ? [1] : []
    content {
      protocol    = "6" # TCP
      source      = "0.0.0.0/0"
      source_type = "CIDR_BLOCK"
      tcp_options {
        min = 3389
        max = 3389
      }
    }
  }

  # ScreenConnect web UI (HTTP)
  ingress_security_rules {
    protocol    = "6" # TCP
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    tcp_options {
      min = 80
      max = 80
    }
  }

  # ScreenConnect web UI (HTTPS)
  ingress_security_rules {
    protocol    = "6" # TCP
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    tcp_options {
      min = 443
      max = 443
    }
  }

  # ScreenConnect relay protocol (port 8041 only)
  ingress_security_rules {
    protocol    = "6" # TCP
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    tcp_options {
      min = 8041
      max = 8041
    }
  }

  freeform_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
  })
}

# Data source to get current public IP
data "http" "current_ip" {
  count = var.auto_detect_home_ip ? 1 : 0
  url   = "https://api.ipify.org"
}

# Local file to store detected IPs for reference
resource "local_file" "detected_ips" {
  count    = var.auto_detect_home_ip ? 1 : 0
  filename = "${path.module}/detected_ips.txt"
  content  = "Detected IP: ${data.http.current_ip[0].response_body}/32\nTimestamp: ${timestamp()}\n"
} 