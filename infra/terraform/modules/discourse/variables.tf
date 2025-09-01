variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "domain_name" {
  description = "Primary domain name"
  type        = string
}

variable "admin_username" {
  description = "Admin username for VM"
  type        = string
  default     = "discourse"
}

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
}

variable "ssh_source_address_prefix" {
  description = "Source address prefix for SSH access"
  type        = string
  default     = "*"
}

variable "postgresql_admin_password" {
  description = "PostgreSQL administrator password"
  type        = string
  sensitive   = true
}

variable "key_vault_id" {
  description = "Key Vault ID for storing secrets"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}