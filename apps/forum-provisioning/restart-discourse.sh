#!/bin/bash

# Discourse Restart Script for RobbedByAppleCare
# This script safely restarts Discourse with proper health checks
# Run with: sudo ./restart-discourse.sh

set -euo pipefail

# Configuration
DISCOURSE_DIR="/var/discourse"
DISCOURSE_CONTAINER="discourse_app"
LOG_FILE="/var/log/discourse-restart.log"
FORUM_USER="discourse"

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
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}" | tee -a "$LOG_FILE"
    exit 1
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}" | tee -a "$LOG_FILE"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   error "This script must be run as root (use sudo)"
fi

# Function to check if Discourse is healthy
check_discourse_health() {
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -f http://localhost/srv/status >/dev/null 2>&1; then
            return 0
        fi
        sleep 10
        attempt=$((attempt + 1))
    done
    
    return 1
}

# Function to gracefully stop Discourse
stop_discourse() {
    log "Stopping Discourse gracefully..."
    
    if docker ps | grep -q "$DISCOURSE_CONTAINER"; then
        # Send SIGTERM to allow graceful shutdown
        docker exec "$DISCOURSE_CONTAINER" sv stop unicorn || true
        sleep 10
        
        # Stop the container
        cd "$DISCOURSE_DIR"
        sudo -u "$FORUM_USER" docker-compose down
        
        log "Discourse stopped successfully"
    else
        log "Discourse container was not running"
    fi
}

# Function to start Discourse
start_discourse() {
    log "Starting Discourse..."
    
    cd "$DISCOURSE_DIR"
    sudo -u "$FORUM_USER" docker-compose up -d
    
    log "Waiting for Discourse to become healthy..."
    if check_discourse_health; then
        log "✅ Discourse started successfully and is healthy"
    else
        error "❌ Discourse failed to start or become healthy"
    fi
}

# Function to update Discourse
update_discourse() {
    log "Updating Discourse to latest version..."
    
    cd "$DISCOURSE_DIR"
    
    # Pull latest images
    sudo -u "$FORUM_USER" docker-compose pull
    
    # Rebuild and restart
    sudo -u "$FORUM_USER" docker-compose up -d --force-recreate
    
    log "Discourse update completed"
}

# Function to show status
show_status() {
    log "Discourse Status Check:"
    
    if docker ps | grep -q "$DISCOURSE_CONTAINER"; then
        log "✅ Container is running"
        
        if check_discourse_health; then
            log "✅ Health check passed"
        else
            warn "⚠️  Health check failed"
        fi
        
        # Show container stats
        log "Container stats:"
        docker stats "$DISCOURSE_CONTAINER" --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}"
        
        # Show recent logs
        log "Recent logs (last 10 lines):"
        docker logs "$DISCOURSE_CONTAINER" --tail 10
    else
        warn "❌ Container is not running"
    fi
}

# Main function
main() {
    case "${1:-restart}" in
        "restart")
            log "🔄 Restarting Discourse..."
            stop_discourse
            start_discourse
            show_status
            ;;
        "stop")
            log "🛑 Stopping Discourse..."
            stop_discourse
            ;;
        "start")
            log "▶️  Starting Discourse..."
            start_discourse
            show_status
            ;;
        "update")
            log "⬆️  Updating Discourse..."
            stop_discourse
            update_discourse
            show_status
            ;;
        "status")
            show_status
            ;;
        "logs")
            log "📋 Showing Discourse logs..."
            docker logs "$DISCOURSE_CONTAINER" --tail 50 -f
            ;;
        *)
            echo "Usage: $0 {restart|start|stop|update|status|logs}"
            echo ""
            echo "Commands:"
            echo "  restart  - Gracefully restart Discourse (default)"
            echo "  start    - Start Discourse"
            echo "  stop     - Stop Discourse"
            echo "  update   - Update Discourse to latest version"
            echo "  status   - Show current status and health"
            echo "  logs     - Show and follow recent logs"
            exit 1
            ;;
    esac
    
    log "Operation completed. Check logs at: $LOG_FILE"
}

# Run main function with all arguments
main "$@"