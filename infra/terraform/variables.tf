variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "RobbedByAppleCare"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "East US"
}

variable "domain_name" {
  description = "Primary domain name"
  type        = string
  default     = "robbedbyapplecare.com"
}

variable "admin_username" {
  description = "Admin username for VM"
  type        = string
  default     = "azureuser"
}



variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
  sensitive   = true
}

variable "postgresql_admin_password" {
  description = "Admin password for PostgreSQL"
  type        = string
  sensitive   = true
}

variable "ssh_source_address_prefix" {
  description = "Source address prefix for SSH access"
  type        = string
  default     = "*"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "prod"
    Project     = "RobbedByAppleCare"
    ManagedBy   = "Terraform"
  }
}