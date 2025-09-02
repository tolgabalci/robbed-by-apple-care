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

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
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