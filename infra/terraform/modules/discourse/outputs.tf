output "vm_public_ip" {
  description = "Public IP address of the Discourse VM"
  value       = azurerm_public_ip.vm.ip_address
}

output "vm_fqdn" {
  description = "FQDN of the Discourse VM"
  value       = azurerm_public_ip.vm.fqdn
}

output "vm_hostname" {
  description = "Hostname for Front Door origin"
  value       = azurerm_public_ip.vm.ip_address
}

output "vm_managed_identity_id" {
  description = "Managed Identity ID for the VM"
  value       = azurerm_user_assigned_identity.vm.id
}

output "vm_managed_identity_principal_id" {
  description = "Managed Identity Principal ID for the VM"
  value       = azurerm_user_assigned_identity.vm.principal_id
}

output "postgresql_fqdn" {
  description = "PostgreSQL server FQDN"
  value       = azurerm_postgresql_flexible_server.main.fqdn
}

output "postgresql_database_name" {
  description = "PostgreSQL database name"
  value       = azurerm_postgresql_flexible_server_database.discourse.name
}

output "postgresql_admin_username" {
  description = "PostgreSQL admin username"
  value       = azurerm_postgresql_flexible_server.main.administrator_login
}

output "storage_account_name" {
  description = "Storage account name for Discourse uploads"
  value       = azurerm_storage_account.discourse.name
}

output "storage_account_primary_access_key" {
  description = "Storage account primary access key"
  value       = data.azurerm_storage_account.discourse.primary_access_key
  sensitive   = true
}

output "storage_account_primary_blob_endpoint" {
  description = "Storage account primary blob endpoint"
  value       = azurerm_storage_account.discourse.primary_blob_endpoint
}

output "uploads_container_name" {
  description = "Uploads container name"
  value       = azurerm_storage_container.uploads.name
}

output "backups_container_name" {
  description = "Backups container name"
  value       = azurerm_storage_container.backups.name
}

output "vnet_id" {
  description = "Virtual Network ID"
  value       = azurerm_virtual_network.main.id
}

output "vm_subnet_id" {
  description = "VM Subnet ID"
  value       = azurerm_subnet.vm.id
}