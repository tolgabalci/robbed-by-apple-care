# RobbedByAppleCare Infrastructure

This directory contains the Terraform infrastructure as code for the RobbedByAppleCare project.

## Architecture Overview

The infrastructure consists of:
- Azure Front Door with WAF for global load balancing and security
- Azure Static Web Apps for hosting the Next.js application
- Azure Virtual Machine running Discourse in Docker
- Azure Database for PostgreSQL for Discourse data
- Azure Blob Storage for file uploads
- Azure Key Vault for secret management
- Azure DNS for domain management

## Prerequisites

1. Azure CLI installed and authenticated
2. Terraform >= 1.6.0 installed
3. Required Azure permissions for resource creation
4. Backend storage account for Terraform state

## Backend Configuration

The Terraform state is stored in Azure Storage. Configure the following secrets in GitHub:

- `TF_STATE_RESOURCE_GROUP`: Resource group containing the storage account
- `TF_STATE_STORAGE_ACCOUNT`: Storage account name for Terraform state
- `TF_STATE_CONTAINER`: Container name for state files

## Deployment

### Via GitHub Actions (Recommended)

1. **Pull Request**: Creates a Terraform plan and posts it as a comment
2. **Release Tag**: Applies the Terraform configuration to production

### Manual Deployment

```bash
# Initialize Terraform
terraform init \
  -backend-config="resource_group_name=<state-rg>" \
  -backend-config="storage_account_name=<state-storage>" \
  -backend-config="container_name=<state-container>" \
  -backend-config="key=terraform.tfstate"

# Plan changes
terraform plan -out=tfplan

# Apply changes
terraform apply tfplan
```

## Security

- All resources use managed identities where possible
- Secrets are stored in Azure Key Vault
- Network security groups restrict access
- Encryption at rest is enabled for all data stores
- WAF protects against common web attacks

## Monitoring

- Security scanning via Checkov, TFSec, and Trivy
- Cost estimation via Infracost
- Drift detection on main branch pushes
- Compliance checking against Azure Security Baseline

## Modules

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | ~> 3.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_discourse"></a> [discourse](#module\_discourse) | ./modules/discourse | n/a |
| <a name="module_networking"></a> [networking](#module\_networking) | ./modules/networking | n/a |
| <a name="module_security"></a> [security](#module\_security) | ./modules/security | n/a |
| <a name="module_static_site"></a> [static\_site](#module\_static\_site) | ./modules/static-site | n/a |

## Resources

| Name | Type |
|------|------|
| [azurerm_resource_group.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_admin_username"></a> [admin\_username](#input\_admin\_username) | Admin username for VM | `string` | `"azureuser"` | no |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | Primary domain name | `string` | `"robbedbyapplecare.com"` | no |
| <a name="input_location"></a> [location](#input\_location) | Azure region for resources | `string` | `"East US"` | no |
| <a name="input_postgresql_admin_password"></a> [postgresql\_admin\_password](#input\_postgresql\_admin\_password) | Admin password for PostgreSQL | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Name of the resource group | `string` | `"RobbedByAppleCare"` | no |
| <a name="input_ssh_public_key"></a> [ssh\_public\_key](#input\_ssh\_public\_key) | SSH public key for VM access | `string` | n/a | yes |
| <a name="input_ssh_source_address_prefix"></a> [ssh\_source\_address\_prefix](#input\_ssh\_source\_address\_prefix) | Source address prefix for SSH access | `string` | `"*"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to all resources | `map(string)` | <pre>{<br/>  "Environment": "prod",<br/>  "ManagedBy": "Terraform",<br/>  "Project": "RobbedByAppleCare"<br/>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_discourse_vm_ip"></a> [discourse\_vm\_ip](#output\_discourse\_vm\_ip) | Public IP of the Discourse VM |
| <a name="output_dns_nameservers"></a> [dns\_nameservers](#output\_dns\_nameservers) | DNS nameservers for domain configuration |
| <a name="output_forum_endpoint_hostname"></a> [forum\_endpoint\_hostname](#output\_forum\_endpoint\_hostname) | Forum Front Door endpoint hostname |
| <a name="output_key_vault_uri"></a> [key\_vault\_uri](#output\_key\_vault\_uri) | URI of the Key Vault |
| <a name="output_resource_group_name"></a> [resource\_group\_name](#output\_resource\_group\_name) | Name of the resource group |
| <a name="output_static_web_app_hostname"></a> [static\_web\_app\_hostname](#output\_static\_web\_app\_hostname) | Static Web App hostname |
| <a name="output_static_web_app_url"></a> [static\_web\_app\_url](#output\_static\_web\_app\_url) | URL of the static web app |
| <a name="output_www_endpoint_hostname"></a> [www\_endpoint\_hostname](#output\_www\_endpoint\_hostname) | WWW Front Door endpoint hostname |
<!-- END_TF_DOCS -->

## Troubleshooting

### Common Issues

1. **State Lock**: If Terraform state is locked, check for running deployments
2. **Permission Errors**: Ensure service principal has required permissions
3. **Resource Conflicts**: Check for existing resources with same names

### Support

For infrastructure issues, check:
1. GitHub Actions logs for deployment failures
2. Azure Portal for resource status
3. Terraform state for configuration drift# Trigger workflows - Wed Sep  3 22:22:49 EDT 2025
# Trigger workflows again - Wed Sep  3 22:32:20 EDT 2025
