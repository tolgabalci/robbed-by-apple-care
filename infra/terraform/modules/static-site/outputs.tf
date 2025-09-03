output "static_web_app_id" {
  description = "Static Web App ID"
  value       = azurerm_static_web_app.main.id
}

output "static_web_app_url" {
  description = "Static Web App default URL"
  value       = azurerm_static_web_app.main.default_host_name
}

output "static_web_app_hostname" {
  description = "Static Web App hostname for Front Door origin"
  value       = azurerm_static_web_app.main.default_host_name
}

output "api_key" {
  description = "Static Web App API key for deployments"
  value       = azurerm_static_web_app.main.api_key
  sensitive   = true
}

output "custom_domain_validation_token" {
  description = "Custom domain validation token"
  value       = azurerm_static_web_app_custom_domain.www.validation_token
  sensitive   = true
}