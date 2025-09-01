output "static_web_app_id" {
  description = "Static Web App ID"
  value       = azurerm_static_site.main.id
}

output "static_web_app_url" {
  description = "Static Web App default URL"
  value       = azurerm_static_site.main.default_host_name
}

output "static_web_app_hostname" {
  description = "Static Web App hostname for Front Door origin"
  value       = azurerm_static_site.main.default_host_name
}

output "staging_slot_url" {
  description = "Staging deployment slot URL"
  value       = azurerm_static_site_deployment_slot.staging.default_host_name
}

output "api_key" {
  description = "Static Web App API key for deployments"
  value       = azurerm_static_site.main.api_key
  sensitive   = true
}

output "custom_domain_validation_token" {
  description = "Custom domain validation token"
  value       = azurerm_static_site_custom_domain.www.validation_token
  sensitive   = true
}