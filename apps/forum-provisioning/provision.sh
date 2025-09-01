#!/bin/bash

# Discourse Provisioning Script for RobbedByAppleCare
# This script sets up Discourse on an Azure Ubuntu VM
# Run with: sudo ./provision.sh

set -euo pipefail

# Configuration
DISCOURSE_DIR="/var/discourse"
FORUM_USER="discourse"
LOG_FILE="/var/log/discourse-provision.log"
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

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   error "This script must be run as root (use sudo)"
fi

log "Starting Discourse provisioning for RobbedByAppleCare..."

# Update system packages
log "Updating system packages..."
apt-get update -y
apt-get upgrade -y

# Install required packages
log "Installing required packages..."
apt-get install -y \
    curl \
    wget \
    git \
    docker.io \
    docker-compose \
    nginx \
    certbot \
    python3-certbot-nginx \
    jq \
    unzip \
    cron \
    logrotate \
    fail2ban \
    ufw

# Install Azure CLI
log "Installing Azure CLI..."
curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# Create discourse user
log "Creating discourse user..."
if ! id "$FORUM_USER" &>/dev/null; then
    useradd -m -s /bin/bash "$FORUM_USER"
    usermod -aG docker "$FORUM_USER"
fi

# Create discourse directory
log "Setting up Discourse directory..."
mkdir -p "$DISCOURSE_DIR"
mkdir -p "$DISCOURSE_DIR/shared/standalone/log"
mkdir -p "$DISCOURSE_DIR/containers"
chown -R "$FORUM_USER:$FORUM_USER" "$DISCOURSE_DIR"

# Start and enable Docker
log "Starting Docker service..."
systemctl start docker
systemctl enable docker

# Configure firewall
log "Configuring firewall..."
ufw --force enable
ufw allow ssh
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow from 10.0.0.0/8 to any port 5432  # PostgreSQL from VNet

# Configure fail2ban
log "Configuring fail2ban..."
cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[sshd]
enabled = true

[nginx-http-auth]
enabled = true

[nginx-limit-req]
enabled = true
EOF

systemctl enable fail2ban
systemctl start fail2ban

# Function to retrieve secrets from Azure Key Vault
get_secret() {
    local secret_name="$1"
    local secret_value
    
    log "Retrieving secret: $secret_name"
    
    # Authenticate using Managed Identity
    az login --identity --allow-no-subscriptions
    
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

# Create environment file with secrets from Key Vault
log "Creating environment configuration..."
cat > "$DISCOURSE_DIR/.env" << EOF
# PostgreSQL Configuration
POSTGRES_HOST=$(get_secret "postgres-host")
POSTGRES_PASSWORD=$(get_secret "postgres-password")

# Azure Blob Storage Configuration
STORAGE_ACCOUNT=$(get_secret "storage-account-name")
BLOB_ACCESS_KEY=$(get_secret "blob-access-key")
BLOB_SECRET_KEY=$(get_secret "blob-secret-key")

# SMTP Configuration
SMTP_HOST=$(get_secret "smtp-host")
SMTP_USERNAME=$(get_secret "smtp-username")
SMTP_PASSWORD=$(get_secret "smtp-password")

# Google OAuth Configuration
GOOGLE_CLIENT_ID=$(get_secret "google-client-id")
GOOGLE_CLIENT_SECRET=$(get_secret "google-client-secret")

# Facebook OAuth Configuration
FACEBOOK_APP_ID=$(get_secret "facebook-app-id")
FACEBOOK_APP_SECRET=$(get_secret "facebook-app-secret")

# CDN Configuration
CDN_HOSTNAME=$(get_secret "cdn-hostname")

# Security
DISCOURSE_SECRET_KEY_BASE=$(get_secret "discourse-secret-key-base")
EOF

chown "$FORUM_USER:$FORUM_USER" "$DISCOURSE_DIR/.env"
chmod 600 "$DISCOURSE_DIR/.env"

# Copy configuration files
log "Copying Discourse configuration files..."
cp app.yml "$DISCOURSE_DIR/containers/"
cp docker-compose.yml "$DISCOURSE_DIR/"
chown -R "$FORUM_USER:$FORUM_USER" "$DISCOURSE_DIR"

# Configure nginx as reverse proxy
log "Configuring nginx reverse proxy..."
cat > /etc/nginx/sites-available/discourse << 'EOF'
upstream discourse {
    server 127.0.0.1:80 fail_timeout=0;
}

server {
    listen 80;
    server_name forum.robbedbyapplecare.com;
    
    # Redirect HTTP to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name forum.robbedbyapplecare.com;
    
    # SSL configuration will be added by certbot
    
    # Security headers
    add_header X-Frame-Options SAMEORIGIN always;
    add_header X-Content-Type-Options nosniff always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    
    # CORS for embedding
    add_header Access-Control-Allow-Origin "https://www.robbedbyapplecare.com" always;
    add_header Access-Control-Allow-Methods "GET, POST, OPTIONS" always;
    add_header Access-Control-Allow-Headers "Content-Type, Authorization" always;
    
    # Rate limiting
    limit_req_zone $binary_remote_addr zone=discourse:10m rate=10r/s;
    limit_req zone=discourse burst=20 nodelay;
    
    # Client max body size for uploads
    client_max_body_size 10m;
    
    location / {
        proxy_pass http://discourse;
        proxy_set_header Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Frame-Options SAMEORIGIN;
        
        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
    
    # Health check endpoint
    location /srv/status {
        proxy_pass http://discourse;
        access_log off;
    }
    
    # Static assets caching
    location ~* \.(css|js|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        proxy_pass http://discourse;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
EOF

# Enable nginx site
ln -sf /etc/nginx/sites-available/discourse /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl enable nginx
systemctl restart nginx

# Create systemd service for Discourse
log "Creating Discourse systemd service..."
cat > /etc/systemd/system/discourse.service << EOF
[Unit]
Description=Discourse Forum
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=$DISCOURSE_DIR
ExecStart=/usr/bin/docker-compose up -d
ExecStop=/usr/bin/docker-compose down
ExecReload=/usr/bin/docker-compose restart
User=$FORUM_USER
Group=$FORUM_USER

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable discourse

# Start Discourse
log "Starting Discourse..."
cd "$DISCOURSE_DIR"
sudo -u "$FORUM_USER" docker-compose up -d

# Wait for Discourse to be ready
log "Waiting for Discourse to be ready..."
timeout=300
counter=0
while ! curl -f http://localhost/srv/status >/dev/null 2>&1; do
    if [ $counter -ge $timeout ]; then
        error "Discourse failed to start within $timeout seconds"
    fi
    sleep 10
    counter=$((counter + 10))
    log "Waiting for Discourse... ($counter/$timeout seconds)"
done

log "Discourse is ready!"

# Create admin user
log "Creating admin user..."
ADMIN_EMAIL="admin@robbedbyapplecare.com"
ADMIN_USERNAME="admin"
ADMIN_PASSWORD="$(openssl rand -base64 32)"

# Store admin password in Key Vault for security
log "Storing admin password in Key Vault..."
az keyvault secret set \
    --vault-name "$AZURE_KEYVAULT_NAME" \
    --name "discourse-admin-password" \
    --value "$ADMIN_PASSWORD" \
    --output none

# Create admin user using Rails console
sudo -u "$FORUM_USER" docker exec discourse_app rails runner "
begin
  # Check if admin user already exists
  admin_user = User.find_by(email: '$ADMIN_EMAIL')
  
  if admin_user.nil?
    # Create new admin user
    admin_user = User.create!(
      email: '$ADMIN_EMAIL',
      username: '$ADMIN_USERNAME',
      name: 'RobbedByAppleCare Admin',
      password: '$ADMIN_PASSWORD',
      active: true,
      approved: true,
      trust_level: 4,
      admin: true,
      moderator: true
    )
    
    # Activate the user
    admin_user.activate
    
    puts 'Admin user created successfully!'
    puts 'Email: $ADMIN_EMAIL'
    puts 'Username: $ADMIN_USERNAME'
    puts 'Password stored in Key Vault: discourse-admin-password'
  else
    puts 'Admin user already exists, skipping creation'
  end
rescue => e
  puts \"Error creating admin user: #{e.message}\"
  exit 1
end
"

# Run embedding configuration script
log "Running embedding configuration..."
if [ -f "./configure-embedding.sh" ]; then
    chmod +x ./configure-embedding.sh
    ./configure-embedding.sh
else
    warn "configure-embedding.sh not found, running inline configuration..."
    
    # Fallback inline configuration
    sudo -u "$FORUM_USER" docker exec discourse_app rails runner "
    # Enable embedding
    SiteSetting.embed_any_origin = false
    SiteSetting.embed_whitelist_selector = 'article'
    SiteSetting.embed_post_limit = 100
    SiteSetting.embed_truncate = true
    SiteSetting.embed_whitelist = 'www.robbedbyapplecare.com'

    # Configure CORS
    SiteSetting.cors_origins = 'https://www.robbedbyapplecare.com'

    # OAuth settings
    SiteSetting.enable_google_oauth2_logins = true
    SiteSetting.enable_facebook_logins = true

    # Security settings
    SiteSetting.force_https = true
    SiteSetting.secure_media = true
    SiteSetting.login_required = false
    SiteSetting.must_approve_users = false

    # Email settings
    SiteSetting.notification_email = 'noreply@robbedbyapplecare.com'
    SiteSetting.contact_email = 'admin@robbedbyapplecare.com'

    # Forum settings
    SiteSetting.title = 'RobbedByAppleCare Community'
    SiteSetting.site_description = 'Community discussion about AppleCare experiences and consumer rights'
    SiteSetting.allow_uncategorized_topics = true

    # Create default category for embedded topics
    category = Category.find_or_create_by(name: 'Article Discussions') do |c|
      c.description = 'Discussions from embedded article comments'
      c.color = '0088CC'
      c.text_color = 'FFFFFF'
    end

    SiteSetting.embed_category_id = category.id

    puts 'Embedding configuration completed!'
    "
fi

# Obtain SSL certificate
log "Obtaining SSL certificate..."
certbot --nginx -d forum.robbedbyapplecare.com --non-interactive --agree-tos --email admin@robbedbyapplecare.com

# Set up certificate renewal
log "Setting up certificate renewal..."
echo "0 12 * * * /usr/bin/certbot renew --quiet" | crontab -

# Configure log rotation
log "Configuring log rotation..."
cat > /etc/logrotate.d/discourse << 'EOF'
/var/discourse/shared/standalone/log/*.log {
    daily
    missingok
    rotate 52
    compress
    delaycompress
    notifempty
    create 644 discourse discourse
    postrotate
        docker exec discourse_app sv restart unicorn
    endscript
}
EOF

# Create health check script
log "Creating health check script..."
cat > /usr/local/bin/discourse-health-check.sh << 'EOF'
#!/bin/bash

# Health check script for Discourse
LOG_FILE="/var/log/discourse-health.log"

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Check if Discourse is responding
if ! curl -f http://localhost/srv/status >/dev/null 2>&1; then
    log "Discourse health check failed, attempting restart..."
    systemctl restart discourse
    
    # Wait and check again
    sleep 30
    if ! curl -f http://localhost/srv/status >/dev/null 2>&1; then
        log "Discourse restart failed, manual intervention required"
        # Could send alert here
    else
        log "Discourse successfully restarted"
    fi
else
    log "Discourse health check passed"
fi
EOF

chmod +x /usr/local/bin/discourse-health-check.sh

# Add health check to cron
echo "*/5 * * * * /usr/local/bin/discourse-health-check.sh" | crontab -

# Setup automation (backup, monitoring, maintenance)
log "Setting up automation and monitoring..."
if [[ -f "./setup-automation.sh" ]]; then
    chmod +x ./setup-automation.sh
    ./setup-automation.sh
else
    warn "setup-automation.sh not found, skipping automation setup"
fi

# Final status check
log "Performing final status check..."
if curl -f http://localhost/srv/status >/dev/null 2>&1; then
    log "✅ Discourse provisioning completed successfully!"
    log ""
    log "🌐 Forum Access:"
    log "   - Forum URL: https://forum.robbedbyapplecare.com"
    log "   - Admin panel: https://forum.robbedbyapplecare.com/admin"
    log "   - Health check: https://forum.robbedbyapplecare.com/srv/status"
    log ""
    log "👤 Admin Credentials:"
    log "   - Email: admin@robbedbyapplecare.com"
    log "   - Username: admin"
    log "   - Password: Stored in Azure Key Vault (discourse-admin-password)"
    log "   - Retrieve with: az keyvault secret show --vault-name $AZURE_KEYVAULT_NAME --name discourse-admin-password --query value -o tsv"
    log ""
    log "🔗 Embedding Configuration:"
    log "   - Whitelist domain: www.robbedbyapplecare.com"
    log "   - Embed category: Article Discussions"
    log "   - CORS enabled for: https://www.robbedbyapplecare.com"
    log ""
    log "🔧 Automation & Monitoring:"
    log "   - Nightly backups: 2:00 AM daily"
    log "   - Health monitoring: Every 5 minutes"
    log "   - Weekly maintenance: Sundays at 3:00 AM"
    log "   - Dashboard: discourse-dashboard command"
    log ""
    log "📋 Next Steps:"
    log "   1. Test embedding functionality with the test page"
    log "   2. Configure OAuth apps in Google and Facebook consoles"
    log "   3. Update OAuth secrets in Key Vault"
    log "   4. Test the complete user flow"
    log "   5. Monitor automation logs in /var/log/discourse-*.log"
else
    error "❌ Discourse provisioning failed - service is not responding"
fi

log "Provisioning completed. Check logs at: $LOG_FILE"