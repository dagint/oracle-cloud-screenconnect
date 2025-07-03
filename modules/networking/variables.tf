# Oracle Cloud Networking Module Variables

variable "compartment_ocid" {
  description = "The OCID of the compartment where resources will be created"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vcn_cidr_block" {
  description = "CIDR block for the VCN"
  type        = string
}

variable "subnet_cidr_block" {
  description = "CIDR block for the subnet"
  type        = string
}

variable "availability_domain" {
  description = "Availability domain for the subnet"
  type        = string
}

# RDP Access Configuration
variable "enable_rdp_access" {
  description = "Whether to enable RDP access from specified IP addresses"
  type        = bool
  default     = true
}

variable "auto_detect_home_ip" {
  description = "Whether to automatically detect and include current public IP for RDP access"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
} 