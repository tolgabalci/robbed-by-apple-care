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

variable "static_web_app_hostname" {
  description = "Hostname of the Static Web App"
  type        = string
}

variable "discourse_vm_hostname" {
  description = "Hostname of the Discourse VM"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}