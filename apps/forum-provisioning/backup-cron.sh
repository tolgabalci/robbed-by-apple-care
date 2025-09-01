#!/bin/bash

# Discourse Backup Script for RobbedByAppleCare
# This script creates nightly backups of Discourse and uploads them to Azure Blob Storage
# Run via cron: 0 2 * * * /path/to/backup-cron.sh

set -euo pipefail

# Configuration
DISCOURSE_DIR="/var/discourse"
DISCOURSE_CONTAINER="discourse_app"
BACKUP_DIR="/var/backups/discourse"
LOG_FILE="/var/log/discourse-backup.log"
RETENTION_DAYS=30
AZURE_KEYVAULT_NAME="${AZURE_KEYVAULT_NAME:-robbedbyapplecare-kv}"

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

# Function to get secrets from Azure Key Vault
get_secret() {
    local secret_name="$1"
    local secret_value
    
    # Authenticate using Managed Identity
    az login --identity --allow-no-subscriptions >/dev/null 2>&1
    
    secret_value=$(az keyvault secret show \
        --vault-name "$AZURE_KEYVAULT_NAME" \
        --name "$secret_name" \
        --query value \
        --output tsv 2>/dev/null)
    
    if [[ -z "$secret_value" ]]; then
        error "Failed to retrieve secret: $secret_name"
    fi
    
    echo "$secret_value"
}

# Function to check if Discourse is healthy
check_discourse_health() {
    if curl -f http://localhost/srv/status >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Function to create Discourse backup
create_discourse_backup() {
    local backup_filename="discourse-backup-$(date +%Y%m%d-%H%M%S)"
    
    log "Creating Discourse backup: $backup_filename"
    
    # Check if Discourse is running
    if ! docker ps | grep -q "$DISCOURSE_CONTAINER"; then
        error "Discourse container is not running"
    fi
    
    # Create backup using Discourse's built-in backup system
    docker exec "$DISCOURSE_CONTAINER" discourse backup "$backup_filename" || {
        error "Failed to create Discourse backup"
    }
    
    # Wait for backup to complete
    local max_wait=1800  # 30 minutes
    local wait_time=0
    
    while [ $wait_time -lt $max_wait ]; do
        if docker exec "$DISCOURSE_CONTAINER" ls /shared/backups/default/ | grep -q "$backup_filename"; then
            log "Backup created successfully: $backup_filename"
            echo "$backup_filename"
            return 0
        fi
        sleep 30
        wait_time=$((wait_time + 30))
        log "Waiting for backup to complete... ($wait_time/$max_wait seconds)"
    done
    
    error "Backup creation timed out after $max_wait seconds"
}

# Function to create database backup
create_database_backup() {
    local db_backup_file="$BACKUP_DIR/postgres-$(date +%Y%m%d-%H%M%S).sql.gz"
    
    log "Creating PostgreSQL database backup..."
    
    # Get database credentials
    local postgres_host=$(get_secret "postgres-host")
    local postgres_password=$(get_secret "postgres-password")
    
    # Create database backup
    PGPASSWORD="$postgres_password" pg_dump \
        -h "$postgres_host" \
        -U discourse_user \
        -d discourse_production \
        --verbose \
        --no-owner \
        --no-privileges \
        | gzip > "$db_backup_file" || {
        error "Failed to create database backup"
    }
    
    log "Database backup created: $db_backup_file"
    echo "$db_backup_file"
}

# Function to backup configuration files
backup_configuration() {
    local config_backup_file="$BACKUP_DIR/config-$(date +%Y%m%d-%H%M%S).tar.gz"
    
    log "Creating configuration backup..."
    
    # Create tar archive of configuration files
    tar -czf "$config_backup_file" \
        -C "$DISCOURSE_DIR" \
        containers/app.yml \
        docker-compose.yml \
        .env \
        2>/dev/null || {
        warn "Some configuration files may be missing"
    }
    
    # Also backup nginx configuration
    if [ -f "/etc/nginx/sites-available/discourse" ]; then
        tar -czf "$config_backup_file.tmp" "$config_backup_file" /etc/nginx/sites-available/discourse
        mv "$config_backup_file.tmp" "$config_backup_file"
    fi
    
    log "Configuration backup created: $config_backup_file"
    echo "$config_backup_file"
}

# Function to upload backup to Azure Blob Storage
upload_to_blob() {
    local file_path="$1"
    local blob_name="$(basename "$file_path")"
    
    log "Uploading backup to Azure Blob Storage: $blob_name"
    
    # Get storage account credentials
    local storage_account=$(get_secret "storage-account-name")
    local blob_access_key=$(get_secret "blob-access-key")
    
    # Upload to blob storage
    az storage blob upload \
        --account-name "$storage_account" \
        --account-key "$blob_access_key" \
        --container-name "discourse-backups" \
        --name "$(date +%Y/%m)/$blob_name" \
        --file "$file_path" \
        --overwrite \
        --output none || {
        error "Failed to upload backup to blob storage: $blob_name"
    }
    
    log "Successfully uploaded: $blob_name"
}

# Function to cleanup old local backups
cleanup_local_backups() {
    log "Cleaning up local backups older than $RETENTION_DAYS days..."
    
    find "$BACKUP_DIR" -type f -name "*.tar.gz" -mtime +$RETENTION_DAYS -delete
    find "$BACKUP_DIR" -type f -name "*.sql.gz" -mtime +$RETENTION_DAYS -delete
    
    # Also cleanup old Discourse backups
    docker exec "$DISCOURSE_CONTAINER" find /shared/backups/default/ -name "*.tar.gz" -mtime +$RETENTION_DAYS -delete 2>/dev/null || true
    
    log "Local backup cleanup completed"
}

# Function to cleanup old blob backups
cleanup_blob_backups() {
    log "Cleaning up blob backups older than $RETENTION_DAYS days..."
    
    local storage_account=$(get_secret "storage-account-name")
    local blob_access_key=$(get_secret "blob-access-key")
    local cutoff_date=$(date -d "$RETENTION_DAYS days ago" +%Y-%m-%dT%H:%M:%SZ)
    
    # List and delete old backups
    az storage blob list \
        --account-name "$storage_account" \
        --account-key "$blob_access_key" \
        --container-name "discourse-backups" \
        --query "[?properties.lastModified<'$cutoff_date'].name" \
        --output tsv | while read -r blob_name; do
        
        if [[ -n "$blob_name" ]]; then
            az storage blob delete \
                --account-name "$storage_account" \
                --account-key "$blob_access_key" \
                --container-name "discourse-backups" \
                --name "$blob_name" \
                --output none
            log "Deleted old backup: $blob_name"
        fi
    done
    
    log "Blob backup cleanup completed"
}

# Function to send backup notification
send_notification() {
    local status="$1"
    local message="$2"
    
    # Log the notification
    if [[ "$status" == "success" ]]; then
        log "✅ Backup completed successfully: $message"
    else
        error "❌ Backup failed: $message"
    fi
    
    # Could integrate with monitoring systems here
    # For example: send to Azure Monitor, Slack, email, etc.
}

# Function to verify backup integrity
verify_backup() {
    local backup_file="$1"
    
    log "Verifying backup integrity: $(basename "$backup_file")"
    
    # Check if file exists and is not empty
    if [[ ! -f "$backup_file" ]] || [[ ! -s "$backup_file" ]]; then
        error "Backup file is missing or empty: $backup_file"
    fi
    
    # For tar.gz files, test the archive
    if [[ "$backup_file" == *.tar.gz ]]; then
        if ! tar -tzf "$backup_file" >/dev/null 2>&1; then
            error "Backup archive is corrupted: $backup_file"
        fi
    fi
    
    # For SQL files, check basic structure
    if [[ "$backup_file" == *.sql.gz ]]; then
        if ! zcat "$backup_file" | head -10 | grep -q "PostgreSQL database dump"; then
            warn "Database backup may be incomplete: $backup_file"
        fi
    fi
    
    log "Backup verification passed: $(basename "$backup_file")"
}

# Main backup function
main() {
    local start_time=$(date +%s)
    
    log "🔄 Starting nightly backup process..."
    
    # Check if Discourse is healthy before backup
    if ! check_discourse_health; then
        error "Discourse is not healthy, aborting backup"
    fi
    
    # Create backup directory
    mkdir -p "$BACKUP_DIR"
    
    # Initialize backup tracking
    local backup_files=()
    local backup_success=true
    
    # Create Discourse application backup
    if discourse_backup=$(create_discourse_backup); then
        # Copy Discourse backup to our backup directory
        local discourse_backup_path="$BACKUP_DIR/$(basename "$discourse_backup").tar.gz"
        docker cp "$DISCOURSE_CONTAINER:/shared/backups/default/$discourse_backup.tar.gz" "$discourse_backup_path" || {
            warn "Failed to copy Discourse backup, but backup exists in container"
        }
        
        if [[ -f "$discourse_backup_path" ]]; then
            verify_backup "$discourse_backup_path"
            backup_files+=("$discourse_backup_path")
        fi
    else
        backup_success=false
        warn "Discourse backup failed"
    fi
    
    # Create database backup
    if db_backup=$(create_database_backup); then
        verify_backup "$db_backup"
        backup_files+=("$db_backup")
    else
        backup_success=false
        warn "Database backup failed"
    fi
    
    # Create configuration backup
    if config_backup=$(backup_configuration); then
        verify_backup "$config_backup"
        backup_files+=("$config_backup")
    else
        backup_success=false
        warn "Configuration backup failed"
    fi
    
    # Upload backups to blob storage
    for backup_file in "${backup_files[@]}"; do
        if ! upload_to_blob "$backup_file"; then
            backup_success=false
            warn "Failed to upload: $(basename "$backup_file")"
        fi
    done
    
    # Cleanup old backups
    cleanup_local_backups
    cleanup_blob_backups
    
    # Calculate backup duration
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    # Send notification
    if [[ "$backup_success" == true ]]; then
        send_notification "success" "Backup completed in ${duration}s. Files: ${#backup_files[@]}"
    else
        send_notification "failure" "Backup completed with errors in ${duration}s"
    fi
    
    # Final health check
    if ! check_discourse_health; then
        warn "Discourse health check failed after backup"
    fi
    
    log "Backup process completed in ${duration} seconds"
}

# Handle script interruption
trap 'error "Backup interrupted"' INT TERM

# Run main function
main "$@"