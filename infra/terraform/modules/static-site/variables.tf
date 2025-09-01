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

variable "front_door_profile_id" {
  description = "Front Door profile ID for integration"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}