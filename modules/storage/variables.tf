# Oracle Cloud Storage Module Variables

variable "compartment_ocid" {
  description = "The OCID of the compartment where the bucket will be created"
  type        = string
}

variable "bucket_name" {
  description = "Name of the Object Storage bucket"
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