#!/bin/bash

# Terraform Deployment Script for RobbedByAppleCare Infrastructure
# Usage: ./deploy.sh [plan|apply|destroy] [environment]

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_VERSION="1.6.0"
DEFAULT_ENVIRONMENT="prod"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
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

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if Terraform is installed
    if ! command -v terraform &> /dev/null; then
        log_error "Terraform is not installed. Please install Terraform $TERRAFORM_VERSION"
        exit 1
    fi
    
    # Check Terraform version
    local tf_version=$(terraform version -json | jq -r '.terraform_version')
    if [[ "$tf_version" != "$TERRAFORM_VERSION" ]]; then
        log_warning "Terraform version $tf_version detected, expected $TERRAFORM_VERSION"
    fi
    
    # Check if Azure CLI is installed and authenticated
    if ! command -v az &> /dev/null; then
        log_error "Azure CLI is not installed"
        exit 1
    fi
    
    if ! az account show &> /dev/null; then
        log_error "Not authenticated with Azure CLI. Run 'az login'"
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

init_terraform() {
    local environment=$1
    log_info "Initializing Terraform for environment: $environment"
    
    # Check if backend configuration exists
    if [[ -z "${TF_STATE_RESOURCE_GROUP:-}" ]] || \
       [[ -z "${TF_STATE_STORAGE_ACCOUNT:-}" ]] || \
       [[ -z "${TF_STATE_CONTAINER:-}" ]]; then
        log_error "Backend configuration missing. Set environment variables:"
        log_error "  TF_STATE_RESOURCE_GROUP"
        log_error "  TF_STATE_STORAGE_ACCOUNT"
        log_error "  TF_STATE_CONTAINER"
        exit 1
    fi
    
    terraform init \
        -backend-config="resource_group_name=$TF_STATE_RESOURCE_GROUP" \
        -backend-config="storage_account_name=$TF_STATE_STORAGE_ACCOUNT" \
        -backend-config="container_name=$TF_STATE_CONTAINER" \
        -backend-config="key=${environment}-terraform.tfstate"
    
    log_success "Terraform initialized"
}

validate_terraform() {
    log_info "Validating Terraform configuration..."
    
    terraform fmt -check -recursive
    terraform validate
    
    log_success "Terraform validation passed"
}

plan_terraform() {
    local environment=$1
    log_info "Creating Terraform plan for environment: $environment"
    
    local var_file="environments/${environment}.tfvars"
    if [[ ! -f "$var_file" ]]; then
        log_error "Environment file not found: $var_file"
        exit 1
    fi
    
    terraform plan \
        -var-file="$var_file" \
        -out="${environment}.tfplan" \
        -detailed-exitcode
    
    local exit_code=$?
    case $exit_code in
        0)
            log_success "No changes required"
            ;;
        1)
            log_error "Terraform plan failed"
            exit 1
            ;;
        2)
            log_success "Plan created with changes"
            ;;
    esac
    
    return $exit_code
}

apply_terraform() {
    local environment=$1
    log_info "Applying Terraform plan for environment: $environment"
    
    local plan_file="${environment}.tfplan"
    if [[ ! -f "$plan_file" ]]; then
        log_error "Plan file not found: $plan_file. Run plan first."
        exit 1
    fi
    
    # Confirmation prompt for production
    if [[ "$environment" == "prod" ]]; then
        log_warning "You are about to apply changes to PRODUCTION environment"
        read -p "Are you sure you want to continue? (yes/no): " confirm
        if [[ "$confirm" != "yes" ]]; then
            log_info "Deployment cancelled"
            exit 0
        fi
    fi
    
    terraform apply "$plan_file"
    
    log_success "Terraform apply completed"
    
    # Show outputs
    log_info "Terraform outputs:"
    terraform output
}

destroy_terraform() {
    local environment=$1
    log_warning "Destroying infrastructure for environment: $environment"
    
    local var_file="environments/${environment}.tfvars"
    if [[ ! -f "$var_file" ]]; then
        log_error "Environment file not found: $var_file"
        exit 1
    fi
    
    # Multiple confirmation prompts for safety
    log_error "WARNING: This will DESTROY all infrastructure in $environment environment"
    read -p "Type 'destroy' to confirm: " confirm1
    if [[ "$confirm1" != "destroy" ]]; then
        log_info "Destruction cancelled"
        exit 0
    fi
    
    read -p "Type the environment name '$environment' to confirm: " confirm2
    if [[ "$confirm2" != "$environment" ]]; then
        log_info "Destruction cancelled"
        exit 0
    fi
    
    terraform destroy \
        -var-file="$var_file" \
        -auto-approve
    
    log_success "Infrastructure destroyed"
}

show_usage() {
    echo "Usage: $0 [command] [environment]"
    echo ""
    echo "Commands:"
    echo "  plan     - Create execution plan"
    echo "  apply    - Apply the execution plan"
    echo "  destroy  - Destroy infrastructure"
    echo ""
    echo "Environments:"
    echo "  dev      - Development environment"
    echo "  prod     - Production environment (default)"
    echo ""
    echo "Examples:"
    echo "  $0 plan dev"
    echo "  $0 apply prod"
    echo "  $0 destroy dev"
}

# Main execution
main() {
    cd "$SCRIPT_DIR"
    
    local command=${1:-}
    local environment=${2:-$DEFAULT_ENVIRONMENT}
    
    if [[ -z "$command" ]]; then
        show_usage
        exit 1
    fi
    
    check_prerequisites
    init_terraform "$environment"
    validate_terraform
    
    case "$command" in
        plan)
            plan_terraform "$environment"
            ;;
        apply)
            apply_terraform "$environment"
            ;;
        destroy)
            destroy_terraform "$environment"
            ;;
        *)
            log_error "Unknown command: $command"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"