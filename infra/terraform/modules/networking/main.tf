# Azure Front Door Profile
resource "azurerm_cdn_frontdoor_profile" "main" {
  name                = "fd-robbedbyapplecare"
  resource_group_name = var.resource_group_name
  sku_name            = "Standard_AzureFrontDoor"

  tags = var.tags
}

# DNS Zone
resource "azurerm_dns_zone" "main" {
  name                = var.domain_name
  resource_group_name = var.resource_group_name

  tags = var.tags
}

# WAF Policy
resource "azurerm_cdn_frontdoor_firewall_policy" "main" {
  name                = "wafrobbedbyapplecare"
  resource_group_name = var.resource_group_name
  sku_name            = azurerm_cdn_frontdoor_profile.main.sku_name
  enabled             = true
  mode                = "Prevention"

  managed_rule {
    type    = "DefaultRuleSet"
    version = "1.0"
    action  = "Block"
  }

  managed_rule {
    type    = "Microsoft_BotManagerRuleSet"
    version = "1.0"
    action  = "Block"
  }

  tags = var.tags
}

# Front Door Endpoint for www subdomain
resource "azurerm_cdn_frontdoor_endpoint" "www" {
  name                     = "www-robbedbyapplecare"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id

  tags = var.tags
}

# Front Door Endpoint for forum subdomain
resource "azurerm_cdn_frontdoor_endpoint" "forum" {
  name                     = "forum-robbedbyapplecare"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id

  tags = var.tags
}

# Origin Group for Static Web App
resource "azurerm_cdn_frontdoor_origin_group" "static_site" {
  name                     = "static-site-origin-group"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id

  load_balancing {
    sample_size                 = 4
    successful_samples_required = 3
  }

  health_probe {
    path                = "/"
    request_type        = "HEAD"
    protocol            = "Https"
    interval_in_seconds = 100
  }
}

# Origin Group for Discourse VM
resource "azurerm_cdn_frontdoor_origin_group" "discourse" {
  name                     = "discourse-origin-group"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id

  load_balancing {
    sample_size                 = 4
    successful_samples_required = 3
  }

  health_probe {
    path                = "/srv/status"
    request_type        = "GET"
    protocol            = "Https"
    interval_in_seconds = 100
  }
}

# Origin for Static Web App
resource "azurerm_cdn_frontdoor_origin" "static_site" {
  name                          = "static-site-origin"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.static_site.id

  enabled                        = true
  host_name                      = var.static_web_app_hostname
  http_port                      = 80
  https_port                     = 443
  origin_host_header            = var.static_web_app_hostname
  priority                      = 1
  weight                        = 1000
  certificate_name_check_enabled = true
}

# Origin for Discourse VM
resource "azurerm_cdn_frontdoor_origin" "discourse" {
  name                          = "discourse-origin"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.discourse.id

  enabled                        = true
  host_name                      = var.discourse_vm_hostname
  http_port                      = 80
  https_port                     = 443
  origin_host_header            = var.discourse_vm_hostname
  priority                      = 1
  weight                        = 1000
  certificate_name_check_enabled = true
}

# Custom Domain for www
resource "azurerm_cdn_frontdoor_custom_domain" "www" {
  name                     = "www-robbedbyapplecare-com"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id
  dns_zone_id              = azurerm_dns_zone.main.id
  host_name                = "www.${var.domain_name}"

  tls {
    certificate_type    = "ManagedCertificate"
    minimum_tls_version = "TLS12"
  }
}

# Custom Domain for forum
resource "azurerm_cdn_frontdoor_custom_domain" "forum" {
  name                     = "forum-robbedbyapplecare-com"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id
  dns_zone_id              = azurerm_dns_zone.main.id
  host_name                = "forum.${var.domain_name}"

  tls {
    certificate_type    = "ManagedCertificate"
    minimum_tls_version = "TLS12"
  }
}

# Route for www subdomain
resource "azurerm_cdn_frontdoor_route" "www" {
  name                          = "www-route"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.www.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.static_site.id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.static_site.id]

  supported_protocols    = ["Http", "Https"]
  patterns_to_match      = ["/*"]
  forwarding_protocol    = "HttpsOnly"
  link_to_default_domain = true

  cdn_frontdoor_custom_domain_ids = [azurerm_cdn_frontdoor_custom_domain.www.id]
  cdn_frontdoor_rule_set_ids      = []

  cache {
    query_string_caching_behavior = "IgnoreQueryString"
    query_strings                 = []
    compression_enabled           = true
    content_types_to_compress = [
      "application/eot",
      "application/font",
      "application/font-sfnt",
      "application/javascript",
      "application/json",
      "application/opentype",
      "application/otf",
      "application/pkcs7-mime",
      "application/truetype",
      "application/ttf",
      "application/vnd.ms-fontobject",
      "application/xhtml+xml",
      "application/xml",
      "application/xml+rss",
      "application/x-font-opentype",
      "application/x-font-truetype",
      "application/x-font-ttf",
      "application/x-httpd-cgi",
      "application/x-javascript",
      "application/x-mpegurl",
      "application/x-opentype",
      "application/x-otf",
      "application/x-perl",
      "application/x-ttf",
      "font/eot",
      "font/ttf",
      "font/otf",
      "font/opentype",
      "image/svg+xml",
      "text/css",
      "text/csv",
      "text/html",
      "text/javascript",
      "text/js",
      "text/plain",
      "text/richtext",
      "text/tab-separated-values",
      "text/xml",
      "text/x-script",
      "text/x-component",
      "text/x-java-source"
    ]
  }
}

# Route for forum subdomain
resource "azurerm_cdn_frontdoor_route" "forum" {
  name                          = "forum-route"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.forum.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.discourse.id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.discourse.id]

  supported_protocols    = ["Http", "Https"]
  patterns_to_match      = ["/*"]
  forwarding_protocol    = "HttpsOnly"
  link_to_default_domain = true

  cdn_frontdoor_custom_domain_ids = [azurerm_cdn_frontdoor_custom_domain.forum.id]
  cdn_frontdoor_rule_set_ids      = []

  cache {
    query_string_caching_behavior = "UseQueryString"
    query_strings                 = []
    compression_enabled           = true
    content_types_to_compress = [
      "application/javascript",
      "application/json",
      "application/xml",
      "text/css",
      "text/html",
      "text/javascript",
      "text/plain"
    ]
  }
}

# Security Policy Association for www
resource "azurerm_cdn_frontdoor_security_policy" "www" {
  name                     = "www-security-policy"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id

  security_policies {
    firewall {
      cdn_frontdoor_firewall_policy_id = azurerm_cdn_frontdoor_firewall_policy.main.id

      association {
        domain {
          cdn_frontdoor_domain_id = azurerm_cdn_frontdoor_custom_domain.www.id
        }
        patterns_to_match = ["/*"]
      }
    }
  }
}

# Security Policy Association for forum
resource "azurerm_cdn_frontdoor_security_policy" "forum" {
  name                     = "forum-security-policy"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id

  security_policies {
    firewall {
      cdn_frontdoor_firewall_policy_id = azurerm_cdn_frontdoor_firewall_policy.main.id

      association {
        domain {
          cdn_frontdoor_domain_id = azurerm_cdn_frontdoor_custom_domain.forum.id
        }
        patterns_to_match = ["/*"]
      }
    }
  }
}

# DNS CNAME record for www
resource "azurerm_dns_cname_record" "www" {
  name                = "www"
  zone_name           = azurerm_dns_zone.main.name
  resource_group_name = var.resource_group_name
  ttl                 = 3600
  record              = azurerm_cdn_frontdoor_endpoint.www.host_name

  tags = var.tags
}

# DNS CNAME record for forum
resource "azurerm_dns_cname_record" "forum" {
  name                = "forum"
  zone_name           = azurerm_dns_zone.main.name
  resource_group_name = var.resource_group_name
  ttl                 = 3600
  record              = azurerm_cdn_frontdoor_endpoint.forum.host_name

  tags = var.tags
}