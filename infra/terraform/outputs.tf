output "static_web_app_url" {
  description = "URL of the static web app"
  value       = module.static_site.static_web_app_url
}

output "discourse_vm_ip" {
  description = "Public IP of the Discourse VM"
  value       = module.discourse.vm_public_ip
}

output "front_door_endpoint" {
  description = "Front Door endpoint URL"
  value       = module.networking.front_door_endpoint
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