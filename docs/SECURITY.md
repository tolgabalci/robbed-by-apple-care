# Security Guide

This document outlines the security measures implemented in the RobbedByAppleCare project and provides guidance for maintaining security.

## Security Architecture

### Defense in Depth

The project implements multiple layers of security:

1. **Network Security**: Azure Front Door with WAF
2. **Application Security**: Security headers and CSP
3. **Infrastructure Security**: Network Security Groups and private networking
4. **Data Security**: Encryption at rest and in transit
5. **Identity Security**: Managed identities and Key Vault

## Web Application Security

### Security Headers Configuration

The following security headers are implemented in Next.js to protect against common web vulnerabilities:

#### Complete Security Headers Implementation

```javascript
// next.config.js security headers configuration
const securityHeaders = [
  {
    key: 'Content-Security-Policy',
    value: [
      "default-src 'self'",
      "img-src 'self' data: https://*.blob.core.windows.net https://www.gravatar.com https://avatars.discourse-cdn.com",
      "script-src 'self' 'unsafe-inline' 'unsafe-eval' https://forum.robbedbyapplecare.com https://www.googletagmanager.com",
      "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com",
      "font-src 'self' https://fonts.gstatic.com",
      "connect-src 'self' https://forum.robbedbyapplecare.com https://www.google-analytics.com",
      "frame-src 'none'",
      "frame-ancestors 'none'",
      "base-uri 'self'",
      "form-action 'self'",
      "object-src 'none'",
      "media-src 'self'",
      "worker-src 'self'",
      "manifest-src 'self'",
      "upgrade-insecure-requests"
    ].join('; ')
  },
  {
    key: 'Strict-Transport-Security',
    value: 'max-age=31536000; includeSubDomains; preload'
  },
  {
    key: 'X-Frame-Options',
    value: 'DENY'
  },
  {
    key: 'X-Content-Type-Options',
    value: 'nosniff'
  },
  {
    key: 'X-DNS-Prefetch-Control',
    value: 'on'
  },
  {
    key: 'Referrer-Policy',
    value: 'strict-origin-when-cross-origin'
  },
  {
    key: 'Permissions-Policy',
    value: 'camera=(), microphone=(), geolocation=(), interest-cohort=()'
  },
  {
    key: 'Cross-Origin-Embedder-Policy',
    value: 'require-corp'
  },
  {
    key: 'Cross-Origin-Opener-Policy',
    value: 'same-origin'
  },
  {
    key: 'Cross-Origin-Resource-Policy',
    value: 'same-origin'
  }
];

module.exports = {
  async headers() {
    return [
      {
        source: '/(.*)',
        headers: securityHeaders,
      },
    ];
  },
};
```

#### Security Headers Validation

**Automated Testing:**
```bash
# Test all security headers
curl -I https://www.robbedbyapplecare.com | grep -E "(Content-Security-Policy|Strict-Transport-Security|X-Frame-Options|X-Content-Type-Options|Referrer-Policy|Permissions-Policy)"

# Validate CSP with online tools
# https://csp-evaluator.withgoogle.com/
# https://securityheaders.com/

# Test HSTS preload eligibility
curl -I https://www.robbedbyapplecare.com | grep -i strict-transport-security
```

**Manual Verification:**
```bash
# Check CSP violations in browser console
# Open Developer Tools → Console
# Look for CSP violation reports

# Verify HSTS is working
curl -I http://www.robbedbyapplecare.com
# Should return 301/302 redirect to HTTPS

# Test frame-ancestors protection
# Try embedding site in iframe - should be blocked
```

### Content Security Policy (CSP) Deep Dive

#### CSP Directive Explanations

```javascript
// Detailed CSP configuration with explanations
const cspDirectives = {
  // Controls default loading policy for all resource types
  "default-src": "'self'",
  
  // Images: Allow self, data URIs, Azure Blob Storage, and Discourse CDN
  "img-src": "'self' data: https://*.blob.core.windows.net https://www.gravatar.com https://avatars.discourse-cdn.com",
  
  // Scripts: Allow self, inline scripts (for Next.js), and Discourse forum
  "script-src": "'self' 'unsafe-inline' 'unsafe-eval' https://forum.robbedbyapplecare.com https://www.googletagmanager.com",
  
  // Styles: Allow self, inline styles, and Google Fonts
  "style-src": "'self' 'unsafe-inline' https://fonts.googleapis.com",
  
  // Fonts: Allow self and Google Fonts
  "font-src": "'self' https://fonts.gstatic.com",
  
  // AJAX/WebSocket connections
  "connect-src": "'self' https://forum.robbedbyapplecare.com https://www.google-analytics.com",
  
  // Prevent embedding in frames
  "frame-src": "'none'",
  "frame-ancestors": "'none'",
  
  // Base URI restrictions
  "base-uri": "'self'",
  
  // Form submission restrictions
  "form-action": "'self'",
  
  // Block plugins (Flash, etc.)
  "object-src": "'none'",
  
  // Media files
  "media-src": "'self'",
  
  // Web Workers
  "worker-src": "'self'",
  
  // Web App Manifest
  "manifest-src": "'self'",
  
  // Upgrade HTTP to HTTPS
  "upgrade-insecure-requests": ""
};
```

#### CSP Testing and Monitoring

**Development Testing:**
```bash
# Test CSP in report-only mode first
# Add to next.config.js for testing:
{
  key: 'Content-Security-Policy-Report-Only',
  value: 'default-src \'self\'; report-uri /api/csp-report'
}

# Create CSP violation endpoint
# pages/api/csp-report.js
export default function handler(req, res) {
  if (req.method === 'POST') {
    console.log('CSP Violation:', JSON.stringify(req.body, null, 2));
    res.status(204).end();
  }
}
```

**Production Monitoring:**
```bash
# Monitor CSP violations in browser
# Check Console for violation reports
# Example violation:
# "Refused to load the script 'https://evil.com/script.js' because it violates the following Content Security Policy directive: "script-src 'self'"

# Use CSP reporting services
# Report-URI: https://report-uri.com/
# Add to CSP: report-uri https://your-org.report-uri.com/r/d/csp/enforce
```

#### CSP Troubleshooting

**Common Issues and Solutions:**

1. **Inline Scripts Blocked:**
```javascript
// Problem: CSP blocks inline scripts
<script>alert('blocked')</script>

// Solution: Use nonce or move to external file
// In next.config.js, generate nonce and add to CSP:
"script-src 'self' 'nonce-{random-nonce}'"
```

2. **Third-party Widgets:**
```javascript
// Problem: External widgets (analytics, chat) blocked
// Solution: Add specific domains to CSP
"script-src 'self' https://www.googletagmanager.com https://widget.intercom.io"
```

3. **Discourse Embed Issues:**
```javascript
// Problem: Discourse embed not loading
// Solution: Ensure Discourse domain is in multiple directives
"script-src 'self' https://forum.robbedbyapplecare.com",
"frame-src https://forum.robbedbyapplecare.com",
"connect-src 'self' https://forum.robbedbyapplecare.com"
```

### HTTPS Enforcement

- All traffic is redirected to HTTPS
- HSTS header enforces HTTPS for future visits
- Certificates are automatically managed by Azure Front Door

## Infrastructure Security

### Network Security

### Azure Front Door WAF Configuration

#### WAF Policy Setup

**Create WAF Policy:**
```bash
# Create WAF policy with managed rules
az network front-door waf-policy create \
  --resource-group rg-robbedbyapplecare-prod \
  --name waf-robbedbyapplecare \
  --sku Premium_AzureFrontDoor \
  --mode Prevention

# Enable managed rule sets
az network front-door waf-policy managed-rules add \
  --policy-name waf-robbedbyapplecare \
  --resource-group rg-robbedbyapplecare-prod \
  --type Microsoft_DefaultRuleSet \
  --version 2.1 \
  --action Block

az network front-door waf-policy managed-rules add \
  --policy-name waf-robbedbyapplecare \
  --resource-group rg-robbedbyapplecare-prod \
  --type Microsoft_BotManagerRuleSet \
  --version 1.0 \
  --action Block
```

#### Rate Limiting Configuration

**Global Rate Limiting:**
```bash
# Create rate limiting rule (100 requests per minute per IP)
az network front-door waf-policy rule create \
  --policy-name waf-robbedbyapplecare \
  --resource-group rg-robbedbyapplecare-prod \
  --name "GlobalRateLimit" \
  --priority 100 \
  --rule-type RateLimitRule \
  --action Block \
  --rate-limit-duration-in-minutes 1 \
  --rate-limit-threshold 100 \
  --match-conditions '[
    {
      "matchVariable": "RemoteAddr",
      "operator": "IPMatch",
      "matchValue": ["0.0.0.0/0"]
    }
  ]'

# API endpoint rate limiting (stricter)
az network front-door waf-policy rule create \
  --policy-name waf-robbedbyapplecare \
  --resource-group rg-robbedbyapplecare-prod \
  --name "APIRateLimit" \
  --priority 200 \
  --rule-type RateLimitRule \
  --action Block \
  --rate-limit-duration-in-minutes 1 \
  --rate-limit-threshold 20 \
  --match-conditions '[
    {
      "matchVariable": "RequestUri",
      "operator": "BeginsWith",
      "matchValue": ["/api/"]
    }
  ]'
```

#### Custom Security Rules

**Block Known Bad IPs:**
```bash
# Create IP blocklist rule
az network front-door waf-policy rule create \
  --policy-name waf-robbedbyapplecare \
  --resource-group rg-robbedbyapplecare-prod \
  --name "BlockMaliciousIPs" \
  --priority 50 \
  --rule-type MatchRule \
  --action Block \
  --match-conditions '[
    {
      "matchVariable": "RemoteAddr",
      "operator": "IPMatch",
      "matchValue": ["192.0.2.1/32", "198.51.100.0/24"]
    }
  ]'
```

**Geographic Restrictions (Optional):**
```bash
# Block traffic from specific countries (if needed)
az network front-door waf-policy rule create \
  --policy-name waf-robbedbyapplecare \
  --resource-group rg-robbedbyapplecare-prod \
  --name "GeoBlock" \
  --priority 75 \
  --rule-type MatchRule \
  --action Block \
  --match-conditions '[
    {
      "matchVariable": "RemoteAddr",
      "operator": "GeoMatch",
      "matchValue": ["CN", "RU", "KP"]
    }
  ]'
```

**User Agent Filtering:**
```bash
# Block suspicious user agents
az network front-door waf-policy rule create \
  --policy-name waf-robbedbyapplecare \
  --resource-group rg-robbedbyapplecare-prod \
  --name "BlockBadUserAgents" \
  --priority 150 \
  --rule-type MatchRule \
  --action Block \
  --match-conditions '[
    {
      "matchVariable": "RequestHeader",
      "selector": "User-Agent",
      "operator": "Contains",
      "matchValue": ["sqlmap", "nikto", "nmap", "masscan"]
    }
  ]'
```

#### WAF Monitoring and Tuning

**Monitor WAF Logs:**
```bash
# Query WAF logs in Azure Monitor
az monitor log-analytics query \
  --workspace <workspace-id> \
  --analytics-query "
    AzureDiagnostics
    | where Category == 'FrontdoorWebApplicationFirewallLog'
    | where TimeGenerated > ago(24h)
    | where action_s == 'Block'
    | summarize count() by ruleName_s, clientIP_s
    | order by count_ desc
  "

# Check for false positives
az monitor log-analytics query \
  --workspace <workspace-id> \
  --analytics-query "
    AzureDiagnostics
    | where Category == 'FrontdoorWebApplicationFirewallLog'
    | where action_s == 'Block'
    | where requestUri_s contains '/legitimate-path'
    | project TimeGenerated, clientIP_s, requestUri_s, ruleName_s
  "
```

**WAF Rule Tuning:**
```bash
# Disable specific rules if causing false positives
az network front-door waf-policy managed-rules exclusion add \
  --policy-name waf-robbedbyapplecare \
  --resource-group rg-robbedbyapplecare-prod \
  --type Microsoft_DefaultRuleSet \
  --version 2.1 \
  --rule-group-name SQLI \
  --rule-id 942100 \
  --match-variable RequestBodyPostArgNames \
  --selector "legitimate_field"

# Create custom allow rules for legitimate traffic
az network front-door waf-policy rule create \
  --policy-name waf-robbedbyapplecare \
  --resource-group rg-robbedbyapplecare-prod \
  --name "AllowLegitimateAPI" \
  --priority 25 \
  --rule-type MatchRule \
  --action Allow \
  --match-conditions '[
    {
      "matchVariable": "RequestUri",
      "operator": "Equal",
      "matchValue": ["/api/legitimate-endpoint"]
    },
    {
      "matchVariable": "RequestHeader",
      "selector": "Authorization",
      "operator": "BeginsWith",
      "matchValue": ["Bearer "]
    }
  ]'
```

#### Rate Limiting Best Practices

**Tiered Rate Limiting Strategy:**

1. **Global Limits (Per IP):**
   - 100 requests/minute for general browsing
   - 500 requests/hour for sustained usage

2. **API Limits:**
   - 20 requests/minute for API endpoints
   - 100 requests/hour for API usage

3. **Authentication Limits:**
   - 5 login attempts/minute
   - 20 login attempts/hour

4. **Upload Limits:**
   - 10 file uploads/minute
   - 100 MB total uploads/hour

**Implementation Example:**
```bash
# Discourse-specific rate limiting
az network front-door waf-policy rule create \
  --policy-name waf-robbedbyapplecare \
  --resource-group rg-robbedbyapplecare-prod \
  --name "DiscourseLoginLimit" \
  --priority 300 \
  --rule-type RateLimitRule \
  --action Block \
  --rate-limit-duration-in-minutes 1 \
  --rate-limit-threshold 5 \
  --match-conditions '[
    {
      "matchVariable": "RequestUri",
      "operator": "Contains",
      "matchValue": ["/session"]
    },
    {
      "matchVariable": "RequestMethod",
      "operator": "Equal",
      "matchValue": ["POST"]
    }
  ]'
```

**Network Security Groups**:
```bash
# VM access is restricted to:
- SSH (port 22) - Limited to management IPs
- HTTP (port 80) - For Let's Encrypt challenges
- HTTPS (port 443) - Public access through Front Door
```

### Virtual Machine Security

**Hardening Measures**:
- Disable password authentication (SSH keys only)
- Automatic security updates enabled
- Minimal software installation
- Regular security patching
- Docker container isolation

**SSH Key Management**:
```bash
# Generate secure SSH key
ssh-keygen -t rsa -b 4096 -f ~/.ssh/discourse_vm

# Use strong passphrase
# Store private key securely
# Rotate keys regularly
```

### Database Security

**PostgreSQL Security**:
- Private networking (no public access)
- Encrypted connections (SSL/TLS)
- Strong authentication
- Regular security updates
- Backup encryption

**Connection Security**:
```bash
# Verify SSL connection
psql "sslmode=require host=<postgres_fqdn> dbname=discourse_production user=discourse_admin"
```

## Data Protection

### Encryption

**At Rest**:
- Azure Storage: AES-256 encryption
- PostgreSQL: Transparent Data Encryption (TDE)
- VM disks: Azure Disk Encryption

**In Transit**:
- HTTPS/TLS 1.2+ for all web traffic
- SSL/TLS for database connections
- Encrypted backup transfers

### Data Privacy

**Personal Data Handling**:
- EXIF data stripped from uploaded images
- User data stored securely in Discourse
- OAuth tokens managed by providers
- No unnecessary data collection

### Backup Security

```bash
# Encrypted backups to Azure Blob Storage
az storage blob upload \
  --account-name <storage_account> \
  --container-name backups \
  --name "encrypted-backup-$(date +%Y%m%d).tar.gz.enc" \
  --file backup.tar.gz.enc
```

## Identity and Access Management

### Azure Managed Identity

- VM uses managed identity for Azure service access
- No stored credentials in configuration files
- Automatic credential rotation

### Key Vault Integration

**Secrets Management**:
```bash
# Store OAuth secrets
az keyvault secret set \
  --vault-name kv-robbedbyapplecare \
  --name "google-oauth-client-id" \
  --value "<client-id>"

# Retrieve secrets in applications
az keyvault secret show \
  --vault-name kv-robbedbyapplecare \
  --name "google-oauth-client-id" \
  --query value -o tsv
```

### OAuth Security

**Google OAuth Configuration**:
- Authorized redirect URIs restricted
- Client secrets stored in Key Vault
- Regular credential rotation

**Facebook OAuth Configuration**:
- App domain restrictions
- Webhook verification
- Secure app secret storage

## Discourse Security

### Container Security

**Docker Security**:
- Non-root user in containers
- Read-only file systems where possible
- Resource limits configured
- Regular image updates

### Discourse Configuration

**Security Settings**:
```yaml
# app.yml security configuration
DISCOURSE_FORCE_HTTPS: true
DISCOURSE_USE_S3: true
DISCOURSE_ENABLE_CORS: true
DISCOURSE_CORS_ORIGIN: 'https://www.robbedbyapplecare.com'
```

**Admin Security**:
- Strong admin passwords
- Two-factor authentication enabled
- Regular admin account review
- Audit log monitoring

## Monitoring and Alerting

### Security Monitoring

**Azure Security Center**:
- Vulnerability assessments
- Security recommendations
- Threat detection
- Compliance monitoring

**Log Monitoring**:
```bash
# Monitor authentication attempts
sudo journalctl -u ssh -f

# Monitor Discourse logs
sudo docker-compose logs -f discourse | grep -i "auth\|login\|security"

# Monitor WAF logs
az monitor activity-log list --resource-group rg-robbedbyapplecare-prod
```

### Incident Response

**Security Alerts**:
- Failed authentication attempts
- Unusual traffic patterns
- Certificate expiration warnings
- Vulnerability scan results

**Response Procedures**:
1. Assess threat severity
2. Isolate affected systems
3. Preserve evidence
4. Apply security patches
5. Monitor for further activity
6. Document incident

## Security Testing

### Regular Security Assessments

**Automated Testing**:
```bash
# SSL/TLS configuration test
testssl.sh --quiet https://www.robbedbyapplecare.com

# Security headers test
curl -I https://www.robbedbyapplecare.com | grep -E "(CSP|HSTS|X-Frame)"

# Vulnerability scanning
nmap -sV --script vuln www.robbedbyapplecare.com
```

**Manual Testing**:
- Penetration testing (quarterly)
- Code security review
- Configuration audit
- Access control verification

### Security Checklist

**Monthly Security Review**:
- [ ] Review access logs
- [ ] Check for security updates
- [ ] Verify backup integrity
- [ ] Test incident response procedures
- [ ] Review user access permissions
- [ ] Check certificate expiration dates
- [ ] Validate security configurations

**Quarterly Security Assessment**:
- [ ] Penetration testing
- [ ] Vulnerability assessment
- [ ] Security policy review
- [ ] Disaster recovery testing
- [ ] Security training update
- [ ] Third-party security audit

## Compliance and Best Practices

### Security Standards

The project follows these security standards:
- OWASP Top 10 protection
- Azure Security Benchmark
- CIS Controls
- NIST Cybersecurity Framework

### Security Best Practices and Update Procedures

#### Development Security Best Practices

**Secure Coding Standards:**
```javascript
// 1. Input Validation and Sanitization
const sanitizeInput = (input) => {
  return DOMPurify.sanitize(input, {
    ALLOWED_TAGS: ['b', 'i', 'em', 'strong'],
    ALLOWED_ATTR: []
  });
};

// 2. Parameterized Queries (Discourse backend)
// Always use parameterized queries to prevent SQL injection
User.where("email = ?", user_email)  // Good
User.where("email = '#{user_email}'")  // Bad - vulnerable to SQL injection

// 3. Secure Headers in API Responses
export default function handler(req, res) {
  res.setHeader('Cache-Control', 'no-store');
  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.json({ data: sanitizedData });
}
```

**Dependency Security Management:**
```bash
# 1. Regular dependency auditing
npm audit --audit-level moderate
npm audit fix

# 2. Automated dependency updates with security focus
# Use Dependabot or Renovate for automated PRs
# Configure .github/dependabot.yml:
version: 2
updates:
  - package-ecosystem: "npm"
    directory: "/apps/web"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 5
    reviewers:
      - "security-team"

# 3. License compliance checking
npx license-checker --onlyAllow 'MIT;Apache-2.0;BSD-3-Clause;ISC'

# 4. Supply chain security
npm ci --only=production  # Use exact versions from package-lock.json
```

**Secrets Management Best Practices:**
```bash
# 1. Never commit secrets to version control
# Use .gitignore and .env.example files
echo "*.env" >> .gitignore
echo ".env.local" >> .gitignore

# 2. Use Azure Key Vault for all secrets
az keyvault secret set \
  --vault-name kv-robbedbyapplecare \
  --name "database-connection-string" \
  --value "postgresql://user:pass@host:5432/db"

# 3. Rotate secrets regularly (automated)
# Create rotation script
#!/bin/bash
NEW_SECRET=$(openssl rand -base64 32)
az keyvault secret set \
  --vault-name kv-robbedbyapplecare \
  --name "api-key" \
  --value "$NEW_SECRET"

# 4. Use managed identities instead of service principals where possible
az vm identity assign \
  --resource-group rg-robbedbyapplecare-prod \
  --name vm-discourse
```

#### Operational Security Procedures

**Security Update Management:**

**Weekly Security Updates:**
```bash
# 1. Check for security advisories
# GitHub Security Advisories: https://github.com/advisories
# Azure Security Updates: https://azure.microsoft.com/en-us/updates/

# 2. Update system packages on VM
ssh discourse-admin@<vm_ip>
sudo apt update && sudo apt list --upgradable
sudo apt upgrade -y
sudo reboot  # If kernel updates

# 3. Update Docker images
sudo docker-compose pull
sudo docker-compose up -d

# 4. Update Node.js dependencies
cd apps/web
npm audit
npm update
npm run test  # Verify no breaking changes
```

**Monthly Security Review:**
```bash
# 1. Review access logs for anomalies
az monitor log-analytics query \
  --workspace <workspace-id> \
  --analytics-query "
    AzureDiagnostics
    | where TimeGenerated > ago(30d)
    | where Category == 'FrontdoorAccessLog'
    | where httpStatusCode_d >= 400
    | summarize count() by clientIP_s, httpStatusCode_d
    | order by count_ desc
  "

# 2. Check for failed authentication attempts
ssh discourse-admin@<vm_ip>
sudo journalctl -u ssh --since "30 days ago" | grep "Failed password"

# 3. Review Discourse admin actions
# Login to https://forum.robbedbyapplecare.com/admin/logs/staff_action_logs

# 4. Validate security configurations
curl -I https://www.robbedbyapplecare.com | grep -E "(CSP|HSTS|X-Frame)"
testssl.sh --quiet https://www.robbedbyapplecare.com
```

**Quarterly Security Assessment:**
```bash
# 1. Penetration testing checklist
# - SQL injection testing
# - XSS vulnerability testing
# - Authentication bypass attempts
# - Authorization testing
# - Session management testing

# 2. Infrastructure security review
az security assessment list \
  --resource-group rg-robbedbyapplecare-prod

# 3. Code security review
# Use tools like:
# - SonarQube for static analysis
# - Snyk for dependency vulnerabilities
# - CodeQL for semantic code analysis

# 4. Compliance validation
# - OWASP Top 10 compliance check
# - Azure Security Benchmark assessment
# - Data protection compliance (GDPR considerations)
```

#### Incident Response Procedures

**Security Incident Classification:**

**Level 1 - Low Impact:**
- Single failed login attempt
- Minor configuration drift
- Non-critical vulnerability discovered

**Level 2 - Medium Impact:**
- Multiple failed login attempts from same IP
- Suspicious traffic patterns
- Medium-severity vulnerability

**Level 3 - High Impact:**
- Successful unauthorized access
- Data breach suspected
- Critical vulnerability exploitation

**Level 4 - Critical:**
- Confirmed data breach
- System compromise
- Service unavailability due to attack

**Incident Response Playbook:**

```bash
# Level 1 Response (Automated)
# 1. Log the incident
echo "$(date): Level 1 incident - $INCIDENT_DESCRIPTION" >> /var/log/security-incidents.log

# 2. Apply automatic remediation
# Block IP if multiple failed attempts
az network front-door waf-policy rule create \
  --policy-name waf-robbedbyapplecare \
  --resource-group rg-robbedbyapplecare-prod \
  --name "BlockSuspiciousIP-$(date +%s)" \
  --priority 10 \
  --rule-type MatchRule \
  --action Block \
  --match-conditions "[{\"matchVariable\":\"RemoteAddr\",\"operator\":\"IPMatch\",\"matchValue\":[\"$SUSPICIOUS_IP\"]}]"

# Level 2-4 Response (Manual)
# 1. Immediate containment
# Isolate affected systems
az vm stop --resource-group rg-robbedbyapplecare-prod --name vm-discourse

# 2. Evidence preservation
# Create VM snapshot before investigation
az snapshot create \
  --resource-group rg-robbedbyapplecare-prod \
  --name vm-discourse-incident-$(date +%Y%m%d) \
  --source vm-discourse

# 3. Investigation
# Collect logs and analyze
az monitor log-analytics query \
  --workspace <workspace-id> \
  --analytics-query "
    AzureDiagnostics
    | where TimeGenerated > ago(24h)
    | where clientIP_s == '$SUSPICIOUS_IP'
    | project TimeGenerated, requestUri_s, httpStatusCode_d, userAgent_s
  "

# 4. Remediation
# Apply security patches, update configurations
# Reset compromised credentials
# Update WAF rules

# 5. Recovery
# Restore services after verification
az vm start --resource-group rg-robbedbyapplecare-prod --name vm-discourse

# 6. Post-incident review
# Document lessons learned
# Update security procedures
# Implement additional controls
```

#### Security Automation

**Automated Security Monitoring:**
```bash
# 1. Create security monitoring script
#!/bin/bash
# security-monitor.sh

# Check for suspicious login patterns
FAILED_LOGINS=$(ssh discourse-admin@<vm_ip> "sudo journalctl -u ssh --since '1 hour ago' | grep 'Failed password' | wc -l")
if [ $FAILED_LOGINS -gt 10 ]; then
    # Send alert
    curl -X POST -H 'Content-type: application/json' \
        --data '{"text":"🚨 Security Alert: '$FAILED_LOGINS' failed SSH login attempts in the last hour"}' \
        $WEBHOOK_URL
fi

# Check for high error rates
ERROR_RATE=$(az monitor log-analytics query \
    --workspace <workspace-id> \
    --analytics-query "
        AzureDiagnostics
        | where TimeGenerated > ago(1h)
        | where httpStatusCode_d >= 400
        | count
    " --query "tables[0].rows[0][0]" -o tsv)

if [ $ERROR_RATE -gt 100 ]; then
    curl -X POST -H 'Content-type: application/json' \
        --data '{"text":"⚠️ High error rate detected: '$ERROR_RATE' errors in the last hour"}' \
        $WEBHOOK_URL
fi

# 2. Schedule monitoring script
echo "0 * * * * /usr/local/bin/security-monitor.sh" | crontab -
```

**Automated Vulnerability Scanning:**
```bash
# 1. Create vulnerability scan script
#!/bin/bash
# vuln-scan.sh

# Scan for open ports
nmap -sS -O www.robbedbyapplecare.com > /tmp/nmap-scan.txt

# Check SSL configuration
testssl.sh --quiet --jsonfile /tmp/ssl-scan.json https://www.robbedbyapplecare.com

# Scan dependencies
cd /path/to/project
npm audit --json > /tmp/npm-audit.json

# Check for high/critical vulnerabilities
CRITICAL_VULNS=$(cat /tmp/npm-audit.json | jq '.metadata.vulnerabilities.critical')
if [ $CRITICAL_VULNS -gt 0 ]; then
    curl -X POST -H 'Content-type: application/json' \
        --data '{"text":"🔴 Critical vulnerabilities found: '$CRITICAL_VULNS'"}' \
        $WEBHOOK_URL
fi

# 2. Run weekly via GitHub Actions
# .github/workflows/security-scan.yml
name: Security Scan
on:
  schedule:
    - cron: '0 2 * * 1'  # Every Monday at 2 AM
jobs:
  security-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run vulnerability scan
        run: |
          npm audit --audit-level critical
          docker run --rm -v $(pwd):/app securecodewarrior/docker-security-scan
```

## Emergency Contacts

**Security Incidents**:
- Azure Security Response: [Contact Info]
- Internal Security Team: [Contact Info]
- Legal/Compliance: [Contact Info]

**Escalation Procedures**:
1. Immediate containment
2. Notify security team
3. Assess impact
4. Implement remediation
5. Post-incident review

## Security Resources

- [Azure Security Documentation](https://docs.microsoft.com/en-us/azure/security/)
- [OWASP Security Guidelines](https://owasp.org/)
- [Discourse Security Guide](https://meta.discourse.org/t/discourse-security-guide/10243)
- [Next.js Security Headers](https://nextjs.org/docs/advanced-features/security-headers)