# Discourse Docker Configuration for RobbedByAppleCare

This directory contains the Docker configuration for running Discourse forum at `forum.robbedbyapplecare.com`.

## Files

- `app.yml` - Main Discourse configuration with PostgreSQL, Blob storage, OAuth, and SMTP
- `docker-compose.yml` - Docker Compose configuration for local development and production
- `.env.template` - Environment variables template (copy to `.env` and fill in values)
- `provision.sh` - Automated provisioning script for VM deployment
- `configure-embedding.sh` - Script to configure Discourse embedding settings
- `restart-discourse.sh` - Script for restarting and managing Discourse service
- `backup-cron.sh` - Automated backup script for production (to be implemented)

## Configuration Features

### Database & Storage
- Azure Database for PostgreSQL Flexible Server integration
- Azure Blob Storage for file uploads (S3-compatible)
- Redis for caching and background jobs

### Authentication
- Google OAuth2 login
- Facebook OAuth login
- Email/password authentication

### Email
- SMTP configuration for notifications
- Support for Azure Communication Services or SendGrid

### Security
- HTTPS enforcement
- CORS configuration for embedding
- Secure media handling
- Rate limiting

### Embedding
- Configured for embedding on www.robbedbyapplecare.com
- Automatic topic creation for embedded pages
- Whitelist-based security

## Environment Variables

Copy `.env.template` to `.env` and configure:

```bash
cp .env.template .env
# Edit .env with your actual values
```

Required variables:
- `POSTGRES_HOST` - Azure PostgreSQL server hostname
- `POSTGRES_PASSWORD` - Database password
- `STORAGE_ACCOUNT` - Azure Storage Account name
- `BLOB_ACCESS_KEY` - Storage access key
- `BLOB_SECRET_KEY` - Storage secret key
- `SMTP_*` - Email configuration
- `GOOGLE_CLIENT_ID/SECRET` - Google OAuth credentials
- `FACEBOOK_APP_ID/SECRET` - Facebook OAuth credentials

## Local Development

```bash
# Start services
docker-compose up -d

# View logs
docker-compose logs -f discourse

# Stop services
docker-compose down
```

## Production Deployment

Use the `provision.sh` script for automated VM deployment:

```bash
# Run on Azure VM (requires Azure CLI and Managed Identity)
sudo ./provision.sh
```

The provisioning script will:
1. Install Docker and required system packages
2. Configure firewall and security settings
3. Retrieve secrets from Azure Key Vault
4. Set up Discourse with proper configuration
5. Create admin user with secure password
6. Configure embedding settings for www.robbedbyapplecare.com
7. Set up SSL certificates and nginx reverse proxy
8. Configure health checks and monitoring

### Post-Deployment Configuration

After provisioning, configure OAuth applications:

1. **Google OAuth Setup**:
   - Go to [Google Cloud Console](https://console.cloud.google.com/)
   - Create OAuth 2.0 credentials
   - Add redirect URI: `https://forum.robbedbyapplecare.com/auth/google_oauth2/callback`
   - Update Key Vault with client ID and secret

2. **Facebook OAuth Setup**:
   - Go to [Facebook Developers](https://developers.facebook.com/)
   - Create Facebook App
   - Add redirect URI: `https://forum.robbedbyapplecare.com/auth/facebook/callback`
   - Update Key Vault with app ID and secret

### Embedding Configuration

Run the embedding configuration script to set up forum embedding:

```bash
# Configure embedding settings
sudo ./configure-embedding.sh
```

This script configures:
- Whitelist for www.robbedbyapplecare.com
- CORS headers for cross-origin requests
- Default category for embedded topics
- OAuth provider settings

## Maintenance & Operations

### Service Management

Use the `restart-discourse.sh` script for service management:

```bash
# Restart Discourse (graceful)
sudo ./restart-discourse.sh restart

# Start Discourse
sudo ./restart-discourse.sh start

# Stop Discourse
sudo ./restart-discourse.sh stop

# Update to latest version
sudo ./restart-discourse.sh update

# Check status and health
sudo ./restart-discourse.sh status

# View logs
sudo ./restart-discourse.sh logs
```

### Admin Access

Admin credentials are automatically generated and stored securely:

```bash
# Retrieve admin password from Key Vault
az keyvault secret show --vault-name robbedbyapplecare-kv --name discourse-admin-password --query value -o tsv

# Admin login details:
# Email: admin@robbedbyapplecare.com
# Username: admin
# Password: (from Key Vault)
```

### Backup & Maintenance

Automated backups will be configured via `backup-cron.sh` (implemented in task 7.3):

```bash
# Install backup cron job (after implementing backup script)
sudo crontab -e
# Add: 0 2 * * * /path/to/backup-cron.sh
```

## Health Checks

The configuration includes health checks for both Discourse and Redis:

```bash
# Check Discourse health
curl -f http://localhost/srv/status

# Check Redis health
docker exec discourse_redis redis-cli ping
```

## Troubleshooting

### Common Issues

1. **Database Connection**: Verify PostgreSQL credentials and network access
2. **Blob Storage**: Check Azure Storage Account keys and permissions
3. **OAuth**: Verify redirect URIs in Google/Facebook app configurations
4. **SMTP**: Test email configuration with provider

### Logs

```bash
# Discourse application logs
docker-compose logs discourse

# System logs
tail -f logs/production.log

# Redis logs
docker-compose logs redis
```

### Rebuilding

If configuration changes require a rebuild:

```bash
# Stop and remove containers
docker-compose down

# Rebuild Discourse
docker-compose up --build -d
```

## Security Notes

- All secrets should be stored in Azure Key Vault in production
- The `.env` file should never be committed to version control
- Regular security updates should be applied via the maintenance scripts
- Monitor logs for suspicious activity

## Support

For Discourse-specific issues, refer to:
- [Discourse Docker Documentation](https://github.com/discourse/discourse_docker)
- [Discourse Meta Community](https://meta.discourse.org/)