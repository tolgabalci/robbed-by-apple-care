# Azure Static Web App
resource "azurerm_static_web_app" "main" {
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
resource "azurerm_static_web_app_custom_domain" "www" {
  static_web_app_id = azurerm_static_web_app.main.id
  domain_name       = "www.${var.domain_name}"
  validation_type   = "dns-txt-token"

  depends_on = [azurerm_static_web_app.main]
}