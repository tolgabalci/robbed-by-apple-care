# Discourse Automation Documentation

This document describes the automated backup, monitoring, maintenance, and deployment systems for the RobbedByAppleCare Discourse forum.

## Overview

The automation system consists of several components:

- **Deployment Automation**: Automated configuration deployment via GitHub Actions and manual scripts
- **Backup System**: Automated nightly backups to Azure Blob Storage
- **Health Monitoring**: Continuous health checks with automatic recovery
- **Maintenance Tasks**: Scheduled system maintenance and updates
- **Monitoring Dashboard**: Real-time status overview

> **Note**: For detailed deployment automation documentation, see [DEPLOYMENT.md](./DEPLOYMENT.md)

## Components

### 1. Deployment Automation

**Purpose**: Automated deployment of Discourse configuration changes and updates.

**Components**:
- **GitHub Actions Workflow** (`.github/workflows/discourse-deploy.yml`): Automated deployment triggered by code changes
- **Manual Deployment Script** (`deploy-discourse.sh`): Direct server management and troubleshooting
- **Health Verification**: Comprehensive post-deployment health checks
- **Automatic Rollback**: Failed deployments automatically rollback to previous configuration

**Deployment Types**:
- `config-update`: Update configuration files and reload Discourse
- `full-restart`: Deploy configuration and perform full restart
- `update-discourse`: Update Discourse to latest version
- `emergency-restart`: Emergency restart without configuration changes

**Manual Usage**:
```bash
# Full deployment with backup
sudo ./deploy-discourse.sh deploy --backup

# Configuration update only
sudo ./deploy-discourse.sh config-only

# Health check
sudo ./deploy-discourse.sh health-check --verbose

# Rollback to previous configuration
sudo ./deploy-discourse.sh rollback
```

**GitHub Actions Usage**:
1. Push changes to `apps/forum-provisioning/**` on main branch (automatic)
2. Manual dispatch from GitHub Actions tab with deployment type selection

### 2. Backup System (`backup-cron.sh`)

**Purpose**: Creates comprehensive backups of Discourse data and uploads them to Azure Blob Storage.

**Schedule**: Daily at 2:00 AM

**What it backs up**:
- Discourse application data (using built-in backup system)
- PostgreSQL database dump
- Configuration files (app.yml, docker-compose.yml, .env, nginx config)

**Features**:
- Automatic cleanup of old backups (30-day retention)
- Backup integrity verification
- Upload to Azure Blob Storage with organized folder structure
- Comprehensive logging and error handling

**Manual Usage**:
```bash
sudo /usr/local/bin/discourse-backup
# or
sudo /usr/local/bin/discourse/backup-cron.sh
```

### 3. Health Monitoring (`health-monitor.sh`)

**Purpose**: Continuously monitors Discourse health and performs automatic recovery.

**Schedule**: Every 5 minutes

**Health Checks**:
- Container status
- HTTP health endpoint
- Database connectivity
- Redis connectivity
- System resources (disk, memory)
- Container resource usage

**Recovery Actions**:
- Automatic restart on critical failures
- Restart cooldown to prevent restart loops
- Maximum restart attempts with manual intervention alerts
- Diagnostic information collection

**Manual Usage**:
```bash
sudo /usr/local/bin/discourse-health
# or
sudo /usr/local/bin/discourse/health-monitor.sh
```

### 4. Maintenance System (`maintenance.sh`)

**Purpose**: Performs routine maintenance tasks to keep the system healthy.

**Scheduled Tasks**:
- **Weekly Full Maintenance**: Sundays at 3:00 AM
- **Daily Cleanup**: 1:00 AM daily
- **Monthly Security Updates**: First Sunday at 4:00 AM

**Available Commands**:
```bash
sudo discourse-maintenance update          # Update Discourse
sudo discourse-maintenance rebuild         # Full rebuild
sudo discourse-maintenance cleanup         # Clean up resources
sudo discourse-maintenance optimize-db     # Database optimization
sudo discourse-maintenance update-ssl      # Update SSL certificates
sudo discourse-maintenance update-system   # Update system packages
sudo discourse-maintenance fix-permissions # Fix file permissions
sudo discourse-maintenance security-update # Security updates
sudo discourse-maintenance report          # Generate status report
sudo discourse-maintenance full            # Run all tasks
```

### 5. Setup Script (`setup-automation.sh`)

**Purpose**: Installs and configures all automation components.

**What it sets up**:
- Copies scripts to system locations
- Creates cron jobs
- Sets up systemd services and timers
- Configures log rotation
- Creates Azure Blob Storage container
- Installs monitoring dependencies

**Usage** (run once during provisioning):
```bash
sudo ./setup-automation.sh
```

## Monitoring and Logs

### Log Files

All automation activities are logged to dedicated files:

- `/var/log/discourse-backup.log` - Backup operations
- `/var/log/discourse-health.log` - Health monitoring
- `/var/log/discourse-maintenance.log` - Maintenance tasks
- `/var/log/discourse-alerts.log` - Critical alerts
- `/var/log/discourse-automation-setup.log` - Setup activities

### Monitoring Dashboard

View real-time status with the monitoring dashboard:

```bash
discourse-dashboard
```

This shows:
- Service status (Discourse, Nginx, Docker)
- Container status
- Resource usage (memory, disk, load)
- Recent activity (backups, health checks)
- Recent alerts

### Systemd Services

The automation uses both cron jobs and systemd timers:

```bash
# Check timer status
systemctl list-timers discourse-*

# Check service status
systemctl status discourse-health-monitor.timer
systemctl status discourse-backup.timer

# View service logs
journalctl -u discourse-health-monitor.service
journalctl -u discourse-backup.service
```

## Backup and Recovery

### Backup Storage

Backups are stored in Azure Blob Storage with the following structure:

```
discourse-backups/
├── 2024/
│   ├── 01/
│   │   ├── discourse-backup-20240115-020001.tar.gz
│   │   ├── postgres-20240115-020001.sql.gz
│   │   └── config-20240115-020001.tar.gz
│   └── 02/
│       └── ...
└── 2024/
    └── ...
```

### Recovery Procedures

1. **Restore from Discourse Backup**:
   ```bash
   # Download backup from blob storage
   az storage blob download --account-name <storage> --container discourse-backups --name <backup-file> --file /tmp/backup.tar.gz
   
   # Restore using Discourse
   docker exec discourse_app discourse restore <backup-name>
   ```

2. **Restore Database**:
   ```bash
   # Download database backup
   az storage blob download --account-name <storage> --container discourse-backups --name <db-backup> --file /tmp/db-backup.sql.gz
   
   # Restore database
   zcat /tmp/db-backup.sql.gz | PGPASSWORD=<password> psql -h <host> -U discourse_user -d discourse_production
   ```

3. **Restore Configuration**:
   ```bash
   # Download config backup
   az storage blob download --account-name <storage> --container discourse-backups --name <config-backup> --file /tmp/config.tar.gz
   
   # Extract configuration
   tar -xzf /tmp/config.tar.gz -C /var/discourse/
   ```

## Troubleshooting

### Common Issues

1. **Backup Failures**:
   - Check Azure credentials in Key Vault
   - Verify blob storage container exists
   - Check disk space for local backups
   - Review backup logs for specific errors

2. **Health Monitor False Positives**:
   - Adjust health check timeouts in script
   - Check network connectivity
   - Verify Discourse is actually running

3. **Maintenance Script Failures**:
   - Check system resources (disk space, memory)
   - Verify Docker service is running
   - Check for conflicting processes

### Manual Intervention

If automatic recovery fails:

1. **Check Service Status**:
   ```bash
   discourse-dashboard
   systemctl status discourse
   docker ps -a
   ```

2. **Manual Restart**:
   ```bash
   sudo discourse-restart restart
   ```

3. **Check Logs**:
   ```bash
   tail -f /var/log/discourse-*.log
   docker logs discourse_app
   ```

4. **Emergency Recovery**:
   ```bash
   # Stop all services
   sudo discourse-restart stop
   
   # Check system resources
   df -h
   free -h
   
   # Restart services
   sudo discourse-restart start
   ```

## Configuration

### Environment Variables

The scripts use these environment variables:

- `AZURE_KEYVAULT_NAME`: Name of the Azure Key Vault (default: robbedbyapplecare-kv)

### Customization

To customize the automation:

1. **Backup Retention**: Edit `RETENTION_DAYS` in `backup-cron.sh`
2. **Health Check Frequency**: Modify cron schedule in `/etc/cron.d/discourse-automation`
3. **Restart Limits**: Adjust `MAX_RESTART_ATTEMPTS` in `health-monitor.sh`
4. **Maintenance Schedule**: Update cron jobs for different timing

### Security

- All scripts run as root for system access
- Azure authentication uses Managed Identity
- Secrets are stored in Azure Key Vault
- Log files have restricted permissions
- Backup files are encrypted in transit and at rest

## Integration with Infrastructure

The automation system integrates with:

- **Azure Key Vault**: For secret management
- **Azure Blob Storage**: For backup storage
- **Azure Managed Identity**: For authentication
- **Systemd**: For service management
- **Cron**: For scheduling
- **Docker**: For container management
- **Nginx**: For web server management

This automation ensures the Discourse forum remains healthy, backed up, and maintained with minimal manual intervention.