# Deployment Guide

This document provides comprehensive step-by-step instructions for deploying the RobbedByAppleCare project to Azure, including infrastructure setup, domain configuration, and troubleshooting procedures.

## Overview

RobbedByAppleCare is deployed as a static website with embedded Discourse forum on Azure infrastructure. The deployment consists of:

- **Static Website**: Next.js app hosted on Azure Static Web Apps
- **Forum**: Discourse running in Docker on Azure VM
- **Database**: Azure Database for PostgreSQL Flexible Server
- **CDN**: Azure Front Door with custom domain and SSL
- **Storage**: Azure Blob Storage for forum uploads

The project uses Infrastructure as Code (Terraform) and GitOps with GitHub Actions for automated deployments.

## Deployment Workflows

### 1. Infrastructure Deployment Pipeline

**File:** `.github/workflows/terraform.yml`

**Triggers:**
- Pull requests affecting `infra/terraform/**` (creates plan)
- Tags starting with `v*` (applies changes)
- Pushes to main branch (drift detection)

**Jobs:**
- **Security Scan**: Runs Trivy, Checkov, and security validation
- **Terraform Plan**: Creates execution plan for pull requests
- **Terraform Apply**: Applies changes for release tags
- **Drift Detection**: Checks for infrastructure drift on main branch

### 2. Infrastructure Validation

**File:** `.github/workflows/terraform-validate.yml`

**Features:**
- Terraform formatting and validation
- TFLint static analysis
- Terraform docs generation
- Cost estimation with Infracost

### 3. Security Scanning

**File:** `.github/workflows/infrastructure-security.yml`

**Scans:**
- Terraform security with Checkov and TFSec
- Docker configuration security
- Azure Security Baseline compliance
- Daily scheduled scans

### 4. Release Management

**File:** `.github/workflows/release.yml`

**Process:**
1. Create GitHub release with changelog
2. Deploy infrastructure changes
3. Deploy web application
4. Run post-deployment verification
5. Update release status

## Prerequisites

### Required Accounts and Services

1. **Azure Subscription**: Active subscription with sufficient credits
2. **GitHub Account**: For repository and CI/CD
3. **Domain Name**: Purchase `robbedbyapplecare.com` from domain registrar
4. **OAuth Applications**: 
   - Google OAuth app for Discourse authentication
   - Facebook OAuth app for Discourse authentication

### Azure Setup (Step-by-Step)

#### 1. Create Service Principal

```bash
# Login to Azure CLI
az login

# Set subscription (if you have multiple)
az account set --subscription "Your Subscription Name"

# Create service principal with contributor role
az ad sp create-for-rbac --name "robbedbyapplecare-sp" \
  --role contributor \
  --scopes /subscriptions/$(az account show --query id -o tsv) \
  --sdk-auth

# Save the output JSON - you'll need it for GitHub secrets
```

#### 2. Create Terraform State Storage

```bash
# Create resource group for Terraform state
az group create --name "rg-terraform-state" --location "East US"

# Create storage account (name must be globally unique)
STORAGE_NAME="tfstate$(openssl rand -hex 4)"
az storage account create \
  --name $STORAGE_NAME \
  --resource-group "rg-terraform-state" \
  --location "East US" \
  --sku "Standard_LRS" \
  --encryption-services blob

# Create container for state files
az storage container create \
  --name "tfstate" \
  --account-name $STORAGE_NAME

# Get storage account key
az storage account keys list \
  --resource-group "rg-terraform-state" \
  --account-name $STORAGE_NAME \
  --query '[0].value' -o tsv

# Save storage account name and key for later use
echo "Storage Account: $STORAGE_NAME"
```

#### 3. Configure Domain DNS

Before deployment, configure your domain's DNS to point to Azure:

```bash
# Get Azure DNS name servers (after running terraform)
az network dns zone show \
  --resource-group "rg-robbedbyapplecare-prod" \
  --name "robbedbyapplecare.com" \
  --query "nameServers"

# Update your domain registrar's DNS settings to use Azure name servers
# Example name servers:
# ns1-01.azure-dns.com
# ns2-01.azure-dns.net
# ns3-01.azure-dns.org
# ns4-01.azure-dns.info
```

#### 4. Create OAuth Applications

**Google OAuth Setup:**
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create new project or select existing
3. Enable Google+ API
4. Go to Credentials → Create OAuth 2.0 Client ID
5. Set authorized redirect URI: `https://forum.robbedbyapplecare.com/auth/google_oauth2/callback`
6. Save Client ID and Client Secret

**Facebook OAuth Setup:**
1. Go to [Facebook Developers](https://developers.facebook.com/)
2. Create new app → Consumer type
3. Add Facebook Login product
4. Set Valid OAuth Redirect URI: `https://forum.robbedbyapplecare.com/auth/facebook/callback`
5. Save App ID and App Secret

### GitHub Secrets

Configure the following secrets in your GitHub repository:

#### Azure Authentication
```
AZURE_CREDENTIALS: {
  "clientId": "<service-principal-id>",
  "clientSecret": "<service-principal-secret>",
  "subscriptionId": "<azure-subscription-id>",
  "tenantId": "<azure-tenant-id>"
}
```

#### Terraform Backend
```
TF_STATE_RESOURCE_GROUP: "rg-terraform-state"
TF_STATE_STORAGE_ACCOUNT: "terraformstate<random>"
TF_STATE_CONTAINER: "tfstate"
```

#### Application Deployment
```
AZURE_STATIC_WEB_APPS_API_TOKEN: "<static-web-apps-token>"
```

#### Optional (for enhanced features)
```
INFRACOST_API_KEY: "<infracost-api-key>"
```

## Deployment Process

### Automated Deployment (Recommended)

1. **Development**:
   ```bash
   # Make infrastructure changes
   git checkout -b feature/infrastructure-update
   # Edit files in infra/terraform/
   git add infra/terraform/
   git commit -m "feat: add new security group rules"
   git push origin feature/infrastructure-update
   ```

2. **Pull Request**:
   - Create PR to main branch
   - GitHub Actions will run security scans and create Terraform plan
   - Review the plan in PR comments
   - Merge PR after approval

3. **Release**:
   ```bash
   # Create and push release tag
   git tag v1.2.3
   git push origin v1.2.3
   ```
   - GitHub Actions will automatically deploy infrastructure and web app
   - Monitor deployment progress in Actions tab

### Manual Deployment

For emergency deployments or local testing:

```bash
# Navigate to terraform directory
cd infra/terraform

# Set required environment variables
export TF_STATE_RESOURCE_GROUP="rg-terraform-state"
export TF_STATE_STORAGE_ACCOUNT="terraformstate<random>"
export TF_STATE_CONTAINER="tfstate"

# Run deployment script
./deploy.sh plan prod    # Create plan
./deploy.sh apply prod   # Apply changes
```

## Environment Management

### Production Environment

- **Trigger**: Release tags (`v*`)
- **Configuration**: `infra/terraform/environments/prod.tfvars`
- **Domain**: `robbedbyapplecare.com`
- **Protection**: Requires manual approval for deployments

### Development Environment

- **Trigger**: Manual workflow dispatch
- **Configuration**: `infra/terraform/environments/dev.tfvars`
- **Domain**: `dev.robbedbyapplecare.com`
- **Features**: Auto-shutdown enabled, relaxed security for testing

## Security Considerations

### Infrastructure Security

1. **Secrets Management**:
   - All secrets stored in Azure Key Vault
   - No hardcoded credentials in code
   - Managed identities for service authentication

2. **Network Security**:
   - Network Security Groups restrict access
   - Private endpoints for databases
   - WAF protection for web applications

3. **Compliance Scanning**:
   - Automated security scans on every change
   - Azure Security Baseline compliance checks
   - SARIF results uploaded to GitHub Security tab

### Deployment Security

1. **Branch Protection**:
   - Require PR reviews for main branch
   - Status checks must pass before merge
   - No direct pushes to main branch

2. **Environment Protection**:
   - Production deployments require manual approval
   - Deployment logs are auditable
   - Rollback procedures documented

## Monitoring and Alerting

### Deployment Monitoring

- **GitHub Actions**: Monitor workflow status
- **Azure Portal**: Check resource deployment status
- **Terraform State**: Track configuration drift

### Application Monitoring

- **Lighthouse CI**: Performance monitoring
- **Security Headers**: Automated security validation
- **SSL Certificates**: Expiration monitoring

## Troubleshooting Guide

### Common Deployment Issues

#### 1. Terraform State Lock Issues

**Problem**: Terraform state is locked from previous failed deployment
```
Error: Error acquiring the state lock
```

**Solution**:
```bash
# Check for running GitHub Actions first
# If no active deployments, force unlock
cd infra/terraform
terraform force-unlock <lock-id>

# If you don't have the lock ID, check Azure Storage
az storage blob list \
  --container-name tfstate \
  --account-name <storage-account> \
  --query "[?contains(name, '.tflock')]"
```

#### 2. Domain and Certificate Issues

**Problem**: SSL certificate not provisioning or domain not resolving

**Diagnosis**:
```bash
# Check DNS propagation
nslookup robbedbyapplecare.com
dig robbedbyapplecare.com

# Check certificate status in Azure
az network front-door check-custom-domain \
  --resource-group rg-robbedbyapplecare-prod \
  --front-door-name fd-robbedbyapplecare \
  --host-name www.robbedbyapplecare.com
```

**Solutions**:
- Verify DNS name servers are correctly set at domain registrar
- Wait 24-48 hours for DNS propagation
- Check that CNAME records are properly configured
- Ensure domain validation is completed

#### 3. Static Web App Deployment Failures

**Problem**: GitHub Actions fails to deploy to Azure Static Web Apps

**Common Causes**:
- Invalid deployment token
- Build configuration issues
- Missing environment variables

**Solutions**:
```bash
# Regenerate deployment token
az staticwebapp secrets list \
  --name swa-robbedbyapplecare \
  --resource-group rg-robbedbyapplecare-prod

# Update GitHub secret with new token
# Check build logs in GitHub Actions for specific errors
```

#### 4. Discourse VM Connection Issues

**Problem**: Cannot SSH to Discourse VM or Discourse not responding

**Diagnosis**:
```bash
# Check VM status
az vm get-instance-view \
  --resource-group rg-robbedbyapplecare-prod \
  --name vm-discourse \
  --query "instanceView.statuses"

# Check NSG rules
az network nsg rule list \
  --resource-group rg-robbedbyapplecare-prod \
  --nsg-name nsg-discourse \
  --query "[].{Name:name,Priority:priority,Access:access,Direction:direction}"

# Test connectivity
nc -zv <vm-public-ip> 22
nc -zv <vm-public-ip> 80
```

**Solutions**:
- Verify NSG allows SSH (port 22) from your IP
- Check if VM is running and not stopped
- Restart VM if necessary:
```bash
az vm restart \
  --resource-group rg-robbedbyapplecare-prod \
  --name vm-discourse
```

#### 5. Database Connection Issues

**Problem**: Discourse cannot connect to PostgreSQL database

**Diagnosis**:
```bash
# Check database status
az postgres flexible-server show \
  --resource-group rg-robbedbyapplecare-prod \
  --name psql-robbedbyapplecare

# Check firewall rules
az postgres flexible-server firewall-rule list \
  --resource-group rg-robbedbyapplecare-prod \
  --name psql-robbedbyapplecare

# Test connection from VM
ssh discourse-admin@<vm-ip>
psql -h <db-host> -U discourse_user -d discourse_production
```

**Solutions**:
- Verify database firewall allows VM subnet
- Check database credentials in Key Vault
- Restart Discourse container:
```bash
ssh discourse-admin@<vm-ip>
cd /var/discourse
sudo ./launcher restart app
```

#### 6. Blob Storage Access Issues

**Problem**: Discourse cannot upload files to Azure Blob Storage

**Diagnosis**:
```bash
# Check storage account access
az storage account show \
  --resource-group rg-robbedbyapplecare-prod \
  --name <storage-account>

# Test blob access from VM
ssh discourse-admin@<vm-ip>
curl -X PUT -H "x-ms-blob-type: BlockBlob" \
  "https://<storage>.blob.core.windows.net/discourse-uploads/test.txt?<sas-token>"
```

**Solutions**:
- Verify storage account keys in Key Vault
- Check container permissions and SAS token
- Update Discourse configuration with correct credentials

#### 7. OAuth Authentication Issues

**Problem**: Users cannot login with Google/Facebook

**Common Issues**:
- Incorrect redirect URIs
- Invalid client credentials
- OAuth app not approved/published

**Solutions**:
1. Verify redirect URIs in OAuth apps:
   - Google: `https://forum.robbedbyapplecare.com/auth/google_oauth2/callback`
   - Facebook: `https://forum.robbedbyapplecare.com/auth/facebook/callback`

2. Check OAuth credentials in Discourse admin:
   ```
   Admin → Settings → Login → Google/Facebook OAuth settings
   ```

3. Test OAuth flow manually and check browser developer tools for errors

### Recovery Procedures

#### Infrastructure Rollback

```bash
# 1. Identify last working version
git log --oneline --grep="deploy"

# 2. Checkout previous working tag
git checkout v1.2.3

# 3. Deploy previous configuration
cd infra/terraform
./deploy.sh apply prod

# 4. Verify rollback success
curl -I https://www.robbedbyapplecare.com
```

#### Database Recovery

```bash
# 1. Stop Discourse to prevent data corruption
ssh discourse-admin@<vm-ip>
cd /var/discourse
sudo ./launcher stop app

# 2. Restore from backup (see RUNBOOK.md for detailed steps)
az storage blob download \
  --container-name backups \
  --name discourse-backup-YYYY-MM-DD.tar.gz \
  --file discourse-backup.tar.gz \
  --account-name <storage-account>

# 3. Restore database
sudo -u postgres psql -c "DROP DATABASE discourse_production;"
sudo -u postgres psql -c "CREATE DATABASE discourse_production;"
sudo -u postgres pg_restore -d discourse_production discourse-backup.sql

# 4. Restart Discourse
sudo ./launcher start app
```

#### Emergency Contact Information

- **Azure Support**: Use Azure Support Portal for infrastructure issues
- **Domain Registrar**: Contact support for DNS/domain issues  
- **GitHub Support**: For CI/CD pipeline issues
- **Project Repository**: Create GitHub issue for application bugs

### Support Contacts

- **Infrastructure Issues**: Check GitHub Issues
- **Azure Support**: Use Azure Support Portal
- **Emergency**: Follow incident response procedures

## Best Practices

### Development Workflow

1. Always create feature branches for changes
2. Test changes in development environment first
3. Use descriptive commit messages
4. Include security considerations in PR reviews

### Infrastructure Changes

1. Use Terraform modules for reusable components
2. Document all variable changes
3. Test with `terraform plan` before applying
4. Monitor resource costs with Infracost

### Security

1. Regularly update Terraform providers
2. Review security scan results
3. Rotate secrets according to schedule
4. Monitor for configuration drift

## Maintenance

### Regular Tasks

- **Weekly**: Review security scan results
- **Monthly**: Update Terraform providers and modules
- **Quarterly**: Review and rotate secrets
- **Annually**: Review and update compliance policies

### Updates

- **Terraform**: Update version in workflows and scripts
- **GitHub Actions**: Keep actions up to date
- **Azure Providers**: Regular updates for new features and security fixes