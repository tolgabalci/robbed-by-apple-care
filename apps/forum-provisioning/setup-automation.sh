#!/bin/bash

# Setup Automation Script for RobbedByAppleCare Discourse
# This script sets up cron jobs and systemd services for automated backup and monitoring
# Run with: sudo ./setup-automation.sh

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/var/log/discourse-automation-setup.log"

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

log "🔧 Setting up Discourse automation for RobbedByAppleCare..."

# Create necessary directories
log "Creating directories..."
mkdir -p /var/backups/discourse
mkdir -p /var/lib/discourse-monitor
mkdir -p /var/log
mkdir -p /usr/local/bin/discourse

# Copy scripts to system locations
log "Installing scripts..."

# Make scripts executable
chmod +x "$SCRIPT_DIR"/*.sh

# Copy scripts to system bin directory
cp "$SCRIPT_DIR/backup-cron.sh" /usr/local/bin/discourse/
cp "$SCRIPT_DIR/health-monitor.sh" /usr/local/bin/discourse/
cp "$SCRIPT_DIR/maintenance.sh" /usr/local/bin/discourse/
cp "$SCRIPT_DIR/restart-discourse.sh" /usr/local/bin/discourse/

# Create symlinks for easy access
ln -sf /usr/local/bin/discourse/backup-cron.sh /usr/local/bin/discourse-backup
ln -sf /usr/local/bin/discourse/health-monitor.sh /usr/local/bin/discourse-health
ln -sf /usr/local/bin/discourse/maintenance.sh /usr/local/bin/discourse-maintenance
ln -sf /usr/local/bin/discourse/restart-discourse.sh /usr/local/bin/discourse-restart

# Set proper permissions
chown -R root:root /usr/local/bin/discourse/
chmod +x /usr/local/bin/discourse/*.sh
chmod +x /usr/local/bin/discourse-*

log "Scripts installed successfully"

# Setup cron jobs
log "Setting up cron jobs..."

# Create cron file for discourse automation
cat > /etc/cron.d/discourse-automation << 'EOF'
# Discourse Automation Cron Jobs for RobbedByAppleCare
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# Nightly backup at 2:00 AM
0 2 * * * root /usr/local/bin/discourse/backup-cron.sh >> /var/log/discourse-backup.log 2>&1

# Health monitoring every 5 minutes
*/5 * * * * root /usr/local/bin/discourse/health-monitor.sh >> /var/log/discourse-health.log 2>&1

# Weekly maintenance on Sundays at 3:00 AM
0 3 * * 0 root /usr/local/bin/discourse/maintenance.sh full >> /var/log/discourse-maintenance.log 2>&1

# SSL certificate renewal check twice daily
0 0,12 * * * root /usr/bin/certbot renew --quiet --post-hook "systemctl reload nginx" >> /var/log/letsencrypt.log 2>&1

# Daily system cleanup at 1:00 AM
0 1 * * * root /usr/local/bin/discourse/maintenance.sh cleanup >> /var/log/discourse-maintenance.log 2>&1

# Monthly security updates on first Sunday at 4:00 AM
0 4 1-7 * 0 root /usr/local/bin/discourse/maintenance.sh security-update >> /var/log/discourse-maintenance.log 2>&1
EOF

# Set proper permissions for cron file
chmod 644 /etc/cron.d/discourse-automation
chown root:root /etc/cron.d/discourse-automation

log "Cron jobs configured"

# Setup systemd service for health monitoring (alternative to cron)
log "Setting up systemd health monitoring service..."

cat > /etc/systemd/system/discourse-health-monitor.service << 'EOF'
[Unit]
Description=Discourse Health Monitor
After=network.target docker.service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/discourse/health-monitor.sh
User=root
StandardOutput=append:/var/log/discourse-health.log
StandardError=append:/var/log/discourse-health.log

[Install]
WantedBy=multi-user.target
EOF

cat > /etc/systemd/system/discourse-health-monitor.timer << 'EOF'
[Unit]
Description=Run Discourse Health Monitor every 5 minutes
Requires=discourse-health-monitor.service

[Timer]
OnCalendar=*:0/5
Persistent=true

[Install]
WantedBy=timers.target
EOF

# Setup systemd service for backup
cat > /etc/systemd/system/discourse-backup.service << 'EOF'
[Unit]
Description=Discourse Backup Service
After=network.target docker.service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/discourse/backup-cron.sh
User=root
StandardOutput=append:/var/log/discourse-backup.log
StandardError=append:/var/log/discourse-backup.log

[Install]
WantedBy=multi-user.target
EOF

cat > /etc/systemd/system/discourse-backup.timer << 'EOF'
[Unit]
Description=Run Discourse Backup daily at 2:00 AM
Requires=discourse-backup.service

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
EOF

# Reload systemd and enable services
systemctl daemon-reload
systemctl enable discourse-health-monitor.timer
systemctl enable discourse-backup.timer
systemctl start discourse-health-monitor.timer
systemctl start discourse-backup.timer

log "Systemd services configured and started"

# Setup log rotation
log "Setting up log rotation..."

cat > /etc/logrotate.d/discourse-automation << 'EOF'
/var/log/discourse-*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 root root
    postrotate
        # Restart rsyslog to release log files
        systemctl reload rsyslog > /dev/null 2>&1 || true
    endscript
}

/var/log/letsencrypt.log {
    weekly
    missingok
    rotate 12
    compress
    delaycompress
    notifempty
    create 644 root root
}
EOF

log "Log rotation configured"

# Create Azure Blob Storage container for backups
log "Setting up Azure Blob Storage container..."

# Check if Azure CLI is available and authenticated
if command -v az >/dev/null 2>&1; then
    # Try to authenticate using managed identity
    if az login --identity --allow-no-subscriptions >/dev/null 2>&1; then
        # Get storage account name from Key Vault
        STORAGE_ACCOUNT=$(az keyvault secret show \
            --vault-name "${AZURE_KEYVAULT_NAME:-robbedbyapplecare-kv}" \
            --name "storage-account-name" \
            --query value \
            --output tsv 2>/dev/null || echo "")
        
        BLOB_ACCESS_KEY=$(az keyvault secret show \
            --vault-name "${AZURE_KEYVAULT_NAME:-robbedbyapplecare-kv}" \
            --name "blob-access-key" \
            --query value \
            --output tsv 2>/dev/null || echo "")
        
        if [[ -n "$STORAGE_ACCOUNT" && -n "$BLOB_ACCESS_KEY" ]]; then
            # Create backup container if it doesn't exist
            az storage container create \
                --account-name "$STORAGE_ACCOUNT" \
                --account-key "$BLOB_ACCESS_KEY" \
                --name "discourse-backups" \
                --public-access off \
                --output none 2>/dev/null || warn "Backup container may already exist"
            
            log "Azure Blob Storage container configured"
        else
            warn "Could not retrieve storage credentials from Key Vault"
        fi
    else
        warn "Could not authenticate with Azure CLI using managed identity"
    fi
else
    warn "Azure CLI not available, skipping blob storage setup"
fi

# Install required packages for monitoring
log "Installing monitoring dependencies..."

# Install PostgreSQL client for database backups
apt-get update
apt-get install -y postgresql-client-common postgresql-client

# Install additional monitoring tools
apt-get install -y htop iotop nethogs

log "Dependencies installed"

# Create initial test run
log "Running initial test of automation scripts..."

# Test health monitor
log "Testing health monitor..."
/usr/local/bin/discourse/health-monitor.sh || warn "Health monitor test failed"

# Test backup script (dry run)
log "Testing backup script..."
# We'll skip the actual backup test to avoid creating unnecessary backups during setup

# Test maintenance script report
log "Testing maintenance script..."
/usr/local/bin/discourse/maintenance.sh report || warn "Maintenance script test failed"

# Setup monitoring dashboard script
log "Creating monitoring dashboard..."

cat > /usr/local/bin/discourse-dashboard << 'EOF'
#!/bin/bash

# Discourse Monitoring Dashboard
# Quick overview of Discourse status and recent activity

echo "=== Discourse Monitoring Dashboard ==="
echo "Generated: $(date)"
echo ""

# Service Status
echo "=== Service Status ==="
if curl -f http://localhost/srv/status >/dev/null 2>&1; then
    echo "✅ Discourse: Healthy"
else
    echo "❌ Discourse: Unhealthy"
fi

if systemctl is-active --quiet nginx; then
    echo "✅ Nginx: Running"
else
    echo "❌ Nginx: Not running"
fi

if systemctl is-active --quiet docker; then
    echo "✅ Docker: Running"
else
    echo "❌ Docker: Not running"
fi

echo ""

# Container Status
echo "=== Container Status ==="
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(discourse|redis|postgres)" || echo "No containers running"
echo ""

# Resource Usage
echo "=== Resource Usage ==="
echo "Memory: $(free -h | awk 'NR==2{printf "%.1f%% used (%s/%s)", $3*100/$2, $3, $2}')"
echo "Disk: $(df -h / | awk 'NR==2{printf "%s used (%s)", $5, $4" available"}')"
echo "Load: $(uptime | awk -F'load average:' '{print $2}')"
echo ""

# Recent Activity
echo "=== Recent Activity ==="
echo "Last backup: $(find /var/backups -name "*.tar.gz" -printf '%T@ %p\n' 2>/dev/null | sort -n | tail -1 | awk '{print strftime("%Y-%m-%d %H:%M:%S", $1), $2}' || echo "No backups found")"
echo "Health checks: $(tail -5 /var/log/discourse-health.log 2>/dev/null | wc -l) recent entries"
echo "Maintenance: $(tail -5 /var/log/discourse-maintenance.log 2>/dev/null | wc -l) recent entries"
echo ""

# Alerts
echo "=== Recent Alerts ==="
if [[ -f "/var/log/discourse-alerts.log" ]]; then
    tail -5 /var/log/discourse-alerts.log 2>/dev/null || echo "No recent alerts"
else
    echo "No alerts logged"
fi
EOF

chmod +x /usr/local/bin/discourse-dashboard

log "Monitoring dashboard created at: /usr/local/bin/discourse-dashboard"

# Final status check
log "Performing final status check..."

# Check cron service
if systemctl is-active --quiet cron; then
    log "✅ Cron service is running"
else
    warn "❌ Cron service is not running"
fi

# Check systemd timers
if systemctl is-active --quiet discourse-health-monitor.timer; then
    log "✅ Health monitor timer is active"
else
    warn "❌ Health monitor timer is not active"
fi

if systemctl is-active --quiet discourse-backup.timer; then
    log "✅ Backup timer is active"
else
    warn "❌ Backup timer is not active"
fi

# Show timer status
log "Timer status:"
systemctl list-timers discourse-* --no-pager

log "✅ Discourse automation setup completed successfully!"
log ""
log "📋 Summary:"
log "   - Backup: Daily at 2:00 AM"
log "   - Health monitoring: Every 5 minutes"
log "   - Weekly maintenance: Sundays at 3:00 AM"
log "   - SSL renewal: Twice daily"
log "   - Daily cleanup: 1:00 AM"
log "   - Monthly security updates: First Sunday at 4:00 AM"
log ""
log "🔧 Management Commands:"
log "   - discourse-dashboard     # View status dashboard"
log "   - discourse-backup        # Manual backup"
log "   - discourse-health        # Manual health check"
log "   - discourse-maintenance   # Manual maintenance"
log "   - discourse-restart       # Restart Discourse"
log ""
log "📊 Log Files:"
log "   - /var/log/discourse-backup.log"
log "   - /var/log/discourse-health.log"
log "   - /var/log/discourse-maintenance.log"
log "   - /var/log/discourse-alerts.log"
log ""
log "Setup completed. Check logs at: $LOG_FILE"