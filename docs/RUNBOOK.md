# Operations Runbook

This runbook covers day-to-day operations, maintenance, and troubleshooting procedures.

## System Overview

- **Web App**: Azure Static Web Apps with Front Door
- **Forum**: Discourse on Azure VM with Docker
- **Database**: Azure Database for PostgreSQL Flexible Server
- **Storage**: Azure Blob Storage for uploads and backups

## Daily Operations

### Health Checks

```bash
# Check web application
curl -I https://www.robbedbyapplecare.com

# Check forum
curl -I https://forum.robbedbyapplecare.com

# Check Discourse health endpoint
curl https://forum.robbedbyapplecare.com/srv/status
```

### Monitoring and Alerting Setup

#### Key Metrics to Monitor

**Application Metrics:**
- Web app response times and availability (target: <2s, >99.9%)
- Discourse container health and memory usage
- PostgreSQL connection count and query performance
- Storage account usage and blob access patterns
- Front Door cache hit ratio (target: >80%)

**Infrastructure Metrics:**
- VM CPU and memory utilization (alert: >80%)
- Disk space usage (alert: >85%)
- Network connectivity and bandwidth
- SSL certificate expiration (alert: 30 days before)

#### Azure Monitor Setup

**Create Action Groups:**
```bash
# Create email action group
az monitor action-group create \
  --resource-group rg-robbedbyapplecare-prod \
  --name ag-robbedbyapplecare-email \
  --short-name "RBAEmail" \
  --action email admin admin@robbedbyapplecare.com

# Create SMS action group (optional)
az monitor action-group create \
  --resource-group rg-robbedbyapplecare-prod \
  --name ag-robbedbyapplecare-sms \
  --short-name "RBASMS" \
  --action sms admin +1234567890
```

**Website Availability Monitoring:**
```bash
# Create availability test for main site
az monitor app-insights web-test create \
  --resource-group rg-robbedbyapplecare-prod \
  --app-insights robbedbyapplecare-insights \
  --name "main-site-availability" \
  --location "East US" \
  --test-locations "us-east-azure" "us-west-azure" \
  --url "https://www.robbedbyapplecare.com" \
  --frequency 300 \
  --timeout 30

# Create availability test for forum
az monitor app-insights web-test create \
  --resource-group rg-robbedbyapplecare-prod \
  --app-insights robbedbyapplecare-insights \
  --name "forum-availability" \
  --location "East US" \
  --test-locations "us-east-azure" "us-west-azure" \
  --url "https://forum.robbedbyapplecare.com/srv/status" \
  --frequency 300 \
  --timeout 30
```

**VM Monitoring Alerts:**
```bash
# CPU usage alert
az monitor metrics alert create \
  --resource-group rg-robbedbyapplecare-prod \
  --name "vm-high-cpu" \
  --scopes "/subscriptions/<sub-id>/resourceGroups/rg-robbedbyapplecare-prod/providers/Microsoft.Compute/virtualMachines/vm-discourse" \
  --condition "avg Percentage CPU > 80" \
  --window-size 5m \
  --evaluation-frequency 1m \
  --action ag-robbedbyapplecare-email \
  --description "VM CPU usage is above 80%"

# Memory usage alert
az monitor metrics alert create \
  --resource-group rg-robbedbyapplecare-prod \
  --name "vm-high-memory" \
  --scopes "/subscriptions/<sub-id>/resourceGroups/rg-robbedbyapplecare-prod/providers/Microsoft.Compute/virtualMachines/vm-discourse" \
  --condition "avg Available Memory Bytes < 1073741824" \
  --window-size 5m \
  --evaluation-frequency 1m \
  --action ag-robbedbyapplecare-email \
  --description "VM available memory is below 1GB"

# Disk space alert
az monitor metrics alert create \
  --resource-group rg-robbedbyapplecare-prod \
  --name "vm-low-disk" \
  --scopes "/subscriptions/<sub-id>/resourceGroups/rg-robbedbyapplecare-prod/providers/Microsoft.Compute/virtualMachines/vm-discourse" \
  --condition "avg Disk Free Space < 15" \
  --window-size 5m \
  --evaluation-frequency 1m \
  --action ag-robbedbyapplecare-email \
  --description "VM disk space is below 15%"
```

**Database Monitoring:**
```bash
# Database connection alert
az monitor metrics alert create \
  --resource-group rg-robbedbyapplecare-prod \
  --name "db-high-connections" \
  --scopes "/subscriptions/<sub-id>/resourceGroups/rg-robbedbyapplecare-prod/providers/Microsoft.DBforPostgreSQL/flexibleServers/psql-robbedbyapplecare" \
  --condition "avg active_connections > 80" \
  --window-size 5m \
  --evaluation-frequency 1m \
  --action ag-robbedbyapplecare-email \
  --description "Database connection count is high"

# Database CPU alert
az monitor metrics alert create \
  --resource-group rg-robbedbyapplecare-prod \
  --name "db-high-cpu" \
  --scopes "/subscriptions/<sub-id>/resourceGroups/rg-robbedbyapplecare-prod/providers/Microsoft.DBforPostgreSQL/flexibleServers/psql-robbedbyapplecare" \
  --condition "avg cpu_percent > 80" \
  --window-size 5m \
  --evaluation-frequency 1m \
  --action ag-robbedbyapplecare-email \
  --description "Database CPU usage is high"
```

#### Custom Monitoring Scripts

**Discourse Health Check Script:**
```bash
# Create monitoring script on VM
ssh discourse-admin@<vm_ip>
sudo tee /usr/local/bin/discourse-health-check.sh << 'EOF'
#!/bin/bash

# Discourse health check script
LOG_FILE="/var/log/discourse-health.log"
WEBHOOK_URL="<slack-webhook-or-teams-webhook>"

check_discourse() {
    if curl -f -s https://forum.robbedbyapplecare.com/srv/status > /dev/null; then
        echo "$(date): Discourse is healthy" >> $LOG_FILE
        return 0
    else
        echo "$(date): Discourse health check failed" >> $LOG_FILE
        return 1
    fi
}

check_docker() {
    if docker ps | grep -q discourse_app; then
        echo "$(date): Discourse container is running" >> $LOG_FILE
        return 0
    else
        echo "$(date): Discourse container is not running" >> $LOG_FILE
        return 1
    fi
}

send_alert() {
    local message="$1"
    curl -X POST -H 'Content-type: application/json' \
        --data "{\"text\":\"🚨 RobbedByAppleCare Alert: $message\"}" \
        "$WEBHOOK_URL"
}

# Main health check
if ! check_discourse || ! check_docker; then
    send_alert "Discourse health check failed. Manual intervention required."
    exit 1
fi

echo "$(date): All health checks passed" >> $LOG_FILE
EOF

# Make executable
sudo chmod +x /usr/local/bin/discourse-health-check.sh

# Add to cron (every 5 minutes)
echo "*/5 * * * * /usr/local/bin/discourse-health-check.sh" | sudo crontab -
```

**SSL Certificate Monitoring:**
```bash
# SSL certificate expiration check
sudo tee /usr/local/bin/ssl-cert-check.sh << 'EOF'
#!/bin/bash

DOMAINS=("www.robbedbyapplecare.com" "forum.robbedbyapplecare.com")
WEBHOOK_URL="<webhook-url>"
DAYS_WARNING=30

for domain in "${DOMAINS[@]}"; do
    expiry_date=$(echo | openssl s_client -servername $domain -connect $domain:443 2>/dev/null | openssl x509 -noout -dates | grep notAfter | cut -d= -f2)
    expiry_epoch=$(date -d "$expiry_date" +%s)
    current_epoch=$(date +%s)
    days_until_expiry=$(( (expiry_epoch - current_epoch) / 86400 ))
    
    if [ $days_until_expiry -le $DAYS_WARNING ]; then
        message="SSL certificate for $domain expires in $days_until_expiry days"
        curl -X POST -H 'Content-type: application/json' \
            --data "{\"text\":\"⚠️ SSL Alert: $message\"}" \
            "$WEBHOOK_URL"
    fi
done
EOF

sudo chmod +x /usr/local/bin/ssl-cert-check.sh

# Run daily at 9 AM
echo "0 9 * * * /usr/local/bin/ssl-cert-check.sh" | sudo crontab -
```

#### Dashboard Setup

**Azure Dashboard Configuration:**
```bash
# Create custom dashboard
az portal dashboard create \
  --resource-group rg-robbedbyapplecare-prod \
  --name "RobbedByAppleCare Operations" \
  --input-path dashboard-config.json

# Dashboard should include:
# - VM metrics (CPU, Memory, Disk)
# - Database metrics (Connections, CPU, Storage)
# - Front Door metrics (Requests, Cache Hit Ratio)
# - Application Insights (Response Times, Availability)
# - Recent alerts and notifications
```

#### Log Aggregation

**Centralized Logging Setup:**
```bash
# Install Azure Monitor Agent on VM
ssh discourse-admin@<vm_ip>

# Download and install agent
wget https://aka.ms/AzureMonitorAgent/Linux/Latest -O AzureMonitorAgent.deb
sudo dpkg -i AzureMonitorAgent.deb

# Configure log collection
sudo tee /etc/opt/microsoft/azuremonitoragent/config.json << 'EOF'
{
  "logs": [
    {
      "name": "discourse-logs",
      "path": "/var/discourse/shared/standalone/log/rails/*.log",
      "format": "text"
    },
    {
      "name": "system-logs",
      "path": "/var/log/syslog",
      "format": "syslog"
    }
  ]
}
EOF

# Restart agent
sudo systemctl restart azuremonitoragent
```

## Discourse Operations

### Restart Discourse (Detailed Procedure)

**When to restart:**
- After configuration changes
- Performance issues or memory leaks
- Database connection problems
- Plugin updates or installations

**Step-by-step restart procedure:**

```bash
# 1. SSH to Discourse VM
ssh discourse-admin@<vm_public_ip>

# 2. Check current Discourse status
cd /var/discourse
sudo ./launcher logs app | tail -20

# 3. Graceful restart (recommended)
sudo ./launcher restart app

# 4. If graceful restart fails, force restart
sudo ./launcher stop app
sudo ./launcher start app

# 5. Verify restart success
sudo ./launcher logs app | tail -20
curl -f https://forum.robbedbyapplecare.com/srv/status

# 6. Check resource usage
docker stats discourse_app
free -h
df -h
```

**Emergency restart (if SSH is unresponsive):**
```bash
# From Azure CLI
az vm restart \
  --resource-group rg-robbedbyapplecare-prod \
  --name vm-discourse

# Wait 2-3 minutes, then verify
curl -f https://forum.robbedbyapplecare.com/srv/status
```

### Discourse Maintenance Procedures

#### Weekly Maintenance

```bash
# 1. Check Discourse health
ssh discourse-admin@<vm_ip>
cd /var/discourse
sudo ./launcher logs app | grep -i error | tail -10

# 2. Update Discourse (if updates available)
sudo ./launcher rebuild app --skip-prereqs

# 3. Clean up old Docker images
sudo docker system prune -f

# 4. Check disk usage
df -h
du -sh /var/discourse/shared/standalone/uploads/

# 5. Verify backup system
ls -la /var/discourse/shared/standalone/backups/
```

#### Plugin Management

```bash
# List installed plugins
sudo ./launcher enter app
cd /var/www/discourse
bundle exec rake plugins:list

# Install new plugin (example)
# Edit app.yml to add plugin git URL, then:
sudo ./launcher rebuild app

# Remove plugin
# Remove from app.yml, then:
sudo ./launcher rebuild app
```

#### Performance Optimization

```bash
# Rebuild search index (monthly)
sudo ./launcher enter app
cd /var/www/discourse
bundle exec rake search:reindex

# Clean up old uploads (quarterly)
bundle exec rake uploads:clean_up

# Optimize database (monthly)
bundle exec rake db:stats
```

## Backup and Restore Operations

### Automated Backup System

**Backup Schedule:**
- **Discourse Backups**: Daily at 2:00 AM UTC via cron
- **Database Backups**: Automatic Azure PostgreSQL backups (7-day retention)
- **File Uploads**: Stored in Azure Blob Storage (replicated)

**Monitoring Automated Backups:**

```bash
# Check backup cron job status
ssh discourse-admin@<vm_ip>
sudo crontab -l
sudo systemctl status cron

# Verify recent backups
ls -la /var/discourse/shared/standalone/backups/ | head -10

# Check backup upload to Azure Blob
az storage blob list \
  --container-name backups \
  --account-name <storage_account> \
  --query "[?contains(name, 'discourse-backup')].{Name:name,LastModified:properties.lastModified}" \
  --output table
```

### Manual Backup Procedures

#### Complete Discourse Backup

```bash
# 1. SSH to Discourse VM
ssh discourse-admin@<vm_ip>

# 2. Create Discourse backup (includes database and uploads)
cd /var/discourse
sudo ./launcher enter app
discourse backup --with-uploads

# 3. Exit container and check backup
exit
ls -la /var/discourse/shared/standalone/backups/

# 4. Upload to Azure Blob Storage
BACKUP_FILE=$(ls -t /var/discourse/shared/standalone/backups/*.tar.gz | head -1)
BACKUP_NAME="manual-discourse-backup-$(date +%Y%m%d-%H%M).tar.gz"

az storage blob upload \
  --account-name <storage_account> \
  --container-name backups \
  --name "$BACKUP_NAME" \
  --file "$BACKUP_FILE" \
  --overwrite

# 5. Verify upload
az storage blob show \
  --account-name <storage_account> \
  --container-name backups \
  --name "$BACKUP_NAME"
```

#### Database-Only Backup

```bash
# Create PostgreSQL dump
ssh discourse-admin@<vm_ip>
sudo -u postgres pg_dump discourse_production > /tmp/discourse_db_$(date +%Y%m%d).sql

# Upload to Azure Blob
az storage blob upload \
  --account-name <storage_account> \
  --container-name backups \
  --name "discourse_db_$(date +%Y%m%d).sql" \
  --file /tmp/discourse_db_$(date +%Y%m%d).sql
```

### Restore Procedures

#### Complete System Restore

**⚠️ WARNING: This will overwrite all current data. Ensure you have a recent backup before proceeding.**

```bash
# 1. Stop Discourse to prevent data corruption
ssh discourse-admin@<vm_ip>
cd /var/discourse
sudo ./launcher stop app

# 2. Download backup from Azure Blob
RESTORE_DATE="YYYY-MM-DD"  # Set to desired backup date
az storage blob download \
  --account-name <storage_account> \
  --container-name backups \
  --name "discourse-backup-${RESTORE_DATE}.tar.gz" \
  --file "/tmp/restore-${RESTORE_DATE}.tar.gz"

# 3. Copy backup to Discourse backups directory
sudo cp "/tmp/restore-${RESTORE_DATE}.tar.gz" /var/discourse/shared/standalone/backups/

# 4. Restore from backup
sudo ./launcher enter app
discourse restore "restore-${RESTORE_DATE}.tar.gz"

# 5. Exit and restart Discourse
exit
sudo ./launcher start app

# 6. Verify restore success
curl -f https://forum.robbedbyapplecare.com/srv/status
sudo ./launcher logs app | tail -20
```

#### Database-Only Restore

```bash
# 1. Stop Discourse
ssh discourse-admin@<vm_ip>
cd /var/discourse
sudo ./launcher stop app

# 2. Download database backup
RESTORE_DATE="YYYY-MM-DD"
az storage blob download \
  --account-name <storage_account> \
  --container-name backups \
  --name "discourse_db_${RESTORE_DATE}.sql" \
  --file "/tmp/discourse_db_restore.sql"

# 3. Restore database
sudo -u postgres psql -c "DROP DATABASE IF EXISTS discourse_production;"
sudo -u postgres psql -c "CREATE DATABASE discourse_production OWNER discourse_user;"
sudo -u postgres psql discourse_production < /tmp/discourse_db_restore.sql

# 4. Restart Discourse
sudo ./launcher start app

# 5. Rebuild to ensure consistency
sudo ./launcher rebuild app --skip-prereqs
```

#### Partial Restore (Uploads Only)

```bash
# If only file uploads need restoration
# 1. Download uploads backup
az storage blob download \
  --account-name <storage_account> \
  --container-name backups \
  --name "uploads-backup-YYYY-MM-DD.tar.gz" \
  --file "/tmp/uploads-restore.tar.gz"

# 2. Extract to uploads directory
ssh discourse-admin@<vm_ip>
sudo tar -xzf /tmp/uploads-restore.tar.gz -C /var/discourse/shared/standalone/uploads/

# 3. Fix permissions
sudo chown -R discourse:discourse /var/discourse/shared/standalone/uploads/
sudo chmod -R 755 /var/discourse/shared/standalone/uploads/

# 4. Restart Discourse
cd /var/discourse
sudo ./launcher restart app
```

### Backup Verification

**Monthly Backup Testing:**

```bash
# 1. Download recent backup
BACKUP_DATE=$(date -d "yesterday" +%Y-%m-%d)
az storage blob download \
  --account-name <storage_account> \
  --container-name backups \
  --name "discourse-backup-${BACKUP_DATE}.tar.gz" \
  --file "/tmp/test-backup.tar.gz"

# 2. Verify backup integrity
tar -tzf /tmp/test-backup.tar.gz > /dev/null
echo "Backup integrity: $?"  # Should be 0

# 3. Check backup size (should be reasonable)
ls -lh /tmp/test-backup.tar.gz

# 4. Document verification in maintenance log
echo "$(date): Backup verification completed for ${BACKUP_DATE}" >> /var/log/backup-verification.log
```

## Database Operations

### PostgreSQL Maintenance

```bash
# Connect to PostgreSQL
az postgres flexible-server connect \
  --name psql-discourse \
  --admin-user discourse_admin \
  --database-name discourse_production

# Check database size
SELECT pg_size_pretty(pg_database_size('discourse_production'));

# Check active connections
SELECT count(*) FROM pg_stat_activity;
```

### Database Backup

```bash
# Manual database backup
az postgres flexible-server backup create \
  --resource-group rg-robbedbyapplecare-prod \
  --server-name psql-discourse \
  --backup-name manual-backup-$(date +%Y%m%d)
```

## Security Operations

### Certificate Management

Certificates are automatically managed by Azure Front Door, but monitor expiration:

```bash
# Check certificate status
az afd custom-domain show \
  --resource-group rg-robbedbyapplecare-prod \
  --profile-name fd-robbedbyapplecare \
  --custom-domain-name www-robbedbyapplecare-com
```

### Key Rotation Procedures

**Rotation Schedule:**
- **Storage Account Keys**: Quarterly
- **OAuth Secrets**: Annually or when compromised
- **Database Passwords**: Annually
- **SSH Keys**: Annually

#### Storage Account Key Rotation

```bash
# 1. Get current key configuration
az storage account keys list \
  --resource-group rg-robbedbyapplecare-prod \
  --account-name <storage_account>

# 2. Rotate secondary key first (zero-downtime)
az storage account keys renew \
  --resource-group rg-robbedbyapplecare-prod \
  --account-name <storage_account> \
  --key secondary

# 3. Update Key Vault with new secondary key
NEW_KEY=$(az storage account keys list \
  --resource-group rg-robbedbyapplecare-prod \
  --account-name <storage_account> \
  --query "[1].value" -o tsv)

az keyvault secret set \
  --vault-name kv-robbedbyapplecare \
  --name "storage-account-key" \
  --value "$NEW_KEY"

# 4. Update Discourse configuration
ssh discourse-admin@<vm_ip>
cd /var/discourse

# Edit app.yml to use new key from Key Vault
sudo nano containers/app.yml

# 5. Restart Discourse with new configuration
sudo ./launcher rebuild app --skip-prereqs

# 6. Verify uploads work with new key
curl -f https://forum.robbedbyapplecare.com/srv/status

# 7. After verification, rotate primary key
az storage account keys renew \
  --resource-group rg-robbedbyapplecare-prod \
  --account-name <storage_account> \
  --key primary
```

#### OAuth Secret Rotation

**Google OAuth:**
```bash
# 1. Generate new client secret in Google Cloud Console
# 2. Update Key Vault
az keyvault secret set \
  --vault-name kv-robbedbyapplecare \
  --name "google-oauth-secret" \
  --value "<new_secret>"

# 3. Update Discourse OAuth settings
# Login to https://forum.robbedbyapplecare.com/admin/site_settings/category/login
# Update Google OAuth client secret

# 4. Test OAuth login flow
# 5. Revoke old secret in Google Cloud Console
```

**Facebook OAuth:**
```bash
# 1. Generate new app secret in Facebook Developers
# 2. Update Key Vault
az keyvault secret set \
  --vault-name kv-robbedbyapplecare \
  --name "facebook-oauth-secret" \
  --value "<new_secret>"

# 3. Update Discourse OAuth settings
# 4. Test OAuth login flow
# 5. Revoke old secret in Facebook Developers
```

#### Database Password Rotation

```bash
# 1. Generate new secure password
NEW_PASSWORD=$(openssl rand -base64 32)

# 2. Update PostgreSQL user password
az postgres flexible-server execute \
  --name psql-robbedbyapplecare \
  --admin-user postgres \
  --admin-password "<current_admin_password>" \
  --querytext "ALTER USER discourse_user PASSWORD '$NEW_PASSWORD';"

# 3. Update Key Vault
az keyvault secret set \
  --vault-name kv-robbedbyapplecare \
  --name "postgres-discourse-password" \
  --value "$NEW_PASSWORD"

# 4. Update Discourse configuration
ssh discourse-admin@<vm_ip>
cd /var/discourse
sudo nano containers/app.yml
# Update DISCOURSE_DB_PASSWORD with new password

# 5. Restart Discourse
sudo ./launcher rebuild app --skip-prereqs

# 6. Verify database connectivity
sudo ./launcher logs app | grep -i database
```

#### SSH Key Rotation

```bash
# 1. Generate new SSH key pair
ssh-keygen -t ed25519 -f ~/.ssh/discourse_new -C "discourse-admin@robbedbyapplecare.com"

# 2. Add new public key to VM
az vm user update \
  --resource-group rg-robbedbyapplecare-prod \
  --name vm-discourse \
  --username discourse-admin \
  --ssh-key-value "$(cat ~/.ssh/discourse_new.pub)"

# 3. Test new key
ssh -i ~/.ssh/discourse_new discourse-admin@<vm_ip> "echo 'New key works'"

# 4. Update GitHub secrets with new private key
# Go to GitHub repository → Settings → Secrets → Update SSH_PRIVATE_KEY

# 5. Remove old key from VM (after verification)
ssh -i ~/.ssh/discourse_new discourse-admin@<vm_ip>
sudo nano ~/.ssh/authorized_keys
# Remove old key entry

# 6. Update local SSH config
mv ~/.ssh/discourse_new ~/.ssh/discourse
mv ~/.ssh/discourse_new.pub ~/.ssh/discourse.pub
```

### Key Rotation Verification

**Post-Rotation Checklist:**
```bash
# 1. Verify all services are operational
curl -f https://www.robbedbyapplecare.com
curl -f https://forum.robbedbyapplecare.com/srv/status

# 2. Test OAuth login flows
# Manual test: Login with Google and Facebook

# 3. Test file uploads
# Manual test: Upload image in Discourse

# 4. Verify backups still work
ssh discourse-admin@<vm_ip>
cd /var/discourse
sudo ./launcher enter app
discourse backup --with-uploads

# 5. Check automated systems
sudo crontab -l
systemctl status backup-cron

# 6. Document rotation in security log
echo "$(date): Key rotation completed successfully" >> /var/log/security-operations.log
```

### Security Scanning

```bash
# Check security headers
curl -I https://www.robbedbyapplecare.com | grep -E "(CSP|HSTS|X-Frame)"

# SSL/TLS test
nmap --script ssl-enum-ciphers -p 443 www.robbedbyapplecare.com
```

## Performance Optimization

### Front Door Cache Management

```bash
# Purge Front Door cache
az afd endpoint purge \
  --resource-group rg-robbedbyapplecare-prod \
  --profile-name fd-robbedbyapplecare \
  --endpoint-name <endpoint-name> \
  --content-paths "/*"
```

### Discourse Performance

```bash
# Check Discourse performance
sudo docker exec -it discourse_app discourse doctor

# Rebuild search index (if needed)
sudo docker exec -it discourse_app discourse rebuild_search_index
```

## Troubleshooting

### Web Application Issues

**Symptom**: Site not loading
```bash
# Check Static Web App status
az staticwebapp show \
  --resource-group rg-robbedbyapplecare-prod \
  --name swa-robbedbyapplecare

# Check Front Door health
az afd profile show \
  --resource-group rg-robbedbyapplecare-prod \
  --profile-name fd-robbedbyapplecare
```

**Symptom**: Slow loading times
```bash
# Check Front Door analytics
az monitor metrics list \
  --resource /subscriptions/<sub-id>/resourceGroups/rg-robbedbyapplecare-prod/providers/Microsoft.Cdn/profiles/fd-robbedbyapplecare \
  --metric "ResponseTime"
```

### Discourse Issues

**Symptom**: Forum not accessible
```bash
# Check container status
ssh azureuser@<vm_ip>
sudo docker ps
sudo docker-compose logs discourse

# Check VM resources
top
df -h
```

**Symptom**: Database connection errors
```bash
# Check PostgreSQL status
az postgres flexible-server show \
  --resource-group rg-robbedbyapplecare-prod \
  --name psql-discourse

# Test connection from VM
ssh azureuser@<vm_ip>
telnet <postgres_fqdn> 5432
```

### DNS Issues

**Symptom**: Domain not resolving
```bash
# Check DNS configuration
nslookup www.robbedbyapplecare.com
dig www.robbedbyapplecare.com

# Check Azure DNS zone
az network dns zone show \
  --resource-group rg-robbedbyapplecare-prod \
  --name robbedbyapplecare.com
```

## Emergency Procedures

### Site Down - Critical

1. Check Azure Service Health
2. Verify Front Door status
3. Check Static Web App deployment status
4. If needed, rollback to previous deployment
5. Notify stakeholders

### Data Loss - Critical

1. Stop all write operations
2. Assess scope of data loss
3. Restore from most recent backup
4. Verify data integrity
5. Resume operations
6. Post-incident review

### Security Incident

1. Isolate affected systems
2. Preserve evidence
3. Assess impact
4. Apply security patches
5. Monitor for further compromise
6. Document incident

## Maintenance Windows

### Monthly Maintenance

- Update Discourse to latest version
- Review and rotate secrets
- Check backup integrity
- Review security logs
- Update documentation

### Quarterly Maintenance

- Review and update Terraform configurations
- Performance optimization review
- Security assessment
- Disaster recovery testing
- Cost optimization review

## Contact Information

- **Azure Support**: [Azure Support Portal]
- **Domain Registrar**: [Contact Info]
- **Emergency Contact**: [Emergency Contact]

## Useful Links

- [Azure Portal](https://portal.azure.com)
- [Discourse Admin](https://forum.robbedbyapplecare.com/admin)
- [GitHub Repository](https://github.com/your-org/robbed-by-apple-care)
- [Monitoring Dashboard](https://portal.azure.com/#@tenant/dashboard)