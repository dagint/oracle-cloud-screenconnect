# Oracle Cloud Compute Module Variables

variable "availability_domain" {
  description = "The availability domain where the instance will be created"
  type        = string
}

variable "compartment_ocid" {
  description = "The OCID of the compartment where the instance will be created"
  type        = string
}

variable "subnet_id" {
  description = "The OCID of the subnet where the instance will be created"
  type        = string
}

variable "instance_shape" {
  description = "The shape of the compute instance"
  type        = string
  default     = "VM.Standard.A1.Flex"
}

variable "ocpus" {
  description = "Number of OCPUs for the instance"
  type        = number
  default     = 1
}

variable "memory_in_gbs" {
  description = "Amount of memory in GB for the instance"
  type        = number
  default     = 6
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key file"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "screenconnect_license_key" {
  description = "ScreenConnect license key"
  type        = string
  sensitive   = true
}

variable "admin_password" {
  description = "Admin password for ScreenConnect"
  type        = string
  sensitive   = true
}

variable "backup_bucket_name" {
  description = "Name of the Object Storage bucket for backups"
  type        = string
}

variable "backup_retention" {
  description = "Number of backups to retain"
  type        = number
  default     = 5
}

variable "vault_id" {
  description = "The OCID of the vault for secrets management"
  type        = string
}

variable "primary_domain" {
  description = "Primary domain for ScreenConnect web UI"
  type        = string
}

variable "relay_domain" {
  description = "Relay domain for ScreenConnect relay protocol"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "screenconnect"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
} 