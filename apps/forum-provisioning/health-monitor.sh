#!/bin/bash

# Discourse Health Monitoring Script for RobbedByAppleCare
# This script monitors Discourse health and performs automatic recovery
# Run via cron: */5 * * * * /path/to/health-monitor.sh

set -euo pipefail

# Configuration
DISCOURSE_DIR="/var/discourse"
DISCOURSE_CONTAINER="discourse_app"
LOG_FILE="/var/log/discourse-health.log"
ALERT_LOG="/var/log/discourse-alerts.log"
MAX_RESTART_ATTEMPTS=3
RESTART_COOLDOWN=300  # 5 minutes between restart attempts
AZURE_KEYVAULT_NAME="${AZURE_KEYVAULT_NAME:-robbedbyapplecare-kv}"

# State files
STATE_DIR="/var/lib/discourse-monitor"
RESTART_COUNT_FILE="$STATE_DIR/restart_count"
LAST_RESTART_FILE="$STATE_DIR/last_restart"
HEALTH_STATUS_FILE="$STATE_DIR/health_status"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}" | tee -a "$LOG_FILE" | tee -a "$ALERT_LOG"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}" | tee -a "$LOG_FILE"
}

alert() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ALERT: $1${NC}" | tee -a "$LOG_FILE" | tee -a "$ALERT_LOG"
}

# Initialize state directory
init_state() {
    mkdir -p "$STATE_DIR"
    
    # Initialize files if they don't exist
    [[ ! -f "$RESTART_COUNT_FILE" ]] && echo "0" > "$RESTART_COUNT_FILE"
    [[ ! -f "$LAST_RESTART_FILE" ]] && echo "0" > "$LAST_RESTART_FILE"
    [[ ! -f "$HEALTH_STATUS_FILE" ]] && echo "unknown" > "$HEALTH_STATUS_FILE"
}

# Function to get current restart count
get_restart_count() {
    cat "$RESTART_COUNT_FILE" 2>/dev/null || echo "0"
}

# Function to increment restart count
increment_restart_count() {
    local count=$(get_restart_count)
    echo $((count + 1)) > "$RESTART_COUNT_FILE"
}

# Function to reset restart count
reset_restart_count() {
    echo "0" > "$RESTART_COUNT_FILE"
}

# Function to get last restart time
get_last_restart() {
    cat "$LAST_RESTART_FILE" 2>/dev/null || echo "0"
}

# Function to set last restart time
set_last_restart() {
    date +%s > "$LAST_RESTART_FILE"
}

# Function to get previous health status
get_previous_health_status() {
    cat "$HEALTH_STATUS_FILE" 2>/dev/null || echo "unknown"
}

# Function to set health status
set_health_status() {
    echo "$1" > "$HEALTH_STATUS_FILE"
}

# Function to check if cooldown period has passed
check_restart_cooldown() {
    local last_restart=$(get_last_restart)
    local current_time=$(date +%s)
    local time_diff=$((current_time - last_restart))
    
    if [[ $time_diff -lt $RESTART_COOLDOWN ]]; then
        local remaining=$((RESTART_COOLDOWN - time_diff))
        warn "Restart cooldown active. ${remaining}s remaining."
        return 1
    fi
    
    return 0
}

# Function to check basic connectivity
check_basic_connectivity() {
    # Check if we can reach localhost
    if ! curl -s --connect-timeout 5 http://localhost >/dev/null 2>&1; then
        return 1
    fi
    return 0
}

# Function to check Discourse health endpoint
check_discourse_health() {
    local timeout=10
    local response
    
    # Check health endpoint
    if response=$(curl -s --connect-timeout $timeout --max-time $timeout http://localhost/srv/status 2>/dev/null); then
        # Check if response contains expected content
        if echo "$response" | grep -q "ok\|healthy\|running"; then
            return 0
        fi
    fi
    
    return 1
}

# Function to check container status
check_container_status() {
    if docker ps --format "table {{.Names}}\t{{.Status}}" | grep -q "$DISCOURSE_CONTAINER.*Up"; then
        return 0
    fi
    return 1
}

# Function to check database connectivity
check_database_connectivity() {
    if docker exec "$DISCOURSE_CONTAINER" rails runner "ActiveRecord::Base.connection.execute('SELECT 1')" >/dev/null 2>&1; then
        return 0
    fi
    return 1
}

# Function to check Redis connectivity
check_redis_connectivity() {
    if docker exec "$DISCOURSE_CONTAINER" redis-cli ping | grep -q "PONG"; then
        return 0
    fi
    return 1
}

# Function to check disk space
check_disk_space() {
    local usage=$(df /var | awk 'NR==2 {print $5}' | sed 's/%//')
    
    if [[ $usage -gt 90 ]]; then
        alert "Disk space critical: ${usage}% used"
        return 1
    elif [[ $usage -gt 80 ]]; then
        warn "Disk space warning: ${usage}% used"
    fi
    
    return 0
}

# Function to check memory usage
check_memory_usage() {
    local mem_usage=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
    
    if [[ $mem_usage -gt 95 ]]; then
        alert "Memory usage critical: ${mem_usage}%"
        return 1
    elif [[ $mem_usage -gt 85 ]]; then
        warn "Memory usage high: ${mem_usage}%"
    fi
    
    return 0
}

# Function to check container resource usage
check_container_resources() {
    local stats
    
    if stats=$(docker stats "$DISCOURSE_CONTAINER" --no-stream --format "{{.CPUPerc}},{{.MemPerc}}" 2>/dev/null); then
        local cpu_usage=$(echo "$stats" | cut -d',' -f1 | sed 's/%//')
        local mem_usage=$(echo "$stats" | cut -d',' -f2 | sed 's/%//')
        
        # Remove any decimal points for comparison
        cpu_usage=${cpu_usage%.*}
        mem_usage=${mem_usage%.*}
        
        if [[ $cpu_usage -gt 90 ]]; then
            warn "Container CPU usage high: ${cpu_usage}%"
        fi
        
        if [[ $mem_usage -gt 90 ]]; then
            warn "Container memory usage high: ${mem_usage}%"
        fi
    fi
    
    return 0
}

# Function to perform comprehensive health check
perform_health_check() {
    local health_score=0
    local max_score=6
    local issues=()
    
    log "Performing comprehensive health check..."
    
    # Check container status
    if check_container_status; then
        health_score=$((health_score + 1))
        log "✅ Container status: Running"
    else
        issues+=("Container not running")
        error "❌ Container status: Not running"
    fi
    
    # Check basic connectivity
    if check_basic_connectivity; then
        health_score=$((health_score + 1))
        log "✅ Basic connectivity: OK"
    else
        issues+=("Basic connectivity failed")
        error "❌ Basic connectivity: Failed"
    fi
    
    # Check Discourse health endpoint
    if check_discourse_health; then
        health_score=$((health_score + 1))
        log "✅ Discourse health endpoint: OK"
    else
        issues+=("Health endpoint failed")
        error "❌ Discourse health endpoint: Failed"
    fi
    
    # Check database connectivity
    if check_database_connectivity; then
        health_score=$((health_score + 1))
        log "✅ Database connectivity: OK"
    else
        issues+=("Database connectivity failed")
        error "❌ Database connectivity: Failed"
    fi
    
    # Check Redis connectivity
    if check_redis_connectivity; then
        health_score=$((health_score + 1))
        log "✅ Redis connectivity: OK"
    else
        issues+=("Redis connectivity failed")
        error "❌ Redis connectivity: Failed"
    fi
    
    # Check system resources
    if check_disk_space && check_memory_usage; then
        health_score=$((health_score + 1))
        log "✅ System resources: OK"
    else
        issues+=("System resources critical")
        error "❌ System resources: Critical"
    fi
    
    # Check container resources
    check_container_resources
    
    # Calculate health percentage
    local health_percentage=$((health_score * 100 / max_score))
    
    log "Health check completed: ${health_score}/${max_score} (${health_percentage}%)"
    
    # Return health status
    if [[ $health_score -eq $max_score ]]; then
        return 0  # Healthy
    elif [[ $health_score -ge $((max_score * 2 / 3)) ]]; then
        return 1  # Degraded
    else
        return 2  # Critical
    fi
}

# Function to attempt service restart
attempt_restart() {
    local restart_count=$(get_restart_count)
    
    log "Attempting Discourse restart (attempt $((restart_count + 1))/$MAX_RESTART_ATTEMPTS)..."
    
    # Check restart cooldown
    if ! check_restart_cooldown; then
        return 1
    fi
    
    # Check if we've exceeded max attempts
    if [[ $restart_count -ge $MAX_RESTART_ATTEMPTS ]]; then
        alert "Maximum restart attempts ($MAX_RESTART_ATTEMPTS) exceeded. Manual intervention required."
        return 1
    fi
    
    # Increment restart count and set timestamp
    increment_restart_count
    set_last_restart
    
    # Perform restart
    log "Executing restart procedure..."
    
    # Use the existing restart script if available
    if [[ -f "$DISCOURSE_DIR/../restart-discourse.sh" ]]; then
        cd "$DISCOURSE_DIR/.."
        sudo ./restart-discourse.sh restart
    else
        # Fallback restart procedure
        cd "$DISCOURSE_DIR"
        docker-compose down
        sleep 10
        docker-compose up -d
    fi
    
    # Wait for service to stabilize
    log "Waiting for service to stabilize..."
    sleep 30
    
    # Verify restart was successful
    if perform_health_check; then
        log "✅ Restart successful"
        reset_restart_count  # Reset on successful restart
        return 0
    else
        error "❌ Restart failed"
        return 1
    fi
}

# Function to collect diagnostic information
collect_diagnostics() {
    local diag_file="/tmp/discourse-diagnostics-$(date +%Y%m%d-%H%M%S).log"
    
    log "Collecting diagnostic information..."
    
    {
        echo "=== Discourse Diagnostics ==="
        echo "Timestamp: $(date)"
        echo "Hostname: $(hostname)"
        echo ""
        
        echo "=== Container Status ==="
        docker ps -a | grep discourse || echo "No discourse containers found"
        echo ""
        
        echo "=== Container Logs (last 50 lines) ==="
        docker logs "$DISCOURSE_CONTAINER" --tail 50 2>&1 || echo "Failed to get container logs"
        echo ""
        
        echo "=== System Resources ==="
        echo "Memory:"
        free -h
        echo ""
        echo "Disk:"
        df -h
        echo ""
        echo "Load:"
        uptime
        echo ""
        
        echo "=== Network Connectivity ==="
        echo "Localhost connectivity:"
        curl -I http://localhost 2>&1 || echo "Failed to connect to localhost"
        echo ""
        
        echo "=== Process List ==="
        ps aux | grep -E "(docker|discourse|nginx)" | grep -v grep
        echo ""
        
        echo "=== Recent System Logs ==="
        journalctl -u docker --no-pager --lines=20
        echo ""
        
    } > "$diag_file"
    
    log "Diagnostics collected: $diag_file"
    
    # Keep only the last 5 diagnostic files
    find /tmp -name "discourse-diagnostics-*.log" -type f -mtime +1 -delete 2>/dev/null || true
}

# Function to send alert notification
send_alert() {
    local severity="$1"
    local message="$2"
    
    alert "[$severity] $message"
    
    # Could integrate with external alerting systems here
    # Examples:
    # - Send to Azure Monitor
    # - Send to Slack webhook
    # - Send email notification
    # - Create Azure Service Health incident
    
    # For now, just log to alert file
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [$severity] $message" >> "$ALERT_LOG"
}

# Main monitoring function
main() {
    init_state
    
    local previous_status=$(get_previous_health_status)
    local current_status
    
    # Perform health check
    if perform_health_check; then
        current_status="healthy"
        
        # If we recovered from an unhealthy state
        if [[ "$previous_status" != "healthy" ]]; then
            log "✅ Service recovered to healthy state"
            reset_restart_count
            send_alert "INFO" "Discourse service recovered to healthy state"
        fi
        
    else
        local health_result=$?
        
        if [[ $health_result -eq 1 ]]; then
            current_status="degraded"
            warn "⚠️  Service is in degraded state"
            
            # Only alert on status change
            if [[ "$previous_status" != "degraded" ]]; then
                send_alert "WARNING" "Discourse service is degraded"
            fi
            
        else
            current_status="critical"
            error "❌ Service is in critical state"
            
            # Collect diagnostics for critical issues
            collect_diagnostics
            
            # Only alert on status change
            if [[ "$previous_status" != "critical" ]]; then
                send_alert "CRITICAL" "Discourse service is critical"
            fi
            
            # Attempt restart for critical issues
            if attempt_restart; then
                current_status="healthy"
                send_alert "INFO" "Discourse service restarted successfully"
            else
                send_alert "CRITICAL" "Discourse service restart failed - manual intervention required"
            fi
        fi
    fi
    
    # Update health status
    set_health_status "$current_status"
    
    log "Health monitoring completed. Status: $current_status"
}

# Handle script interruption
trap 'error "Health monitoring interrupted"' INT TERM

# Run main function
main "$@"