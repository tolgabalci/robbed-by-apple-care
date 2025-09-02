#!/bin/bash

# Azure Deployment Setup Script for RobbedByAppleCare
# Run this script locally where you have Azure CLI installed

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Configuration
RESOURCE_GROUP="RobbedByAppleCare"
LOCATION="East US"
SERVICE_PRINCIPAL_NAME="github-actions-robbedbyapplecare"

log_info "Starting Azure deployment setup for RobbedByAppleCare..."

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    log_error "Azure CLI is not installed. Please install it first:"
    log_error "https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

# Check if logged in
if ! az account show &> /dev/null; then
    log_error "Not logged in to Azure. Please run 'az login' first"
    exit 1
fi

# Get subscription ID
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
log_info "Using subscription: $SUBSCRIPTION_ID"

# Verify resource group exists
if ! az group show --name "$RESOURCE_GROUP" &> /dev/null; then
    log_error "Resource group '$RESOURCE_GROUP' not found"
    exit 1
fi

log_success "Resource group '$RESOURCE_GROUP' found"

# Step 1: Create Service Principal
log_info "Creating service principal for GitHub Actions..."

# Check if service principal already exists
if az ad sp list --display-name "$SERVICE_PRINCIPAL_NAME" --query "[0].appId" -o tsv | grep -q .; then
    log_warning "Service principal '$SERVICE_PRINCIPAL_NAME' already exists"
    APP_ID=$(az ad sp list --display-name "$SERVICE_PRINCIPAL_NAME" --query "[0].appId" -o tsv)
    log_info "Using existing service principal: $APP_ID"
    
    # Reset credentials
    AZURE_CREDENTIALS=$(az ad sp create-for-rbac --name "$SERVICE_PRINCIPAL_NAME" \
        --role contributor \
        --scopes "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP" \
        --sdk-auth)
else
    AZURE_CREDENTIALS=$(az ad sp create-for-rbac --name "$SERVICE_PRINCIPAL_NAME" \
        --role contributor \
        --scopes "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP" \
        --sdk-auth)
fi

log_success "Service principal created/updated"

# Step 2: Create Terraform State Storage
log_info "Creating Terraform state storage..."

STORAGE_NAME="tfstaterobbed$(date +%s)"

az storage account create \
    --name "$STORAGE_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --location "$LOCATION" \
    --sku "Standard_LRS" \
    --kind "StorageV2" \
    --allow-blob-public-access false

log_success "Storage account '$STORAGE_NAME' created"

# Create container
az storage container create \
    --name "tfstate" \
    --account-name "$STORAGE_NAME" \
    --auth-mode login

log_success "Terraform state container created"

# Step 3: Create Static Web App (optional - can be done via Terraform)
log_info "Creating Azure Static Web App..."

STATIC_WEB_APP_NAME="robbedbyapplecare-web"

# Check if static web app already exists
if az staticwebapp show --name "$STATIC_WEB_APP_NAME" --resource-group "$RESOURCE_GROUP" &> /dev/null; then
    log_warning "Static Web App '$STATIC_WEB_APP_NAME' already exists"
else
    az staticwebapp create \
        --name "$STATIC_WEB_APP_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --location "East US 2" \
        --sku "Free"
    
    log_success "Static Web App '$STATIC_WEB_APP_NAME' created"
fi

# Get deployment token
STATIC_WEB_APP_TOKEN=$(az staticwebapp secrets list \
    --name "$STATIC_WEB_APP_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --query "properties.apiKey" -o tsv)

log_success "Retrieved Static Web App deployment token"

# Output GitHub Secrets
echo ""
log_info "=== GITHUB SECRETS TO ADD ==="
echo ""
echo "Go to your GitHub repository → Settings → Secrets and variables → Actions"
echo "Add these secrets:"
echo ""
echo "1. AZURE_CREDENTIALS:"
echo "$AZURE_CREDENTIALS"
echo ""
echo "2. TF_STATE_RESOURCE_GROUP:"
echo "$RESOURCE_GROUP"
echo ""
echo "3. TF_STATE_STORAGE_ACCOUNT:"
echo "$STORAGE_NAME"
echo ""
echo "4. TF_STATE_CONTAINER:"
echo "tfstate"
echo ""
echo "5. AZURE_STATIC_WEB_APPS_API_TOKEN:"
echo "$STATIC_WEB_APP_TOKEN"
echo ""

# Save to file for reference
cat > azure-secrets.txt << EOF
AZURE_CREDENTIALS:
$AZURE_CREDENTIALS

TF_STATE_RESOURCE_GROUP:
$RESOURCE_GROUP

TF_STATE_STORAGE_ACCOUNT:
$STORAGE_NAME

TF_STATE_CONTAINER:
tfstate

AZURE_STATIC_WEB_APPS_API_TOKEN:
$STATIC_WEB_APP_TOKEN
EOF

log_success "Secrets saved to azure-secrets.txt"
log_info "Setup complete! Add the secrets to GitHub and create a release tag to deploy."