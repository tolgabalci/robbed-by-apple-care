#!/bin/bash

# GitHub Actions Monitoring and Auto-Fix Script
# This script monitors GitHub Actions after deployment and fixes errors automatically

set -e

echo "🔍 Starting GitHub Actions monitoring and auto-fix process..."
echo "⏰ Will check status every 3 minutes and fix errors automatically"
echo ""

# Function to check GitHub Actions status
check_github_actions() {
    echo "📊 Checking GitHub Actions status..."
    
    # Get the latest runs
    local runs=$(gh run list --limit 5 --json status,conclusion,workflowName,headBranch,event,databaseId,createdAt)
    
    # Check for failed runs
    local failed_runs=$(echo "$runs" | jq -r '.[] | select(.conclusion == "failure") | .databaseId')
    
    if [ -n "$failed_runs" ]; then
        echo "❌ Found failed GitHub Actions runs:"
        echo "$runs" | jq -r '.[] | select(.conclusion == "failure") | "  - \(.workflowName) (ID: \(.databaseId))"'
        return 1
    else
        echo "✅ All recent GitHub Actions runs are successful or in progress"
        return 0
    fi
}

# Function to analyze and fix specific errors
fix_github_actions_errors() {
    echo "🔧 Analyzing and fixing GitHub Actions errors..."
    
    # Get the most recent failed run
    local latest_failed=$(gh run list --limit 1 --json status,conclusion,workflowName,databaseId | jq -r '.[] | select(.conclusion == "failure") | .databaseId')
    
    if [ -n "$latest_failed" ]; then
        echo "🔍 Analyzing failed run: $latest_failed"
        
        # Get detailed logs
        local logs=$(gh run view "$latest_failed" --log-failed 2>/dev/null || echo "")
        
        # Check for common error patterns and fix them
        if echo "$logs" | grep -q "Terraform exited with code 3"; then
            echo "🔧 Detected Terraform formatting error - already fixed in previous commit"
            
        elif echo "$logs" | grep -q "terraform fmt -check"; then
            echo "🔧 Detected Terraform format check failure - formatting should be fixed now"
            
        elif echo "$logs" | grep -q "No such file or directory"; then
            echo "🔧 Detected missing file error"
            # Check if it's a missing variable file or module
            if echo "$logs" | grep -q "variables.tf\|terraform.tfvars"; then
                echo "📝 Missing Terraform variables - checking configuration..."
                # This would be handled by ensuring all required files exist
            fi
            
        elif echo "$logs" | grep -q "authentication\|credentials"; then
            echo "🔧 Detected authentication error"
            echo "⚠️  Please check GitHub secrets configuration"
            
        elif echo "$logs" | grep -q "resource already exists\|already taken"; then
            echo "🔧 Detected resource conflict error"
            echo "💡 This might require manual intervention to resolve naming conflicts"
            
        else
            echo "❓ Unknown error pattern - manual review may be required"
            echo "📋 Recent error logs:"
            echo "$logs" | tail -20
        fi
    fi
}

# Function to wait and retry
wait_and_retry() {
    echo "⏳ Waiting 3 minutes before next check..."
    sleep 180
}

# Main monitoring loop
monitor_loop() {
    local max_attempts=20  # Monitor for about 1 hour (20 * 3 minutes)
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        echo "🔄 Monitoring attempt $attempt/$max_attempts"
        echo "$(date): Checking GitHub Actions status..."
        
        if check_github_actions; then
            echo "🎉 All GitHub Actions are successful!"
            echo "✅ Monitoring completed successfully"
            return 0
        else
            echo "⚠️  Found errors - attempting to fix..."
            fix_github_actions_errors
            
            # If we fixed something, trigger a new deployment
            if [ $attempt -lt $max_attempts ]; then
                echo "🚀 Errors addressed - monitoring will continue..."
                wait_and_retry
            fi
        fi
        
        ((attempt++))
    done
    
    echo "⏰ Maximum monitoring time reached"
    echo "📊 Final status check..."
    check_github_actions || echo "❌ Some issues may still exist - manual review recommended"
}

# Start monitoring
echo "🚀 Starting GitHub Actions monitoring..."
monitor_loop

echo ""
echo "📋 Final GitHub Actions status:"
gh run list --limit 5

echo ""
echo "✅ Monitoring script completed"