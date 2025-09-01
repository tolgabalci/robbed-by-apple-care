# Discourse Deployment Automation

This document describes the automated deployment system for the RobbedByAppleCare Discourse forum, including both GitHub Actions workflows and manual deployment tools.

## Overview

The deployment system provides multiple ways to deploy and manage Discourse:

1. **Automated GitHub Actions** - Triggered by code changes or manual dispatch
2. **Manual Deployment Script** - For direct server management and troubleshooting
3. **Health Monitoring** - Continuous monitoring and automatic recovery

## GitHub Actions Workflow

### Workflow File
`.github/workflows/discourse-deploy.yml`

### Triggers

The workflow is triggered by:
- **Push to main branch** with changes in `apps/forum-provisioning/**`
- **Pull requests** with changes in `apps/forum-provisioning/**` (validation only)
- **Manual dispatch** with deployment type selection

### Deployment Types

When manually triggering the workflow, you can select:

- **config-update** (default) - Update configuration files and reload Discourse
- **full-restart** - Deploy configuration and perform full restart
- **update-discourse** - Update Discourse to latest version
- **emergency-restart** - Emergency restart without configuration changes

### Workflow Jobs

#### 1. validate-config
- Validates shell script syntax
- Validates Docker Compose configuration
- Validates Discourse app.yml YAML syntax

#### 2. deploy-discourse
- Gets VM information from Azure
- Establishes SSH connection to Discourse VM
- Uploads configuration files
- Executes deployment based on selected type
- Performs cleanup

#### 3. health-check
- Waits for service stabilization
- Performs comprehensive health checks:
  - Container status
  - Health endpoint
  - External accessibility
  - Database connectivity
  - Redis connectivity
  - SSL certificate validation
  - Embedding configuration
- Runs performance tests
- Collects deployment logs

#### 4. rollback (on failure)
- Automatically triggered if deployment or health checks fail
- Restores previous configuration from backup
- Attempts service restart

#### 5. notify
- Sends deployment status notifications
- Updates GitHub step summary with results

### Required Secrets

The workflow requires these GitHub secrets:

```bash
AZURE_CREDENTIALS              # Azure service principal credentials
AZURE_RESOURCE_GROUP          # Resource group containing the VM
DISCOURSE_VM_SSH_KEY          # Private SSH key for VM access
```

### Example Usage

#### Automatic Deployment
```bash
# Push changes to trigger automatic deployment
git add apps/forum-provisioning/
git commit -m "Update Discourse configuration"
git push origin main
```

#### Manual Deployment
1. Go to GitHub Actions tab
2. Select "Deploy Discourse Configuration" workflow
3. Click "Run workflow"
4. Select deployment type and options
5. Click "Run workflow"

## Manual Deployment Script

### Script Location
`apps/forum-provisioning/deploy-discourse.sh`

### Prerequisites

- Must be run as root or with sudo
- Docker service must be running
- Discourse directory must exist (`/var/discourse`)
- Configuration files must be present in script directory

### Commands

#### Deploy Configuration
```bash
# Full deployment with backup
sudo ./deploy-discourse.sh deploy --backup

# Preview changes without executing
sudo ./deploy-discourse.sh deploy --dry-run

# Force deployment
sudo ./deploy-discourse.sh deploy --force
```

#### Configuration Only
```bash
# Update configuration without restart
sudo ./deploy-discourse.sh config-only

# Preview configuration changes
sudo ./deploy-discourse.sh config-only --dry-run
```

#### Service Management
```bash
# Restart Discourse
sudo ./deploy-discourse.sh restart

# Update to latest version
sudo ./deploy-discourse.sh update --backup

# Show current status
sudo ./deploy-discourse.sh status

# Show recent logs
sudo ./deploy-discourse.sh logs
```

#### Health Monitoring
```bash
# Basic health check
sudo ./deploy-discourse.sh health-check

# Detailed health check
sudo ./deploy-discourse.sh health-check --verbose
```

#### Backup and Recovery
```bash
# Create manual backup
sudo ./deploy-discourse.sh backup

# Rollback to previous configuration
sudo ./deploy-discourse.sh rollback
```

### Script Options

- `--dry-run` - Preview changes without executing
- `--verbose` - Enable detailed output
- `--force` - Force operation even if checks fail
- `--backup` - Create backup before deployment

## Health Monitoring System

### Automated Health Checks

The deployment system includes comprehensive health monitoring:

1. **Container Status** - Verifies Discourse container is running
2. **Health Endpoint** - Tests `/srv/status` endpoint
3. **External Access** - Verifies forum accessibility from internet
4. **Database Connectivity** - Tests PostgreSQL connection
5. **Redis Connectivity** - Tests Redis connection
6. **SSL Certificate** - Validates certificate status
7. **Embedding Config** - Verifies embedding whitelist settings

### Health Check Scoring

- **Healthy** (7/7 checks pass) - All systems operational
- **Degraded** (5-6/7 checks pass) - Some issues detected
- **Critical** (0-4/7 checks pass) - Major issues, automatic restart triggered

### Automatic Recovery

The system includes automatic recovery mechanisms:

1. **Health Monitoring** - Continuous monitoring via cron job
2. **Automatic Restart** - Failed health checks trigger restart
3. **Rollback on Failure** - Failed deployments automatically rollback
4. **Cooldown Periods** - Prevents restart loops

## Configuration Files

### Key Files

- `app.yml` - Main Discourse configuration
- `docker-compose.yml` - Container orchestration
- `provision.sh` - Initial server setup
- `restart-discourse.sh` - Service restart script
- `health-monitor.sh` - Health monitoring script
- `backup-cron.sh` - Backup automation

### Configuration Management

1. **Version Control** - All configurations stored in Git
2. **Validation** - Syntax validation before deployment
3. **Backup** - Automatic backup before changes
4. **Rollback** - Easy rollback to previous versions

## Troubleshooting

### Common Issues

#### SSH Connection Failed
```bash
# Check VM status
az vm list --resource-group <resource-group> --output table

# Verify SSH key
ssh-keygen -l -f ~/.ssh/discourse_key

# Test SSH connection
ssh -i ~/.ssh/discourse_key azureuser@<vm-ip> "echo 'Connection test'"
```

#### Health Check Failed
```bash
# Run detailed health check
sudo ./deploy-discourse.sh health-check --verbose

# Check container logs
sudo ./deploy-discourse.sh logs

# Check service status
sudo ./deploy-discourse.sh status
```

#### Deployment Failed
```bash
# Check recent logs
sudo journalctl -u discourse --no-pager --lines=50

# Verify configuration
sudo ./deploy-discourse.sh config-only --dry-run

# Manual rollback
sudo ./deploy-discourse.sh rollback
```

### Emergency Procedures

#### Emergency Restart
```bash
# Via GitHub Actions
# 1. Go to Actions tab
# 2. Run "Deploy Discourse Configuration"
# 3. Select "emergency-restart"

# Via manual script
sudo ./deploy-discourse.sh restart --force
```

#### Manual Recovery
```bash
# Stop Discourse
cd /var/discourse
sudo docker-compose down

# Check system resources
df -h
free -h
docker system df

# Start Discourse
sudo docker-compose up -d

# Monitor startup
sudo docker logs discourse_app -f
```

## Monitoring and Alerting

### Log Files

- `/var/log/discourse-deploy.log` - Deployment logs
- `/var/log/discourse-health.log` - Health monitoring logs
- `/var/log/discourse-alerts.log` - Alert notifications

### Monitoring Commands

```bash
# Watch deployment logs
tail -f /var/log/discourse-deploy.log

# Check health status
sudo ./deploy-discourse.sh health-check

# Monitor container resources
docker stats discourse_app

# Check system resources
htop
iotop
```

### Performance Monitoring

The system monitors:
- Response time (target: <5 seconds)
- CPU usage (alert: >90%)
- Memory usage (alert: >90%)
- Disk usage (alert: >80%, critical: >90%)

## Security Considerations

### SSH Security
- SSH keys stored as GitHub secrets
- Key rotation procedures documented
- Connection timeouts configured
- Host key verification enabled

### Configuration Security
- Sensitive values stored in Azure Key Vault
- Environment files have restricted permissions (600)
- Backup files exclude sensitive data
- Audit logging enabled

### Network Security
- SSH access restricted to deployment systems
- Health checks use internal endpoints when possible
- SSL/TLS enforced for all external connections
- Firewall rules limit exposed ports

## Maintenance

### Regular Tasks

1. **Weekly** - Review deployment logs and health metrics
2. **Monthly** - Update Discourse to latest stable version
3. **Quarterly** - Rotate SSH keys and secrets
4. **Annually** - Review and update security configurations

### Update Procedures

#### Discourse Updates
```bash
# Automated via GitHub Actions
# 1. Go to Actions tab
# 2. Run "Deploy Discourse Configuration"
# 3. Select "update-discourse"

# Manual update
sudo ./deploy-discourse.sh update --backup
```

#### Configuration Updates
```bash
# Edit configuration files
vim apps/forum-provisioning/app.yml

# Commit and push changes
git add apps/forum-provisioning/
git commit -m "Update Discourse configuration"
git push origin main

# Automatic deployment will trigger
```

## Support

### Getting Help

1. **Check Logs** - Review deployment and health logs
2. **Run Diagnostics** - Use health check with verbose output
3. **Review Documentation** - Check this guide and runbook
4. **Manual Intervention** - Use deployment script for direct control

### Contact Information

- **Repository Issues** - Create GitHub issue for bugs/features
- **Emergency Contact** - Use emergency restart procedures
- **Documentation** - Update this file for new procedures

---

This deployment system provides robust, automated management of the Discourse forum with comprehensive monitoring, health checks, and recovery mechanisms.