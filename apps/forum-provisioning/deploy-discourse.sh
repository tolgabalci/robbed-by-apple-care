#!/bin/bash

# Manual Discourse Deployment Script for RobbedByAppleCare
# This script can be used for manual deployments and troubleshooting
# Run with: ./deploy-discourse.sh [command] [options]

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DISCOURSE_DIR="/var/discourse"
DISCOURSE_CONTAINER="discourse_app"
LOG_FILE="/var/log/discourse-deploy.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}" | tee -a "$LOG_FILE"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}" | tee -a "$LOG_FILE"
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}" | tee -a "$LOG_FILE"
}

# Function to show usage
show_usage() {
    cat << EOF
Discourse Deployment Script for RobbedByAppleCare

Usage: $0 [COMMAND] [OPTIONS]

Commands:
  deploy          Deploy configuration files and restart Discourse
  config-only     Update configuration files without restart
  restart         Restart Discourse service
  update          Update Discourse to latest version
  health-check    Perform comprehensive health check
  rollback        Rollback to previous configuration
  logs            Show recent Discourse logs
  status          Show current status
  backup          Create manual backup
  help            Show this help message

Options:
  --force         Force operation even if checks fail
  --dry-run       Show what would be done without executing
  --verbose       Enable verbose output
  --backup        Create backup before deployment

Examples:
  $0 deploy --backup          # Deploy with automatic backup
  $0 config-only --dry-run    # Preview configuration changes
  $0 health-check --verbose   # Detailed health check
  $0 rollback                 # Rollback to previous config
  $0 update --force           # Force Discourse update

Environment Variables:
  DISCOURSE_DIR               # Discourse installation directory (default: /var/discourse)
  DISCOURSE_CONTAINER         # Container name (default: discourse_app)
  LOG_FILE                    # Log file path (default: /var/log/discourse-deploy.log)

EOF
}

# Function to check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    # Check if running as root or with sudo
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root or with sudo"
        exit 1
    fi
    
    # Check if Docker is running
    if ! systemctl is-active --quiet docker; then
        error "Docker service is not running"
        exit 1
    fi
    
    # Check if Discourse directory exists
    if [[ ! -d "$DISCOURSE_DIR" ]]; then
        error "Discourse directory not found: $DISCOURSE_DIR"
        exit 1
    fi
    
    # Check if configuration files exist in script directory
    if [[ ! -f "$SCRIPT_DIR/app.yml" ]]; then
        error "app.yml not found in script directory: $SCRIPT_DIR"
        exit 1
    fi
    
    log "Prerequisites check passed"
}

# Function to create backup
create_backup() {
    local backup_name="backup-$(date +%Y%m%d-%H%M%S)"
    local backup_dir="/var/backups/discourse"
    
    log "Creating backup: $backup_name"
    
    mkdir -p "$backup_dir"
    
    # Backup configuration files
    if [[ -f "$DISCOURSE_DIR/containers/app.yml" ]]; then
        cp "$DISCOURSE_DIR/containers/app.yml" "$backup_dir/app.yml.$backup_name"
        log "Configuration backed up to: $backup_dir/app.yml.$backup_name"
    fi
    
    # Backup environment file if it exists
    if [[ -f "$DISCOURSE_DIR/.env" ]]; then
        cp "$DISCOURSE_DIR/.env" "$backup_dir/.env.$backup_name"
        log "Environment file backed up"
    fi
    
    # Create Discourse backup via Rails
    if docker ps | grep -q "$DISCOURSE_CONTAINER"; then
        log "Creating Discourse database backup..."
        docker exec "$DISCOURSE_CONTAINER" discourse backup || warn "Database backup failed"
    fi
    
    echo "$backup_name"
}

# Function to validate configuration
validate_config() {
    log "Validating configuration files..."
    
    # Validate app.yml syntax
    if ! python3 -c "import yaml; yaml.safe_load(open('$SCRIPT_DIR/app.yml'))" 2>/dev/null; then
        error "Invalid YAML syntax in app.yml"
        return 1
    fi
    
    # Validate docker-compose.yml if present
    if [[ -f "$SCRIPT_DIR/docker-compose.yml" ]]; then
        if ! docker-compose -f "$SCRIPT_DIR/docker-compose.yml" config >/dev/null 2>&1; then
            error "Invalid docker-compose.yml"
            return 1
        fi
    fi
    
    # Check for required environment variables in app.yml
    local required_vars=("POSTGRES_HOST" "POSTGRES_PASSWORD" "STORAGE_ACCOUNT")
    for var in "${required_vars[@]}"; do
        if ! grep -q "$var" "$SCRIPT_DIR/app.yml"; then
            warn "Required variable $var not found in app.yml"
        fi
    done
    
    log "Configuration validation passed"
    return 0
}

# Function to deploy configuration
deploy_config() {
    local dry_run=${1:-false}
    local force_backup=${2:-false}
    
    log "Deploying Discourse configuration..."
    
    if [[ "$force_backup" == "true" ]]; then
        create_backup
    fi
    
    if [[ "$dry_run" == "true" ]]; then
        info "DRY RUN: Would copy the following files:"
        info "  $SCRIPT_DIR/app.yml -> $DISCOURSE_DIR/containers/app.yml"
        info "  $SCRIPT_DIR/*.sh -> $DISCOURSE_DIR/../"
        if [[ -f "$SCRIPT_DIR/docker-compose.yml" ]]; then
            info "  $SCRIPT_DIR/docker-compose.yml -> $DISCOURSE_DIR/docker-compose.yml"
        fi
        return 0
    fi
    
    # Copy configuration files
    cp "$SCRIPT_DIR/app.yml" "$DISCOURSE_DIR/containers/"
    log "Copied app.yml to containers directory"
    
    # Copy shell scripts
    for script in "$SCRIPT_DIR"/*.sh; do
        if [[ -f "$script" && "$(basename "$script")" != "deploy-discourse.sh" ]]; then
            cp "$script" "$DISCOURSE_DIR/../"
            chmod +x "$DISCOURSE_DIR/../$(basename "$script")"
            log "Copied $(basename "$script") to Discourse directory"
        fi
    done
    
    # Copy docker-compose.yml if present
    if [[ -f "$SCRIPT_DIR/docker-compose.yml" ]]; then
        cp "$SCRIPT_DIR/docker-compose.yml" "$DISCOURSE_DIR/"
        log "Copied docker-compose.yml"
    fi
    
    # Set proper ownership
    chown -R discourse:discourse "$DISCOURSE_DIR"
    
    log "Configuration deployment completed"
}

# Function to restart Discourse
restart_discourse() {
    local method=${1:-graceful}
    
    log "Restarting Discourse (method: $method)..."
    
    case "$method" in
        "graceful")
            if [[ -f "$DISCOURSE_DIR/../restart-discourse.sh" ]]; then
                cd "$DISCOURSE_DIR/.."
                ./restart-discourse.sh restart
            else
                # Fallback graceful restart
                cd "$DISCOURSE_DIR"
                docker-compose restart
            fi
            ;;
        "force")
            cd "$DISCOURSE_DIR"
            docker-compose down
            sleep 5
            docker-compose up -d
            ;;
        "reload")
            if docker ps | grep -q "$DISCOURSE_CONTAINER"; then
                docker exec "$DISCOURSE_CONTAINER" sv reload unicorn
            else
                warn "Container not running, performing full restart"
                restart_discourse "graceful"
            fi
            ;;
    esac
    
    log "Discourse restart completed"
}

# Function to perform health check
health_check() {
    local verbose=${1:-false}
    
    log "Performing health check..."
    
    local health_score=0
    local max_score=7
    
    # Check 1: Container status
    if docker ps | grep -q "$DISCOURSE_CONTAINER.*Up"; then
        health_score=$((health_score + 1))
        log "✅ Container is running"
    else
        error "❌ Container is not running"
    fi
    
    # Check 2: Health endpoint
    if curl -f http://localhost/srv/status >/dev/null 2>&1; then
        health_score=$((health_score + 1))
        log "✅ Health endpoint responding"
    else
        error "❌ Health endpoint not responding"
    fi
    
    # Check 3: Database connectivity
    if docker exec "$DISCOURSE_CONTAINER" rails runner "ActiveRecord::Base.connection.execute('SELECT 1')" >/dev/null 2>&1; then
        health_score=$((health_score + 1))
        log "✅ Database connectivity OK"
    else
        error "❌ Database connectivity failed"
    fi
    
    # Check 4: Redis connectivity
    if docker exec "$DISCOURSE_CONTAINER" redis-cli ping | grep -q "PONG"; then
        health_score=$((health_score + 1))
        log "✅ Redis connectivity OK"
    else
        error "❌ Redis connectivity failed"
    fi
    
    # Check 5: Disk space
    local disk_usage=$(df /var | awk 'NR==2 {print $5}' | sed 's/%//')
    if [[ $disk_usage -lt 90 ]]; then
        health_score=$((health_score + 1))
        log "✅ Disk space OK (${disk_usage}% used)"
    else
        error "❌ Disk space critical (${disk_usage}% used)"
    fi
    
    # Check 6: Memory usage
    local mem_usage=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
    if [[ $mem_usage -lt 90 ]]; then
        health_score=$((health_score + 1))
        log "✅ Memory usage OK (${mem_usage}%)"
    else
        error "❌ Memory usage high (${mem_usage}%)"
    fi
    
    # Check 7: External accessibility
    if curl -f -s -o /dev/null --connect-timeout 10 https://forum.robbedbyapplecare.com/srv/status; then
        health_score=$((health_score + 1))
        log "✅ External accessibility OK"
    else
        error "❌ External accessibility failed"
    fi
    
    # Verbose checks
    if [[ "$verbose" == "true" ]]; then
        info "=== Verbose Health Information ==="
        
        # Container stats
        info "Container stats:"
        docker stats "$DISCOURSE_CONTAINER" --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" || true
        
        # Recent logs
        info "Recent logs (last 10 lines):"
        docker logs "$DISCOURSE_CONTAINER" --tail 10 || true
        
        # Discourse version
        info "Discourse version:"
        docker exec "$DISCOURSE_CONTAINER" discourse version || true
        
        # Site settings check
        info "Key site settings:"
        docker exec "$DISCOURSE_CONTAINER" rails runner "
          puts 'Embed whitelist: ' + SiteSetting.embed_whitelist.to_s
          puts 'Force HTTPS: ' + SiteSetting.force_https.to_s
          puts 'Title: ' + SiteSetting.title.to_s
        " || true
    fi
    
    # Overall health assessment
    local health_percentage=$((health_score * 100 / max_score))
    
    if [[ $health_score -eq $max_score ]]; then
        log "🎉 Health check PASSED: ${health_score}/${max_score} (${health_percentage}%)"
        return 0
    elif [[ $health_score -ge $((max_score * 2 / 3)) ]]; then
        warn "⚠️  Health check DEGRADED: ${health_score}/${max_score} (${health_percentage}%)"
        return 1
    else
        error "❌ Health check FAILED: ${health_score}/${max_score} (${health_percentage}%)"
        return 2
    fi
}

# Function to rollback configuration
rollback_config() {
    log "Rolling back Discourse configuration..."
    
    local backup_dir="/var/backups/discourse"
    
    # Find the most recent backup
    local latest_backup=$(ls -t "$backup_dir"/app.yml.backup-* 2>/dev/null | head -1 || echo "")
    
    if [[ -z "$latest_backup" ]]; then
        error "No backup found for rollback"
        return 1
    fi
    
    log "Rolling back to: $(basename "$latest_backup")"
    
    # Restore configuration
    cp "$latest_backup" "$DISCOURSE_DIR/containers/app.yml"
    chown discourse:discourse "$DISCOURSE_DIR/containers/app.yml"
    
    # Restart Discourse
    restart_discourse "graceful"
    
    log "Rollback completed"
}

# Function to show logs
show_logs() {
    local lines=${1:-50}
    
    log "Showing Discourse logs (last $lines lines)..."
    
    if docker ps | grep -q "$DISCOURSE_CONTAINER"; then
        docker logs "$DISCOURSE_CONTAINER" --tail "$lines"
    else
        error "Discourse container is not running"
        return 1
    fi
}

# Function to show status
show_status() {
    log "Discourse Status Report"
    echo "========================"
    
    # Container status
    if docker ps | grep -q "$DISCOURSE_CONTAINER"; then
        echo "Container: ✅ Running"
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep discourse || true
    else
        echo "Container: ❌ Not Running"
    fi
    
    # Service status
    if systemctl is-active --quiet discourse 2>/dev/null; then
        echo "Service: ✅ Active"
    else
        echo "Service: ❌ Inactive"
    fi
    
    # Quick health check
    if curl -f http://localhost/srv/status >/dev/null 2>&1; then
        echo "Health: ✅ OK"
    else
        echo "Health: ❌ Failed"
    fi
    
    # Disk usage
    local disk_usage=$(df /var | awk 'NR==2 {print $5}')
    echo "Disk Usage: $disk_usage"
    
    # Memory usage
    local mem_usage=$(free | awk 'NR==2{printf "%.0f%%", $3*100/$2}')
    echo "Memory Usage: $mem_usage"
    
    # Last backup
    local last_backup=$(ls -t /var/backups/discourse/app.yml.backup-* 2>/dev/null | head -1 || echo "None")
    echo "Last Backup: $(basename "$last_backup" 2>/dev/null || echo "None")"
}

# Main function
main() {
    local command="${1:-help}"
    local dry_run=false
    local verbose=false
    local force=false
    local backup=false
    
    # Parse options
    shift || true
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run)
                dry_run=true
                shift
                ;;
            --verbose)
                verbose=true
                shift
                ;;
            --force)
                force=true
                shift
                ;;
            --backup)
                backup=true
                shift
                ;;
            *)
                warn "Unknown option: $1"
                shift
                ;;
        esac
    done
    
    # Execute command
    case "$command" in
        "deploy")
            check_prerequisites
            validate_config
            deploy_config "$dry_run" "$backup"
            if [[ "$dry_run" == "false" ]]; then
                restart_discourse "graceful"
                sleep 30
                health_check "$verbose"
            fi
            ;;
        "config-only")
            check_prerequisites
            validate_config
            deploy_config "$dry_run" "$backup"
            ;;
        "restart")
            check_prerequisites
            restart_discourse "graceful"
            sleep 30
            health_check
            ;;
        "update")
            check_prerequisites
            if [[ "$backup" == "true" ]]; then
                create_backup
            fi
            cd "$DISCOURSE_DIR"
            docker-compose pull
            docker-compose up -d --force-recreate
            sleep 60
            health_check "$verbose"
            ;;
        "health-check")
            health_check "$verbose"
            ;;
        "rollback")
            check_prerequisites
            rollback_config
            sleep 30
            health_check
            ;;
        "logs")
            show_logs 50
            ;;
        "status")
            show_status
            ;;
        "backup")
            check_prerequisites
            create_backup
            ;;
        "help"|*)
            show_usage
            ;;
    esac
}

# Run main function with all arguments
main "$@"