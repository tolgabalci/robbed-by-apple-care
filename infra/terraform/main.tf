terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }

  # Use service principal authentication for GitHub Actions
  use_cli = false
  use_msi = false
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location

  tags = var.tags
}

# Modules
module "static_site" {
  source = "./modules/static-site"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  domain_name         = var.domain_name
  tags                = var.tags
}

module "discourse" {
  source = "./modules/discourse"

  resource_group_name       = azurerm_resource_group.main.name
  location                  = azurerm_resource_group.main.location
  domain_name               = var.domain_name
  admin_username            = var.admin_username
  ssh_public_key            = var.ssh_public_key
  ssh_source_address_prefix = var.ssh_source_address_prefix
  postgresql_admin_password = var.postgresql_admin_password
  tags                      = var.tags
}

module "security" {
  source = "./modules/security"

  resource_group_name              = azurerm_resource_group.main.name
  location                         = azurerm_resource_group.main.location
  postgresql_admin_password        = var.postgresql_admin_password
  vm_managed_identity_principal_id = module.discourse.vm_managed_identity_principal_id
  storage_account_access_key       = module.discourse.storage_account_primary_access_key
  tags                             = var.tags
}

module "networking" {
  source = "./modules/networking"

  resource_group_name     = azurerm_resource_group.main.name
  location                = azurerm_resource_group.main.location
  domain_name             = var.domain_name
  static_web_app_hostname = module.static_site.static_web_app_hostname
  discourse_vm_hostname   = module.discourse.vm_hostname
  tags                    = var.tags
}