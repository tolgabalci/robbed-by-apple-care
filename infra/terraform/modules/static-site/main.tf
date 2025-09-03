# Azure Static Web Apps
resource "azurerm_static_site" "main" {
  name                = "swa-robbedbyapplecare"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku_tier            = "Standard"
  sku_size            = "Standard"

  app_settings = {
    "NEXT_PUBLIC_SITE_URL"  = "https://www.${var.domain_name}"
    "NEXT_PUBLIC_FORUM_URL" = "https://forum.${var.domain_name}"
  }

  tags = var.tags
}

# Custom Domain for Static Web App
resource "azurerm_static_site_custom_domain" "www" {
  static_site_id  = azurerm_static_site.main.id
  domain_name     = "www.${var.domain_name}"
  validation_type = "dns-txt-token"

  depends_on = [azurerm_static_site.main]
}

# Production deployment slot (default)
# Note: The production slot is created automatically with the static site

# Staging deployment slot
resource "azurerm_static_site_deployment_slot" "staging" {
  name           = "staging"
  static_site_id = azurerm_static_site.main.id

  app_settings = {
    "NEXT_PUBLIC_SITE_URL"  = "https://staging-www.${var.domain_name}"
    "NEXT_PUBLIC_FORUM_URL" = "https://forum.${var.domain_name}"
    "ENVIRONMENT"           = "staging"
  }

  tags = var.tags
}