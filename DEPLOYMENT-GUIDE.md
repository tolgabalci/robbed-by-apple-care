# RobbedByAppleCare Deployment Guide

This guide will walk you through deploying the RobbedByAppleCare website and forum to Azure.

## Prerequisites

- Azure CLI installed and configured
- GitHub repository with admin access
- Azure subscription with the "RobbedByAppleCare" resource group

## Step 1: Run Azure Setup Script

Run the setup script to create all necessary Azure resources and get the GitHub secrets:

```bash
./setup-azure-deployment.sh
```

This script will:
- Create a service principal for GitHub Actions
- Set up Terraform state storage
- Create Azure Static Web App
- Output all the GitHub secrets you need

## Step 2: Add GitHub Secrets

Go to your GitHub repository → Settings → Secrets and variables → Actions

Add these 5 secrets (values will be provided by the setup script):

1. `AZURE_CREDENTIALS` - Service principal credentials for Azure access
2. `TF_STATE_RESOURCE_GROUP` - Resource group for Terraform state (RobbedByAppleCare)
3. `TF_STATE_STORAGE_ACCOUNT` - Storage account name for Terraform state
4. `TF_STATE_CONTAINER` - Container name for state files (tfstate)
5. `AZURE_STATIC_WEB_APPS_API_TOKEN` - Deployment token for Static Web Apps

## Step 3: Deploy via GitHub Actions

### Option A: Automatic Deployment (Recommended)

Create and push a release tag to trigger the full deployment:

```bash
git add .
git commit -m "Configure Azure deployment"
git push origin main

# Create release tag
git tag v1.0.0
git push origin v1.0.0
```

### Option B: Manual Deployment

If you prefer to deploy manually:

```bash
cd infra/terraform
./deploy.sh plan prod
./deploy.sh apply prod
```

## Step 4: Monitor Deployment

1. Go to your GitHub repository → Actions
2. Watch the "Release and Deploy" workflow
3. The deployment takes about 10-15 minutes

The workflow will:
- Deploy Azure infrastructure (Front Door, VM, Database, etc.)
- Deploy the web application to Static Web Apps
- Configure Discourse forum on the VM
- Set up SSL certificates and domain routing
- Run verification tests

## Step 5: Verify Deployment

After deployment completes, you should have:

- **Main Website**: Available at the Azure Static Web Apps URL
- **Forum**: Running at the VM's public IP (will be configured for custom domain)
- **Comments**: Working on the main site (embedded Discourse)

## Post-Deployment Configuration

### Custom Domain Setup (Optional)

If you want to use your own domain (robbedbyapplecare.com):

1. Update DNS records to point to Azure Front Door
2. Configure custom domain in Azure Front Door
3. Update the domain configuration in Terraform

### OAuth Setup

Configure OAuth providers for the forum:

1. **Google OAuth**:
   - Go to Google Cloud Console
   - Create OAuth 2.0 credentials
   - Add redirect URI: `https://forum.robbedbyapplecare.com/auth/google_oauth2/callback`

2. **Facebook OAuth**:
   - Go to Facebook Developers
   - Create Facebook App
   - Add redirect URI: `https://forum.robbedbyapplecare.com/auth/facebook/callback`

## Troubleshooting

### Common Issues

1. **GitHub Secrets Missing**: Ensure all 5 secrets are added correctly
2. **Azure Permissions**: Verify the service principal has contributor access
3. **Resource Group**: Confirm "RobbedByAppleCare" resource group exists
4. **Terraform State**: Check that the storage account was created successfully

### Getting Help

- Check GitHub Actions logs for detailed error messages
- Review Azure Portal for resource status
- Check the deployment workflow summary for specific failures

## Maintenance

### Updates

To update the deployment:
1. Make changes to code
2. Create a new release tag (e.g., v1.0.1)
3. Push the tag to trigger redeployment

### Monitoring

- GitHub Actions provides deployment status
- Azure Portal shows resource health
- Discourse admin panel for forum management

## Security Notes

- All secrets are stored securely in GitHub Secrets
- Azure resources use managed identities where possible
- SSL certificates are automatically managed
- WAF protection is enabled via Azure Front Door

## Support

For issues with:
- **Infrastructure**: Check Terraform logs in GitHub Actions
- **Web App**: Check Static Web Apps deployment logs
- **Forum**: SSH into the VM and check Docker logs
- **DNS/SSL**: Check Azure Front Door configuration

---

**Next Steps After Deployment:**
1. Test the website and forum functionality
2. Configure OAuth providers
3. Set up custom domain (if desired)
4. Add content and customize the forum settings