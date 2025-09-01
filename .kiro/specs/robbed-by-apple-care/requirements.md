# Requirements Document

## Introduction

RobbedByAppleCare is a single-purpose website designed to host one long-form complaint article about AppleCare with an embedded Discourse forum for community discussion. The project consists of a static single-page application hosted on Azure with a custom domain (RobbedByAppleCare.com), featuring a main site at www.robbedbyapplecare.com and a Discourse forum at forum.robbedbyapplecare.com. The forum is embedded directly beneath the article content to create a Reddit-style discussion experience.

## Requirements

### Requirement 1

**User Story:** As a visitor, I want to read a comprehensive article about AppleCare issues on a fast-loading single page, so that I can understand the complaint and supporting evidence.

#### Acceptance Criteria

1. WHEN a user visits www.robbedbyapplecare.com THEN the system SHALL render a single-page article with title, subtitle, hero image, TL;DR, and timeline sections
2. WHEN the page loads THEN the system SHALL display an evidence gallery with email screenshots and optional PDFs with captions and lightbox functionality
3. WHEN a user clicks on evidence items THEN the system SHALL open them in a lightbox with navigation controls
4. WHEN the page loads THEN the system SHALL achieve a Lighthouse performance score of ≥90 on mobile devices
5. WHEN images are displayed THEN the system SHALL serve optimized webp formats with responsive sizes (320/640/1280px)

### Requirement 2

**User Story:** As a visitor, I want to participate in discussions about the article directly below the content, so that I can share my experiences and engage with the community without navigating to a separate forum.

#### Acceptance Criteria

1. WHEN a user scrolls below the article content THEN the system SHALL display an embedded Discourse comment thread
2. WHEN a user first visits the page THEN the system SHALL automatically create a Discourse topic tied to the page's canonical URL
3. WHEN a user wants to comment THEN the system SHALL allow login via Google or Facebook OAuth through Discourse
4. WHEN a user posts a comment THEN the system SHALL display it immediately in the embedded thread
5. WHEN the embedded thread loads THEN the system SHALL provide a "continue discussion" link to the full forum

### Requirement 3

**User Story:** As a site administrator, I want the website to be secure and performant, so that users have a safe browsing experience and the site loads quickly.

#### Acceptance Criteria

1. WHEN any user accesses the site THEN the system SHALL enforce HTTPS with automatic HTTP redirects
2. WHEN the page loads THEN the system SHALL include security headers: CSP, HSTS, Referrer-Policy, and Permissions-Policy
3. WHEN content is served THEN the system SHALL implement HSTS with max-age=31536000 and includeSubDomains
4. WHEN images are processed THEN the system SHALL strip EXIF data from all evidence images
5. WHEN the site is accessed THEN the system SHALL remove x-powered-by headers and enforce strict MIME sniffing

### Requirement 4

**User Story:** As a content creator, I want to manage the article content through MDX with structured frontmatter, so that I can easily update the article and evidence without touching code.

#### Acceptance Criteria

1. WHEN content is stored THEN the system SHALL use MDX format with JSON frontmatter containing title, subtitle, authorDisplay, publishedAt, tldr, tags, heroImage, ogImage, canonicalUrl, and evidence array
2. WHEN evidence is added THEN the system SHALL support both image and PDF types with captions
3. WHEN images are uploaded THEN the system SHALL provide a file-drop script using Sharp to compress and generate webp versions
4. WHEN the article is updated THEN the system SHALL not require database changes or complex deployments
5. WHEN content is rendered THEN the system SHALL support anchored headings, callouts, and footnotes

### Requirement 5

**User Story:** As a site owner, I want the infrastructure to be hosted on Azure with proper domain configuration, so that the site is reliable and professionally accessible.

#### Acceptance Criteria

1. WHEN the infrastructure is deployed THEN the system SHALL use Azure Front Door with managed certificates for both www and forum subdomains
2. WHEN traffic is routed THEN the system SHALL direct www.* to the static site origin and forum.* to the Discourse VM endpoint
3. WHEN the static site is hosted THEN the system SHALL use Azure Static Web Apps with Front Door integration
4. WHEN DNS is configured THEN the system SHALL properly resolve RobbedByAppleCare.com, www.robbedbyapplecare.com, and forum.robbedbyapplecare.com
5. WHEN WAF is enabled THEN the system SHALL implement basic security rules through Front Door

### Requirement 6

**User Story:** As a forum administrator, I want Discourse running on Azure infrastructure with proper database and storage, so that the community can engage reliably with OAuth authentication.

#### Acceptance Criteria

1. WHEN Discourse is deployed THEN the system SHALL run on an Azure Ubuntu LTS VM using Docker
2. WHEN the database is configured THEN the system SHALL use Azure Database for PostgreSQL Flexible Server with a dedicated database and user
3. WHEN file uploads occur THEN the system SHALL store them in Azure Blob Storage with S3-compatible configuration
4. WHEN users authenticate THEN the system SHALL support Google and Facebook OAuth login
5. WHEN embedded comments are configured THEN the system SHALL whitelist www.robbedbyapplecare.com and auto-create topics for embedded pages

### Requirement 7

**User Story:** As a developer, I want infrastructure as code and automated deployments, so that the system can be reliably deployed and maintained.

#### Acceptance Criteria

1. WHEN infrastructure is provisioned THEN the system SHALL use Terraform to create all Azure resources including resource groups, Front Door, Static Web Apps, PostgreSQL, VNet, VM, and Key Vault
2. WHEN code is pushed to main THEN the system SHALL automatically build and deploy the static site via GitHub Actions
3. WHEN infrastructure changes are made THEN the system SHALL run Terraform plan on PRs and apply on releases
4. WHEN Discourse is updated THEN the system SHALL support automated provisioning and restart via SSH scripts
5. WHEN secrets are managed THEN the system SHALL store OAuth secrets, SMTP credentials, and Blob keys in Azure Key Vault

### Requirement 8

**User Story:** As a site visitor, I want proper SEO and social sharing capabilities, so that the article can be discovered and shared effectively.

#### Acceptance Criteria

1. WHEN the page is crawled THEN the system SHALL include OpenGraph and Twitter Card meta tags
2. WHEN the page is indexed THEN the system SHALL provide JSON-LD Article schema markup
3. WHEN search engines access the site THEN the system SHALL serve sitemap.xml and robots.txt
4. WHEN the page is shared THEN the system SHALL generate dynamic OG images using an edge function
5. WHEN the canonical URL is set THEN the system SHALL use it for Discourse topic creation and SEO

### Requirement 9

**User Story:** As a system administrator, I want monitoring and backup capabilities, so that I can maintain the system and recover from issues.

#### Acceptance Criteria

1. WHEN Discourse is running THEN the system SHALL perform nightly backups to Azure Blob Storage
2. WHEN the VM is deployed THEN the system SHALL include health checks and systemd service management
3. WHEN backups are needed THEN the system SHALL provide restore procedures documented in the runbook
4. WHEN keys need rotation THEN the system SHALL support credential rotation procedures
5. WHEN monitoring is required THEN the system SHALL provide restart and maintenance procedures for Discourse

### Requirement 10

**User Story:** As a developer, I want a well-structured monorepo with clear development workflows, so that I can efficiently develop and maintain the application.

#### Acceptance Criteria

1. WHEN the project is structured THEN the system SHALL use pnpm workspaces with apps/web, infra/terraform, and apps/forum-provisioning directories
2. WHEN developing locally THEN the system SHALL support `pnpm dev` for the web app and optional local Discourse via docker-compose
3. WHEN code quality is enforced THEN the system SHALL include linting, link checking, and Axe accessibility tests in CI
4. WHEN documentation is provided THEN the system SHALL include DEPLOYMENT.md, RUNBOOK.md, and SECURITY.md files
5. WHEN the project is initialized THEN the system SHALL include realistic placeholder content with 6-10 evidence images