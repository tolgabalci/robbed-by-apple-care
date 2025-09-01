#!/bin/bash

# Discourse Embedding Configuration Script for RobbedByAppleCare
# This script configures Discourse embedding settings after initial setup
# Run with: ./configure-embedding.sh

set -euo pipefail

# Configuration
DISCOURSE_CONTAINER="discourse_app"
FORUM_DOMAIN="forum.robbedbyapplecare.com"
EMBED_DOMAIN="www.robbedbyapplecare.com"
LOG_FILE="/var/log/discourse-embedding.log"

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

# Check if Docker container is running
check_discourse_running() {
    if ! docker ps | grep -q "$DISCOURSE_CONTAINER"; then
        error "Discourse container '$DISCOURSE_CONTAINER' is not running"
    fi
    log "Discourse container is running"
}

# Wait for Discourse to be ready
wait_for_discourse() {
    log "Waiting for Discourse to be ready..."
    timeout=300
    counter=0
    
    while ! curl -f http://localhost/srv/status >/dev/null 2>&1; do
        if [ $counter -ge $timeout ]; then
            error "Discourse is not responding after $timeout seconds"
        fi
        sleep 10
        counter=$((counter + 10))
        log "Waiting for Discourse... ($counter/$timeout seconds)"
    done
    
    log "Discourse is ready!"
}

# Configure embedding settings
configure_embedding() {
    log "Configuring Discourse embedding settings..."
    
    docker exec "$DISCOURSE_CONTAINER" rails runner "
# Enable embedding functionality
SiteSetting.embed_any_origin = false
SiteSetting.embed_whitelist_selector = 'article'
SiteSetting.embed_post_limit = 100
SiteSetting.embed_truncate = true
SiteSetting.embed_whitelist = '$EMBED_DOMAIN'

# Configure CORS for embedding
SiteSetting.cors_origins = 'https://$EMBED_DOMAIN'

# Embedding display settings
SiteSetting.embed_classname_whitelist = 'discourse-embed-frame'

# Create or update the default category for embedded topics
category = Category.find_or_create_by(name: 'Article Discussions') do |c|
  c.description = 'Discussions from embedded article comments'
  c.color = '0088CC'
  c.text_color = 'FFFFFF'
  c.slug = 'article-discussions'
  c.position = 1
end

# Set the embed category
SiteSetting.embed_category_id = category.id

# Configure topic auto-creation
SiteSetting.embed_by_username = 'system'

puts 'Embedding configuration completed successfully!'
"
    
    if [ $? -eq 0 ]; then
        log "✅ Embedding settings configured successfully"
    else
        error "❌ Failed to configure embedding settings"
    fi
}

# Configure OAuth providers
configure_oauth() {
    log "Configuring OAuth providers..."
    
    docker exec "$DISCOURSE_CONTAINER" rails runner "
# Enable OAuth providers
SiteSetting.enable_google_oauth2_logins = true
SiteSetting.enable_facebook_logins = true

# OAuth settings
SiteSetting.google_oauth2_hd = ''  # Allow any Google domain
SiteSetting.facebook_request_extra_profile_details = true

puts 'OAuth providers configured successfully!'
"
    
    if [ $? -eq 0 ]; then
        log "✅ OAuth providers configured successfully"
    else
        warn "⚠️  OAuth provider configuration may have failed - check manually"
    fi
}

# Configure security and performance settings
configure_security() {
    log "Configuring security and performance settings..."
    
    docker exec "$DISCOURSE_CONTAINER" rails runner "
# Security settings
SiteSetting.force_https = true
SiteSetting.secure_media = true
SiteSetting.login_required = false
SiteSetting.must_approve_users = false
SiteSetting.enable_sso = false

# Performance settings
SiteSetting.max_image_size_kb = 10240
SiteSetting.max_attachment_size_kb = 10240
SiteSetting.clean_up_uploads = true
SiteSetting.clean_orphan_uploads_grace_period_hours = 48

# Rate limiting
SiteSetting.max_topics_per_day = 50
SiteSetting.max_posts_per_day = 200
SiteSetting.rate_limit_create_topic = 15
SiteSetting.rate_limit_create_post = 5

# Email settings
SiteSetting.notification_email = 'noreply@robbedbyapplecare.com'
SiteSetting.contact_email = 'admin@robbedbyapplecare.com'
SiteSetting.title = 'RobbedByAppleCare Community'
SiteSetting.site_description = 'Community discussion about AppleCare experiences and consumer rights'

# Forum behavior
SiteSetting.allow_uncategorized_topics = true
SiteSetting.default_trust_level = 1
SiteSetting.min_trust_to_create_topic = 1

puts 'Security and performance settings configured successfully!'
"
    
    if [ $? -eq 0 ]; then
        log "✅ Security and performance settings configured successfully"
    else
        warn "⚠️  Some security/performance settings may not have been applied"
    fi
}

# Test embedding functionality
test_embedding() {
    log "Testing embedding functionality..."
    
    # Test CORS headers
    cors_test=$(curl -s -H "Origin: https://$EMBED_DOMAIN" \
                     -H "Access-Control-Request-Method: GET" \
                     -H "Access-Control-Request-Headers: Content-Type" \
                     -X OPTIONS \
                     "http://localhost/embed/comments" \
                     -w "%{http_code}" -o /dev/null)
    
    if [ "$cors_test" = "200" ]; then
        log "✅ CORS configuration is working"
    else
        warn "⚠️  CORS test returned status: $cors_test"
    fi
    
    # Test embed endpoint
    embed_test=$(curl -s -w "%{http_code}" -o /dev/null "http://localhost/embed/comments?embed_url=https://$EMBED_DOMAIN/")
    
    if [ "$embed_test" = "200" ]; then
        log "✅ Embed endpoint is responding"
    else
        warn "⚠️  Embed endpoint test returned status: $embed_test"
    fi
}

# Create embedding test page
create_test_page() {
    log "Creating embedding test page..."
    
    cat > /tmp/embed-test.html << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Discourse Embed Test - RobbedByAppleCare</title>
    <link rel="canonical" href="https://$EMBED_DOMAIN/test-embed">
</head>
<body>
    <article>
        <h1>Test Article for Discourse Embedding</h1>
        <p>This is a test article to verify that Discourse embedding is working correctly.</p>
        <p>The comments section should appear below this content.</p>
    </article>
    
    <div id="discourse-comments"></div>
    
    <script type="text/javascript">
      DiscourseEmbed = { 
        discourseUrl: 'https://$FORUM_DOMAIN/',
        discourseEmbedUrl: 'https://$EMBED_DOMAIN/test-embed'
      };

      (function() {
        var d = document.createElement('script'); d.type = 'text/javascript'; d.async = true;
        d.src = DiscourseEmbed.discourseUrl + 'javascripts/embed.js';
        (document.getElementsByTagName('head')[0] || document.getElementsByTagName('body')[0]).appendChild(d);
      })();
    </script>
</body>
</html>
EOF
    
    log "Test page created at /tmp/embed-test.html"
    log "You can serve this file to test embedding functionality"
}

# Main execution
main() {
    log "Starting Discourse embedding configuration..."
    
    check_discourse_running
    wait_for_discourse
    configure_embedding
    configure_oauth
    configure_security
    test_embedding
    create_test_page
    
    log "🎉 Discourse embedding configuration completed!"
    log ""
    log "Next steps:"
    log "1. Verify embedding works by testing with the created test page"
    log "2. Update your main site to use the embed script"
    log "3. Test OAuth login functionality"
    log "4. Monitor logs for any issues: $LOG_FILE"
    log ""
    log "Embedding configuration:"
    log "- Whitelist domain: $EMBED_DOMAIN"
    log "- Forum URL: https://$FORUM_DOMAIN/"
    log "- Embed category: Article Discussions"
    log "- CORS enabled for: https://$EMBED_DOMAIN"
}

# Run main function
main "$@"