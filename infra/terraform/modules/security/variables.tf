variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "vm_managed_identity_principal_id" {
  description = "Principal ID of the VM managed identity"
  type        = string
  default     = null
}

variable "postgresql_admin_password" {
  description = "PostgreSQL administrator password"
  type        = string
  sensitive   = true
}

variable "storage_account_access_key" {
  description = "Storage account access key"
  type        = string
  sensitive   = true
  default     = null
}

variable "google_oauth_client_id" {
  description = "Google OAuth client ID"
  type        = string
  sensitive   = true
  default     = null
}

variable "google_oauth_client_secret" {
  description = "Google OAuth client secret"
  type        = string
  sensitive   = true
  default     = null
}

variable "facebook_oauth_app_id" {
  description = "Facebook OAuth app ID"
  type        = string
  sensitive   = true
  default     = null
}

variable "facebook_oauth_app_secret" {
  description = "Facebook OAuth app secret"
  type        = string
  sensitive   = true
  default     = null
}

variable "smtp_server" {
  description = "SMTP server hostname"
  type        = string
  default     = null
}

variable "smtp_username" {
  description = "SMTP username"
  type        = string
  sensitive   = true
  default     = null
}

variable "smtp_password" {
  description = "SMTP password"
  type        = string
  sensitive   = true
  default     = null
}

variable "discourse_admin_api_key" {
  description = "Discourse admin API key (set after initial setup)"
  type        = string
  sensitive   = true
  default     = null
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}