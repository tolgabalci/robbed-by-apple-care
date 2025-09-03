output "static_web_app_url" {
  description = "URL of the static web app"
  value       = module.static_site.static_web_app_url
}

output "discourse_vm_ip" {
  description = "Public IP of the Discourse VM"
  value       = module.discourse.vm_public_ip
}

output "www_endpoint_hostname" {
  description = "WWW Front Door endpoint hostname"
  value       = module.networking.www_endpoint_hostname
}

output "forum_endpoint_hostname" {
  description = "Forum Front Door endpoint hostname"
  value       = module.networking.forum_endpoint_hostname
}

output "dns_nameservers" {
  description = "DNS nameservers for domain configuration"
  value       = module.networking.dns_nameservers
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = module.security.key_vault_uri
  sensitive   = true
}

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "static_web_app_hostname" {
  description = "Static Web App hostname"
  value       = module.static_site.static_web_app_hostname
}