#!/bin/bash

# GitHub Actions Monitoring Script
# This script monitors GitHub Actions status every 3 minutes

set -e

echo "🔍 GitHub Actions Status Monitor"
echo "⏰ Checking status every 3 minutes..."
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

# Function to wait 3 minutes
wait_3_minutes() {
    echo "⏳ Waiting 3 minutes before next check..."
    sleep 180
}

# Main monitoring loop
monitor_loop() {
    local max_attempts=20  # Monitor for about 1 hour (20 * 3 minutes)
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        echo "🔄 Check $attempt/$max_attempts at $(date)"
        
        if check_github_actions; then
            echo "🎉 All GitHub Actions are successful!"
            echo "✅ Monitoring completed successfully"
            return 0
        else
            echo "⚠️  Found errors - manual intervention required"
            
            if [ $attempt -lt $max_attempts ]; then
                wait_3_minutes
            fi
        fi
        
        ((attempt++))
    done
    
    echo "⏰ Maximum monitoring time reached"
    echo "📊 Final status check..."
    check_github_actions || echo "❌ Some issues still exist - manual review required"
}

# Start monitoring
echo "🚀 Starting GitHub Actions monitoring..."
monitor_loop

echo ""
echo "📋 Final GitHub Actions status:"
gh run list --limit 5

echo ""
echo "✅ Monitoring script completed"