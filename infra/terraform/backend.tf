terraform {
  backend "azurerm" {
    # Backend configuration is provided via CLI during init
    # This ensures state is stored in Azure Storage Account
    # Configuration values are passed via GitHub Secrets:
    # - resource_group_name: TF_STATE_RESOURCE_GROUP
    # - storage_account_name: TF_STATE_STORAGE_ACCOUNT  
    # - container_name: TF_STATE_CONTAINER
    # - key: terraform.tfstate
  }
}