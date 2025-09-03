# Get current client configuration
data "azurerm_client_config" "current" {}

# Key Vault
resource "azurerm_key_vault" "main" {
  name                = "kv-robbedbyapplecare-${random_string.kv_suffix.result}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  # Security settings
  enabled_for_disk_encryption     = true
  enabled_for_deployment          = false
  enabled_for_template_deployment = true
  purge_protection_enabled        = true
  soft_delete_retention_days      = 7

  # Network access
  network_acls {
    default_action = "Allow"
    bypass         = "AzureServices"
  }

  tags = var.tags
}

# Access policy for current user/service principal (for Terraform)
resource "azurerm_key_vault_access_policy" "terraform" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  key_permissions = [
    "Get",
    "List",
    "Create",
    "Delete",
    "Update",
    "Purge",
    "Recover"
  ]

  secret_permissions = [
    "Get",
    "List",
    "Set",
    "Delete",
    "Purge",
    "Recover"
  ]

  certificate_permissions = [
    "Get",
    "List",
    "Create",
    "Delete",
    "Update",
    "Purge",
    "Recover"
  ]
}

# Access policy for VM Managed Identity
resource "azurerm_key_vault_access_policy" "vm_identity" {
  count = var.vm_managed_identity_principal_id != null ? 1 : 0

  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = var.vm_managed_identity_principal_id

  secret_permissions = [
    "Get",
    "List"
  ]
}

# PostgreSQL admin password secret
resource "azurerm_key_vault_secret" "postgresql_admin_password" {
  name            = "postgresql-admin-password"
  value           = var.postgresql_admin_password
  key_vault_id    = azurerm_key_vault.main.id
  content_type    = "password"
  expiration_date = timeadd(timestamp(), "8760h") # 1 year from now

  depends_on = [azurerm_key_vault_access_policy.terraform]

  tags = var.tags
}

# Storage account access key secret
resource "azurerm_key_vault_secret" "storage_access_key" {
  count = var.storage_account_access_key != null ? 1 : 0

  name            = "storage-account-access-key"
  value           = var.storage_account_access_key
  key_vault_id    = azurerm_key_vault.main.id
  content_type    = "access-key"
  expiration_date = timeadd(timestamp(), "8760h") # 1 year from now

  depends_on = [azurerm_key_vault_access_policy.terraform]

  tags = var.tags
}

# Google OAuth client ID secret
resource "azurerm_key_vault_secret" "google_oauth_client_id" {
  count = var.google_oauth_client_id != null ? 1 : 0

  name            = "google-oauth-client-id"
  value           = var.google_oauth_client_id
  key_vault_id    = azurerm_key_vault.main.id
  content_type    = "oauth-client-id"
  expiration_date = timeadd(timestamp(), "8760h") # 1 year from now

  depends_on = [azurerm_key_vault_access_policy.terraform]

  tags = var.tags
}

# Google OAuth client secret
resource "azurerm_key_vault_secret" "google_oauth_client_secret" {
  count = var.google_oauth_client_secret != null ? 1 : 0

  name            = "google-oauth-client-secret"
  value           = var.google_oauth_client_secret
  key_vault_id    = azurerm_key_vault.main.id
  content_type    = "oauth-client-secret"
  expiration_date = timeadd(timestamp(), "8760h") # 1 year from now

  depends_on = [azurerm_key_vault_access_policy.terraform]

  tags = var.tags
}

# Facebook OAuth app ID secret
resource "azurerm_key_vault_secret" "facebook_oauth_app_id" {
  count = var.facebook_oauth_app_id != null ? 1 : 0

  name            = "facebook-oauth-app-id"
  value           = var.facebook_oauth_app_id
  key_vault_id    = azurerm_key_vault.main.id
  content_type    = "oauth-app-id"
  expiration_date = timeadd(timestamp(), "8760h") # 1 year from now

  depends_on = [azurerm_key_vault_access_policy.terraform]

  tags = var.tags
}

# Facebook OAuth app secret
resource "azurerm_key_vault_secret" "facebook_oauth_app_secret" {
  count = var.facebook_oauth_app_secret != null ? 1 : 0

  name            = "facebook-oauth-app-secret"
  value           = var.facebook_oauth_app_secret
  key_vault_id    = azurerm_key_vault.main.id
  content_type    = "oauth-app-secret"
  expiration_date = timeadd(timestamp(), "8760h") # 1 year from now

  depends_on = [azurerm_key_vault_access_policy.terraform]

  tags = var.tags
}

# SMTP server configuration secret
resource "azurerm_key_vault_secret" "smtp_server" {
  count = var.smtp_server != null ? 1 : 0

  name            = "smtp-server"
  value           = var.smtp_server
  key_vault_id    = azurerm_key_vault.main.id
  content_type    = "smtp-server"
  expiration_date = timeadd(timestamp(), "8760h") # 1 year from now

  depends_on = [azurerm_key_vault_access_policy.terraform]

  tags = var.tags
}

# SMTP username secret
resource "azurerm_key_vault_secret" "smtp_username" {
  count = var.smtp_username != null ? 1 : 0

  name            = "smtp-username"
  value           = var.smtp_username
  key_vault_id    = azurerm_key_vault.main.id
  content_type    = "smtp-username"
  expiration_date = timeadd(timestamp(), "8760h") # 1 year from now

  depends_on = [azurerm_key_vault_access_policy.terraform]

  tags = var.tags
}

# SMTP password secret
resource "azurerm_key_vault_secret" "smtp_password" {
  count = var.smtp_password != null ? 1 : 0

  name            = "smtp-password"
  value           = var.smtp_password
  key_vault_id    = azurerm_key_vault.main.id
  content_type    = "smtp-password"
  expiration_date = timeadd(timestamp(), "8760h") # 1 year from now

  depends_on = [azurerm_key_vault_access_policy.terraform]

  tags = var.tags
}

# Discourse admin API key (generated after Discourse setup)
resource "azurerm_key_vault_secret" "discourse_admin_api_key" {
  count = var.discourse_admin_api_key != null ? 1 : 0

  name            = "discourse-admin-api-key"
  value           = var.discourse_admin_api_key
  key_vault_id    = azurerm_key_vault.main.id
  content_type    = "api-key"
  expiration_date = timeadd(timestamp(), "8760h") # 1 year from now

  depends_on = [azurerm_key_vault_access_policy.terraform]

  tags = var.tags
}

resource "random_string" "kv_suffix" {
  length  = 4
  special = false
  upper   = false
}