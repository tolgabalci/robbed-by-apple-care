output "front_door_profile_id" {
  description = "Front Door profile ID"
  value       = azurerm_cdn_frontdoor_profile.main.id
}

output "www_endpoint_hostname" {
  description = "WWW endpoint hostname"
  value       = azurerm_cdn_frontdoor_endpoint.www.host_name
}

output "forum_endpoint_hostname" {
  description = "Forum endpoint hostname"
  value       = azurerm_cdn_frontdoor_endpoint.forum.host_name
}

output "dns_zone_id" {
  description = "DNS zone ID"
  value       = azurerm_dns_zone.main.id
}

output "dns_nameservers" {
  description = "DNS nameservers"
  value       = azurerm_dns_zone.main.name_servers
}

output "waf_policy_id" {
  description = "WAF policy ID"
  value       = azurerm_cdn_frontdoor_firewall_policy.main.id
}

output "static_site_origin_group_id" {
  description = "Static site origin group ID"
  value       = azurerm_cdn_frontdoor_origin_group.static_site.id
}

output "discourse_origin_group_id" {
  description = "Discourse origin group ID"
  value       = azurerm_cdn_frontdoor_origin_group.discourse.id
}