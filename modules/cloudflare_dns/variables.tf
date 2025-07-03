# Cloudflare DNS Module Variables

variable "zone_id" {
  description = "Cloudflare zone ID for the domain"
  type        = string
}

variable "primary_domain" {
  description = "Primary domain for ScreenConnect web UI (remotesupport.yourdomain.com)"
  type        = string
}

variable "relay_domain" {
  description = "Relay domain for ScreenConnect relay protocol (relay.yourdomain.com)"
  type        = string
}

variable "public_ip" {
  description = "Public IP address of the compute instance"
  type        = string
}

variable "private_ip" {
  description = "Private IP address of the compute instance"
  type        = string
}

variable "load_balancer_ip" {
  description = "Public IP address of the load balancer (if enabled)"
  type        = string
  default     = null
}

variable "enable_proxy" {
  description = "Whether to enable Cloudflare proxy (orange cloud)"
  type        = bool
  default     = true
}

variable "ssl_mode" {
  description = "Cloudflare SSL mode (flexible, full, full_strict)"
  type        = string
  default     = "full"
}

variable "enable_www_redirect" {
  description = "Whether to enable www to non-www redirect"
  type        = bool
  default     = false
} 