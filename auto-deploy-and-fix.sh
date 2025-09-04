#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}"
}

print_success() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] ✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] ⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ❌ $1${NC}"
}

# Function to check GitHub Actions status
check_github_actions() {
    print_status "Checking GitHub Actions status..."
    
    # Get the latest runs
    local runs=$(gh run list --limit 10 --json status,conclusion,workflowName,createdAt,url,databaseId)
    
    # Parse and display results
    echo "$runs" | jq -r '.[] | select(.createdAt > (now - 300 | strftime("%Y-%m-%dT%H:%M:%SZ"))) | "\(.workflowName): \(.status) - \(.conclusion // "running")"'
    
    # Count failures in recent runs (last 5 minutes)
    local failures=$(echo "$runs" | jq '[.[] | select(.createdAt > (now - 300 | strftime("%Y-%m-%dT%H:%M:%SZ")) and .conclusion == "failure")] | length')
    
    return $failures
}

# Function to get detailed error information
get_error_details() {
    print_status "Getting detailed error information..."
    
    local failed_runs=$(gh run list --limit 5 --json status,conclusion,workflowName,databaseId | jq -r '.[] | select(.conclusion == "failure") | .databaseId')
    
    for run_id in $failed_runs; do
        print_status "Analyzing run $run_id..."
        gh run view $run_id --log | grep -E "(error|Error|ERROR|failed|Failed|FAILED)" | head -10 || true
    done
}

# Function to fix SARIF upload permissions
fix_sarif_permissions() {
    print_status "Fixing SARIF upload permissions..."
    
    # Check if we need to update workflow permissions
    local workflow_file=".github/workflows/terraform.yml"
    
    if ! grep -q "security-events: write" "$workflow_file"; then
        print_status "Adding security-events permission to workflow..."
        
        # Create a backup
        cp "$workflow_file" "$workflow_file.backup"
        
        # Add permissions section if it doesn't exist
        if ! grep -q "permissions:" "$workflow_file"; then
            # Add permissions after the name
            sed -i '/^name:/a\\npermissions:\n  contents: read\n  security-events: write\n  actions: read' "$workflow_file"
        else
            # Add security-events permission to existing permissions
            sed -i '/permissions:/a\  security-events: write' "$workflow_file"
        fi
        
        print_success "Added security-events permission"
        return 0
    else
        print_success "SARIF permissions already configured"
        return 1
    fi
}

# Function to fix missing Checkov results
fix_checkov_results() {
    print_status "Fixing Checkov configuration..."
    
    local workflow_file=".github/workflows/terraform.yml"
    
    # Check if Checkov step exists but results file is missing
    if grep -q "checkov-results.sarif" "$workflow_file"; then
        print_status "Adding Checkov scan step..."
        
        # Find the line with "Upload Checkov scan results" and add the scan step before it
        local line_num=$(grep -n "Upload Checkov scan results" "$workflow_file" | cut -d: -f1)
        
        if [ ! -z "$line_num" ]; then
            # Insert Checkov scan step before upload
            sed -i "${line_num}i\\      - name: Run Checkov scan\\n        run: |\\n          docker run --rm -v \$(pwd):/tf bridgecrew/checkov:latest -f /tf/infra/terraform --framework terraform --output sarif --output-file-path /tf/checkov-results.sarif || true\\n" "$workflow_file"
            
            print_success "Added Checkov scan step"
            return 0
        fi
    fi
    
    return 1
}

# Function to commit and push changes
commit_and_push() {
    local message="$1"
    
    print_status "Committing and pushing changes: $message"
    
    git add .
    if git diff --staged --quiet; then
        print_warning "No changes to commit"
        return 1
    fi
    
    git commit -m "$message"
    git push origin main
    
    print_success "Changes pushed to GitHub"
    return 0
}

# Function to wait for workflows to complete
wait_for_workflows() {
    local timeout=${1:-300}  # 5 minutes default
    local start_time=$(date +%s)
    
    print_status "Waiting for workflows to complete (timeout: ${timeout}s)..."
    
    while true; do
        local current_time=$(date +%s)
        local elapsed=$((current_time - start_time))
        
        if [ $elapsed -gt $timeout ]; then
            print_error "Timeout waiting for workflows to complete"
            return 1
        fi
        
        # Check if any workflows are still running
        local running=$(gh run list --limit 5 --json status | jq -r '.[] | select(.status == "in_progress" or .status == "queued") | .status' | wc -l)
        
        if [ "$running" -eq 0 ]; then
            print_success "All workflows completed"
            return 0
        fi
        
        print_status "Still waiting... ($running workflows running, ${elapsed}s elapsed)"
        sleep 10
    done
}

# Main deployment and fix loop
main() {
    local max_attempts=5
    local attempt=1
    
    print_status "Starting automated deployment and error fixing process..."
    print_status "Maximum attempts: $max_attempts"
    
    while [ $attempt -le $max_attempts ]; do
        print_status "=== ATTEMPT $attempt/$max_attempts ==="
        
        # Check current status
        if check_github_actions; then
            local failure_count=$?
            if [ $failure_count -eq 0 ]; then
                print_success "All GitHub Actions are passing! 🎉"
                exit 0
            else
                print_warning "Found $failure_count failed workflows"
            fi
        fi
        
        # Get error details
        get_error_details
        
        # Try to fix known issues
        local changes_made=false
        
        # Fix SARIF permissions
        if fix_sarif_permissions; then
            changes_made=true
        fi
        
        # Fix Checkov results
        if fix_checkov_results; then
            changes_made=true
        fi
        
        # If we made changes, commit and push
        if [ "$changes_made" = true ]; then
            if commit_and_push "fix: GitHub Actions workflow issues (attempt $attempt)"; then
                print_status "Waiting 1 minute for GitHub to process changes..."
                sleep 60
                
                # Wait for workflows to complete
                wait_for_workflows 300
            fi
        else
            print_warning "No automatic fixes available for current errors"
            
            # Manual intervention might be needed
            print_status "Checking if we should retry anyway..."
            sleep 60
        fi
        
        attempt=$((attempt + 1))
    done
    
    print_error "Maximum attempts reached. Manual intervention may be required."
    print_status "Final status check:"
    check_github_actions
    
    exit 1
}

# Run the main function
main "$@"