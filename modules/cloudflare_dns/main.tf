# Cloudflare DNS Module
# Manages DNS records for ScreenConnect deployment - Cost optimized

# Primary domain A record (web UI) - remotesupport.yourdomain.com
resource "cloudflare_record" "primary_domain" {
  zone_id = var.zone_id
  name    = var.primary_domain
  value   = var.public_ip
  type    = "A"
  ttl     = 1 # Auto TTL
  proxied = var.enable_proxy

  depends_on = [cloudflare_record.relay_domain]
}

# Relay domain A record (relay protocol) - relay.yourdomain.com
resource "cloudflare_record" "relay_domain" {
  zone_id = var.zone_id
  name    = var.relay_domain
  value   = var.public_ip
  type    = "A"
  ttl     = 1 # Auto TTL
  proxied = false # Relay protocol should not be proxied through Cloudflare

  # Add comment for documentation
  comment = "ScreenConnect Relay Protocol - Direct connection required"
}

# Page rule for SSL enforcement - remotesupport.yourdomain.com
resource "cloudflare_page_rule" "ssl_enforcement" {
  zone_id = var.zone_id
  target  = "${var.primary_domain}/*"
  priority = 1

  actions {
    ssl = "full"
    always_use_https = true
  }
}

# Page rule for security headers - remotesupport.yourdomain.com
resource "cloudflare_page_rule" "security_headers" {
  zone_id = var.zone_id
  target  = "${var.primary_domain}/*"
  priority = 2

  actions {
    security_level = "high"
    browser_check = "on"
    challenge_ttl = 1800
    minify {
      css  = "off"
      html = "off"
      js   = "off"
    }
  }
}

# Zone settings for security
resource "cloudflare_zone_settings_override" "security_settings" {
  zone_id = var.zone_id

  settings {
    # SSL/TLS
    ssl                      = var.ssl_mode
    always_use_https         = "on"
    min_tls_version          = "1.2"
    opportunistic_encryption = "on"
    tls_1_3                  = "zrt"
    
    # Security
    security_level           = "high"
    browser_check            = "on"
    challenge_ttl            = 1800
    security_header {
      enabled = true
      include_subdomains = true
      preload = true
      max_age = 31536000 # 1 year
    }
    
    # Performance
    rocket_loader            = "off" # Can interfere with ScreenConnect
    minify {
      css  = "off"
      html = "off"
      js   = "off"
    }
    
    # Caching
    cache_level              = "standard"
    edge_cache_ttl           = 3600
    browser_cache_ttl        = 1800
    
    # Other
    always_online            = "on"
    development_mode         = "off"
    websockets               = "on"
  }
} 