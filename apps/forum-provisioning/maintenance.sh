#!/bin/bash

# Discourse Maintenance Script for RobbedByAppleCare
# This script handles routine maintenance tasks for Discourse
# Run with: sudo ./maintenance.sh [task]

set -euo pipefail

# Configuration
DISCOURSE_DIR="/var/discourse"
DISCOURSE_CONTAINER="discourse_app"
LOG_FILE="/var/log/discourse-maintenance.log"
AZURE_KEYVAULT_NAME="${AZURE_KEYVAULT_NAME:-robbedbyapplecare-kv}"

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
    exit 1
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}" | tee -a "$LOG_FILE"
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}" | tee -a "$LOG_FILE"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
       error "This script must be run as root (use sudo)"
    fi
}

# Function to check if Discourse is healthy
check_discourse_health() {
    if curl -f http://localhost/srv/status >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Function to update Discourse to latest version
update_discourse() {
    log "🔄 Starting Discourse update process..."
    
    # Check current health
    if ! check_discourse_health; then
        error "Discourse is not healthy, aborting update"
    fi
    
    # Create pre-update backup
    log "Creating pre-update backup..."
    if [[ -f "./backup-cron.sh" ]]; then
        ./backup-cron.sh
    else
        warn "Backup script not found, proceeding without backup"
    fi
    
    cd "$DISCOURSE_DIR"
    
    # Pull latest images
    log "Pulling latest Discourse images..."
    docker-compose pull
    
    # Stop services gracefully
    log "Stopping Discourse services..."
    docker-compose down
    
    # Start with new images
    log "Starting Discourse with updated images..."
    docker-compose up -d
    
    # Wait for services to be ready
    log "Waiting for services to be ready..."
    local max_wait=300
    local wait_time=0
    
    while [ $wait_time -lt $max_wait ]; do
        if check_discourse_health; then
            log "✅ Discourse update completed successfully"
            return 0
        fi
        sleep 10
        wait_time=$((wait_time + 10))
        log "Waiting for Discourse... ($wait_time/$max_wait seconds)"
    done
    
    error "❌ Discourse update failed - service not responding after $max_wait seconds"
}

# Function to rebuild Discourse (full rebuild)
rebuild_discourse() {
    log "🔨 Starting Discourse rebuild process..."
    
    # Create pre-rebuild backup
    log "Creating pre-rebuild backup..."
    if [[ -f "./backup-cron.sh" ]]; then
        ./backup-cron.sh
    else
        warn "Backup script not found, proceeding without backup"
    fi
    
    cd "$DISCOURSE_DIR"
    
    # Stop and remove containers
    log "Stopping and removing containers..."
    docker-compose down --volumes --remove-orphans
    
    # Remove old images
    log "Removing old images..."
    docker image prune -f
    
    # Pull fresh images
    log "Pulling fresh images..."
    docker-compose pull
    
    # Rebuild and start
    log "Rebuilding and starting Discourse..."
    docker-compose up -d --force-recreate
    
    # Wait for services to be ready
    log "Waiting for services to be ready..."
    local max_wait=600  # Longer wait for rebuild
    local wait_time=0
    
    while [ $wait_time -lt $max_wait ]; do
        if check_discourse_health; then
            log "✅ Discourse rebuild completed successfully"
            return 0
        fi
        sleep 15
        wait_time=$((wait_time + 15))
        log "Waiting for Discourse... ($wait_time/$max_wait seconds)"
    done
    
    error "❌ Discourse rebuild failed - service not responding after $max_wait seconds"
}

# Function to clean up system resources
cleanup_system() {
    log "🧹 Starting system cleanup..."
    
    # Clean Docker resources
    log "Cleaning Docker resources..."
    docker system prune -f
    docker volume prune -f
    docker image prune -a -f
    
    # Clean package cache
    log "Cleaning package cache..."
    apt-get autoremove -y
    apt-get autoclean
    
    # Clean log files
    log "Rotating and cleaning log files..."
    logrotate -f /etc/logrotate.conf
    
    # Clean temporary files
    log "Cleaning temporary files..."
    find /tmp -type f -atime +7 -delete 2>/dev/null || true
    find /var/tmp -type f -atime +7 -delete 2>/dev/null || true
    
    # Clean old backups (keep last 30 days)
    log "Cleaning old backup files..."
    find /var/backups -type f -mtime +30 -delete 2>/dev/null || true
    
    log "✅ System cleanup completed"
}

# Function to optimize database
optimize_database() {
    log "🗄️  Starting database optimization..."
    
    if ! check_discourse_health; then
        error "Discourse is not healthy, aborting database optimization"
    fi
    
    # Run database maintenance tasks
    log "Running database maintenance tasks..."
    docker exec "$DISCOURSE_CONTAINER" rails runner "
    # Analyze and vacuum database
    ActiveRecord::Base.connection.execute('ANALYZE;')
    ActiveRecord::Base.connection.execute('VACUUM ANALYZE;')
    
    # Update statistics
    ActiveRecord::Base.connection.execute('UPDATE pg_stat_user_tables SET n_tup_ins = 0, n_tup_upd = 0, n_tup_del = 0;')
    
    puts 'Database optimization completed'
    "
    
    # Rebuild search index
    log "Rebuilding search index..."
    docker exec "$DISCOURSE_CONTAINER" rails runner "
    SearchIndexer.rebuild_posts
    puts 'Search index rebuilt'
    "
    
    log "✅ Database optimization completed"
}

# Function to update SSL certificates
update_ssl() {
    log "🔒 Updating SSL certificates..."
    
    # Renew certificates
    certbot renew --quiet
    
    # Reload nginx
    systemctl reload nginx
    
    # Test SSL configuration
    if curl -I https://forum.robbedbyapplecare.com >/dev/null 2>&1; then
        log "✅ SSL certificates updated successfully"
    else
        error "❌ SSL certificate update failed"
    fi
}

# Function to update system packages
update_system() {
    log "📦 Updating system packages..."
    
    # Update package lists
    apt-get update
    
    # Upgrade packages
    apt-get upgrade -y
    
    # Update Azure CLI
    log "Updating Azure CLI..."
    curl -sL https://aka.ms/InstallAzureCLIDeb | bash
    
    # Update Docker Compose
    log "Updating Docker Compose..."
    local compose_version=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
    curl -L "https://github.com/docker/compose/releases/download/${compose_version}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    
    log "✅ System packages updated"
}

# Function to check and repair file permissions
fix_permissions() {
    log "🔧 Checking and fixing file permissions..."
    
    # Fix Discourse directory permissions
    chown -R discourse:discourse "$DISCOURSE_DIR"
    chmod -R 755 "$DISCOURSE_DIR"
    
    # Fix specific file permissions
    chmod 600 "$DISCOURSE_DIR/.env" 2>/dev/null || true
    chmod +x "$DISCOURSE_DIR"/../*.sh 2>/dev/null || true
    
    # Fix log file permissions
    chown discourse:discourse /var/log/discourse-*.log 2>/dev/null || true
    chmod 644 /var/log/discourse-*.log 2>/dev/null || true
    
    log "✅ File permissions fixed"
}

# Function to run security updates
security_update() {
    log "🛡️  Running security updates..."
    
    # Update system packages with security focus
    apt-get update
    apt-get upgrade -y
    
    # Update fail2ban rules
    systemctl restart fail2ban
    
    # Update firewall rules
    ufw --force reload
    
    # Check for security vulnerabilities
    log "Checking for security vulnerabilities..."
    if command -v lynis >/dev/null 2>&1; then
        lynis audit system --quick --quiet
    else
        warn "Lynis not installed, skipping security audit"
    fi
    
    log "✅ Security updates completed"
}

# Function to generate maintenance report
generate_report() {
    local report_file="/tmp/discourse-maintenance-report-$(date +%Y%m%d-%H%M%S).txt"
    
    log "📊 Generating maintenance report..."
    
    {
        echo "=== Discourse Maintenance Report ==="
        echo "Generated: $(date)"
        echo "Hostname: $(hostname)"
        echo ""
        
        echo "=== System Information ==="
        echo "OS: $(lsb_release -d | cut -f2)"
        echo "Kernel: $(uname -r)"
        echo "Uptime: $(uptime -p)"
        echo ""
        
        echo "=== Discourse Status ==="
        if check_discourse_health; then
            echo "Status: ✅ Healthy"
        else
            echo "Status: ❌ Unhealthy"
        fi
        
        echo "Container Status:"
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep discourse || echo "No discourse containers running"
        echo ""
        
        echo "=== Resource Usage ==="
        echo "Memory:"
        free -h
        echo ""
        echo "Disk Usage:"
        df -h | grep -E "(/$|/var)"
        echo ""
        echo "Docker Usage:"
        docker system df
        echo ""
        
        echo "=== Recent Logs ==="
        echo "Last 10 maintenance log entries:"
        tail -10 "$LOG_FILE" 2>/dev/null || echo "No maintenance logs found"
        echo ""
        
        echo "=== SSL Certificate Status ==="
        echo "Certificate expiry:"
        echo | openssl s_client -servername forum.robbedbyapplecare.com -connect forum.robbedbyapplecare.com:443 2>/dev/null | openssl x509 -noout -dates 2>/dev/null || echo "Could not check SSL certificate"
        echo ""
        
        echo "=== Backup Status ==="
        echo "Recent backups:"
        find /var/backups -name "*.tar.gz" -mtime -7 -ls 2>/dev/null | head -5 || echo "No recent backups found"
        echo ""
        
    } > "$report_file"
    
    log "Maintenance report generated: $report_file"
    
    # Display summary
    info "=== Maintenance Report Summary ==="
    if check_discourse_health; then
        info "✅ Discourse Status: Healthy"
    else
        warn "❌ Discourse Status: Unhealthy"
    fi
    
    local disk_usage=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
    info "💾 Disk Usage: ${disk_usage}%"
    
    local mem_usage=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
    info "🧠 Memory Usage: ${mem_usage}%"
    
    info "📄 Full report: $report_file"
}

# Function to rotate credentials and keys
rotate_keys() {
    log "🔑 Starting credential rotation process..."
    
    if ! check_discourse_health; then
        error "Discourse is not healthy, aborting key rotation"
    fi
    
    # Create pre-rotation backup
    log "Creating pre-rotation backup..."
    if [[ -f "./backup-cron.sh" ]]; then
        ./backup-cron.sh
    else
        warn "Backup script not found, proceeding without backup"
    fi
    
    log "Rotating OAuth secrets..."
    
    # Note: This is a template for key rotation
    # In practice, you would:
    # 1. Generate new secrets in OAuth provider consoles
    # 2. Update secrets in Azure Key Vault
    # 3. Restart Discourse to pick up new secrets
    # 4. Verify functionality
    
    warn "Key rotation requires manual steps:"
    warn "1. Generate new OAuth secrets in Google/Facebook consoles"
    warn "2. Update secrets in Azure Key Vault:"
    warn "   - google-client-secret"
    warn "   - facebook-app-secret"
    warn "   - smtp-password (if needed)"
    warn "   - blob-access-key (if needed)"
    warn "3. Run: $0 restart-after-rotation"
    
    log "Credential rotation preparation completed"
}

# Function to restart services after key rotation
restart_after_rotation() {
    log "🔄 Restarting services after credential rotation..."
    
    # Restart Discourse to pick up new secrets
    if [[ -f "./restart-discourse.sh" ]]; then
        ./restart-discourse.sh restart
    else
        cd "$DISCOURSE_DIR"
        docker-compose down
        sleep 10
        docker-compose up -d
    fi
    
    # Wait for services to be ready
    log "Waiting for services to be ready after rotation..."
    local max_wait=300
    local wait_time=0
    
    while [ $wait_time -lt $max_wait ]; do
        if check_discourse_health; then
            log "✅ Services restarted successfully after rotation"
            
            # Test OAuth functionality
            log "Testing OAuth functionality..."
            docker exec "$DISCOURSE_CONTAINER" rails runner "
            # Test Google OAuth configuration
            if SiteSetting.google_oauth2_client_id.present? && SiteSetting.google_oauth2_client_secret.present?
              puts 'Google OAuth configuration present'
            else
              puts 'WARNING: Google OAuth configuration missing'
            end
            
            # Test Facebook OAuth configuration
            if SiteSetting.facebook_app_id.present? && SiteSetting.facebook_app_secret.present?
              puts 'Facebook OAuth configuration present'
            else
              puts 'WARNING: Facebook OAuth configuration missing'
            end
            
            puts 'OAuth configuration check completed'
            "
            
            return 0
        fi
        sleep 10
        wait_time=$((wait_time + 10))
        log "Waiting for services... ($wait_time/$max_wait seconds)"
    done
    
    error "❌ Services failed to restart properly after rotation"
}

# Function to show usage
show_usage() {
    echo "Discourse Maintenance Script for RobbedByAppleCare"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  update              Update Discourse to latest version"
    echo "  rebuild             Full rebuild of Discourse containers"
    echo "  cleanup             Clean up system resources and old files"
    echo "  optimize-db         Optimize database and rebuild search index"
    echo "  update-ssl          Update SSL certificates"
    echo "  update-system       Update system packages and tools"
    echo "  fix-permissions     Fix file and directory permissions"
    echo "  security-update     Run security-focused updates"
    echo "  rotate-keys         Prepare for credential rotation"
    echo "  restart-after-rotation  Restart services after key rotation"
    echo "  report              Generate maintenance report"
    echo "  full                Run full maintenance (all tasks except rebuild)"
    echo "  help                Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 update                    # Update Discourse"
    echo "  $0 full                      # Run full maintenance"
    echo "  $0 rotate-keys               # Prepare for credential rotation"
    echo "  $0 report                    # Generate status report"
}

# Main function
main() {
    local command="${1:-help}"
    
    case "$command" in
        "update")
            check_root
            update_discourse
            ;;
        "rebuild")
            check_root
            rebuild_discourse
            ;;
        "cleanup")
            check_root
            cleanup_system
            ;;
        "optimize-db")
            check_root
            optimize_database
            ;;
        "update-ssl")
            check_root
            update_ssl
            ;;
        "update-system")
            check_root
            update_system
            ;;
        "fix-permissions")
            check_root
            fix_permissions
            ;;
        "security-update")
            check_root
            security_update
            ;;
        "rotate-keys")
            check_root
            rotate_keys
            ;;
        "restart-after-rotation")
            check_root
            restart_after_rotation
            ;;
        "report")
            generate_report
            ;;
        "full")
            check_root
            log "🔄 Starting full maintenance routine..."
            
            # Run all maintenance tasks except rebuild
            update_discourse
            cleanup_system
            optimize_database
            update_ssl
            update_system
            fix_permissions
            security_update
            generate_report
            
            log "✅ Full maintenance routine completed"
            ;;
        "help"|*)
            show_usage
            ;;
    esac
}

# Handle script interruption
trap 'error "Maintenance interrupted"' INT TERM

# Run main function with all arguments
main "$@"