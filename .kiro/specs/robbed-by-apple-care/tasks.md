# Implementation Plan

- [x] 1. Set up monorepo structure and development environment
  - Create pnpm workspace configuration with apps/web, infra/terraform, and apps/forum-provisioning directories
  - Initialize Next.js 14 app with App Router in apps/web
  - Configure Tailwind CSS and TypeScript settings
  - Set up basic package.json scripts for development workflow
  - _Requirements: 10.1, 10.2_

- [x] 2. Implement core article content system
  - [x] 2.1 Create MDX article processing and frontmatter interface
    - Define TypeScript interfaces for ArticleFrontmatter and EvidenceItem
    - Implement MDX loader and parser for article content
    - Create article.mdx template with realistic placeholder content
    - _Requirements: 4.1, 4.4, 10.5_

  - [x] 2.2 Build evidence gallery component with lightbox
    - Create EvidenceGallery component with responsive image display
    - Implement lightbox functionality with navigation controls
    - Add support for both image and PDF evidence types with captions
    - _Requirements: 1.2, 1.3, 4.2_

  - [x] 2.3 Create image optimization and processing script
    - Build Node.js script using Sharp for image compression
    - Generate webp versions in multiple sizes (320/640/1280px)
    - Implement EXIF data stripping for security
    - Create file-drop interface for evidence management
    - _Requirements: 1.5, 3.4, 4.3_

- [x] 3. Implement single-page article layout and design system
  - [x] 3.1 Create main page layout with article structure
    - Build page.tsx with article sections (title, subtitle, hero, TL;DR, timeline)
    - Implement responsive layout with mobile-first approach
    - Add anchored headings and smooth scrolling navigation
    - _Requirements: 1.1, 4.5_

  - [x] 3.2 Build Tailwind design system components
    - Create reusable UI components (buttons, badges, callouts)
    - Implement dark/light theme toggle functionality
    - Build responsive typography and spacing system
    - _Requirements: 1.1, 10.5_

  - [x] 3.3 Add SEO and social sharing features
    - Implement OpenGraph and Twitter Card meta tags
    - Create JSON-LD Article schema markup
    - Build dynamic OG image generation using edge function
    - Generate sitemap.xml and robots.txt files
    - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5_

- [x] 4. Implement Discourse embedded comments integration
  - [x] 4.1 Create DiscourseEmbed component
    - Build React component for Discourse embed script
    - Implement proper script loading with error handling
    - Configure canonical URL detection for topic creation
    - _Requirements: 2.1, 2.2, 2.4_

  - [x] 4.2 Add Discourse embed script and configuration
    - Implement embed JavaScript with proper CSP compliance
    - Add prefetch functionality for Discourse assets
    - Create fallback UI for when Discourse is unavailable
    - _Requirements: 2.1, 2.5_

- [x] 5. Implement security headers and performance optimizations
  - [x] 5.1 Configure security headers in Next.js
    - Implement CSP, HSTS, Referrer-Policy, and Permissions-Policy headers
    - Add X-Frame-Options and X-Content-Type-Options
    - Remove x-powered-by header and enforce HTTPS redirects
    - _Requirements: 3.1, 3.2, 3.3, 3.5_

  - [x] 5.2 Optimize performance and implement lazy loading
    - Add lazy loading for evidence gallery images
    - Implement critical CSS extraction
    - Configure image optimization with Next.js Image component
    - Add performance monitoring and Core Web Vitals tracking
    - _Requirements: 1.4, 1.5_

- [x] 6. Create Terraform infrastructure modules
  - [x] 6.1 Build networking and Front Door module
    - Create Terraform module for Azure Front Door with WAF
    - Implement DNS zone configuration for custom domain
    - Configure routing rules for www and forum subdomains
    - Add managed certificate provisioning
    - _Requirements: 5.1, 5.2, 5.5, 7.1_

  - [x] 6.2 Implement static site hosting module
    - Create Azure Static Web Apps resource with Front Door integration
    - Configure custom domain binding and HTTPS enforcement
    - Set up deployment slots for staging/production
    - _Requirements: 5.3, 5.4_

  - [x] 6.3 Build Discourse infrastructure module
    - Create Ubuntu VM with proper sizing (Standard D2s v5)
    - Implement Azure Database for PostgreSQL Flexible Server
    - Configure Azure Blob Storage with S3-compatible settings
    - Set up VNet, NSG, and security configurations
    - _Requirements: 6.1, 6.2, 6.3, 7.1_

  - [x] 6.4 Implement Key Vault and secrets management
    - Create Azure Key Vault for OAuth secrets and credentials
    - Configure Managed Identity for VM access to Key Vault
    - Set up secret rotation and access policies
    - _Requirements: 6.5, 7.5_

- [-] 7. Create Discourse Docker configuration and provisioning
  - [x] 7.1 Build Discourse Docker setup
    - Create app.yml configuration with PostgreSQL and Blob storage
    - Configure OAuth providers (Google and Facebook)
    - Set up SMTP configuration for email notifications
    - _Requirements: 6.1, 6.2, 6.3, 6.4_

  - [x] 7.2 Implement Discourse provisioning scripts
    - Create provision.sh script for Docker installation and setup
    - Build admin user creation and initial configuration
    - Implement embed settings configuration (whitelist, CORS)
    - _Requirements: 6.5, 7.4_

  - [x] 7.3 Add backup and maintenance automation
    - Create backup-cron.sh script for nightly backups to Blob
    - Implement health check monitoring and restart procedures
    - Build maintenance and update scripts
    - _Requirements: 9.1, 9.2, 9.4_

- [-] 8. Implement CI/CD pipeline with GitHub Actions
  - [x] 8.1 Create web application deployment workflow
    - Build GitHub Actions workflow for Next.js build and test
    - Implement deployment to Azure Static Web Apps
    - Add linting, accessibility checks, and performance testing
    - _Requirements: 7.2, 10.3_

  - [x] 8.2 Build infrastructure deployment pipeline
    - Create Terraform plan workflow for pull requests
    - Implement Terraform apply workflow for releases
    - Add security scanning and validation steps
    - _Requirements: 7.3_

  - [x] 8.3 Add Discourse deployment automation
    - Create workflow for Discourse configuration updates
    - Implement SSH-based deployment to VM
    - Add health check verification after deployments
    - _Requirements: 7.4_

- [x] 9. Create comprehensive testing suite
  - [x] 9.1 Implement unit tests for React components
    - Write tests for Article, EvidenceGallery, and DiscourseEmbed components
    - Test error handling and fallback scenarios
    - Add accessibility testing with axe-core
    - _Requirements: 1.1, 1.2, 1.3, 10.3_

  - [x] 9.2 Build integration tests for Discourse embed
    - Test topic creation and comment loading functionality
    - Mock Discourse API responses for reliable testing
    - Verify canonical URL handling and embed configuration
    - _Requirements: 2.2, 2.4, 2.5_

  - [x] 9.3 Add end-to-end testing with Playwright
    - Create user journey tests for article reading and commenting
    - Test OAuth login flows and comment posting
    - Verify mobile responsiveness and performance metrics
    - _Requirements: 1.4, 2.3, 6.4_

- [x] 10. Create documentation and deployment guides
  - [x] 10.1 Write deployment documentation
    - Create DEPLOYMENT.md with step-by-step Azure setup instructions
    - Document domain configuration and certificate binding
    - Add troubleshooting guide for common deployment issues
    - _Requirements: 10.4_

  - [x] 10.2 Build operational runbook
    - Create RUNBOOK.md with Discourse restart and maintenance procedures
    - Document backup restoration and key rotation processes
    - Add monitoring and alerting setup instructions
    - _Requirements: 9.3, 9.5, 10.4_

  - [x] 10.3 Create security documentation
    - Write SECURITY.md with security headers and CSP configuration
    - Document WAF rules and rate limiting setup
    - Add security best practices and update procedures
    - _Requirements: 3.1, 3.2, 5.5, 10.4_

- [x] 11. Generate placeholder content and final integration
  - [x] 11.1 Create realistic article content and evidence
    - Write comprehensive MDX article about AppleCare issues
    - Generate 6-10 placeholder evidence images (redacted email screenshots)
    - Create proper captions and metadata for all evidence
    - _Requirements: 10.5_

  - [x] 11.2 Perform final integration testing and optimization
    - Test complete user flow from article reading to commenting
    - Verify Lighthouse performance scores meet ≥90 requirement
    - Validate all security headers and HTTPS enforcement
    - Confirm OAuth login and comment functionality
    - _Requirements: 1.4, 2.3, 3.1, 6.4_