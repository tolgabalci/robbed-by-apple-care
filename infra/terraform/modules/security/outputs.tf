output "key_vault_id" {
  description = "Key Vault ID"
  value       = azurerm_key_vault.main.id
}

output "key_vault_uri" {
  description = "Key Vault URI"
  value       = azurerm_key_vault.main.vault_uri
}

output "key_vault_name" {
  description = "Key Vault name"
  value       = azurerm_key_vault.main.name
}

output "postgresql_admin_password_secret_id" {
  description = "PostgreSQL admin password secret ID"
  value       = azurerm_key_vault_secret.postgresql_admin_password.id
}

output "storage_access_key_secret_id" {
  description = "Storage access key secret ID"
  value       = var.storage_account_access_key != null ? azurerm_key_vault_secret.storage_access_key[0].id : null
}

output "google_oauth_client_id_secret_id" {
  description = "Google OAuth client ID secret ID"
  value       = var.google_oauth_client_id != null ? azurerm_key_vault_secret.google_oauth_client_id[0].id : null
}

output "google_oauth_client_secret_secret_id" {
  description = "Google OAuth client secret secret ID"
  value       = var.google_oauth_client_secret != null ? azurerm_key_vault_secret.google_oauth_client_secret[0].id : null
}

output "facebook_oauth_app_id_secret_id" {
  description = "Facebook OAuth app ID secret ID"
  value       = var.facebook_oauth_app_id != null ? azurerm_key_vault_secret.facebook_oauth_app_id[0].id : null
}

output "facebook_oauth_app_secret_secret_id" {
  description = "Facebook OAuth app secret secret ID"
  value       = var.facebook_oauth_app_secret != null ? azurerm_key_vault_secret.facebook_oauth_app_secret[0].id : null
}

output "smtp_server_secret_id" {
  description = "SMTP server secret ID"
  value       = var.smtp_server != null ? azurerm_key_vault_secret.smtp_server[0].id : null
}

output "smtp_username_secret_id" {
  description = "SMTP username secret ID"
  value       = var.smtp_username != null ? azurerm_key_vault_secret.smtp_username[0].id : null
}

output "smtp_password_secret_id" {
  description = "SMTP password secret ID"
  value       = var.smtp_password != null ? azurerm_key_vault_secret.smtp_password[0].id : null
}