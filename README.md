# Robbed by AppleCare

A production-ready monorepo for a single-page article website with embedded Discourse comments, hosted on Azure infrastructure.

## Project Structure

```
robbed-by-apple-care/
├── apps/
│   ├── web/                    # Next.js single-page application
│   └── forum-provisioning/     # Discourse Docker configuration
├── infra/
│   └── terraform/              # Azure infrastructure as code
├── .github/
│   └── workflows/              # CI/CD pipelines
└── docs/                       # Documentation
```

## Quick Start

### Prerequisites

- Node.js 18+
- pnpm 8+
- Docker (for local Discourse development)
- Terraform (for infrastructure deployment)
- Azure CLI (for Azure deployment)

### Local Development

1. Install dependencies:
```bash
pnpm install
```

2. Start the web application:
```bash
pnpm dev
```

3. (Optional) Start local Discourse:
```bash
pnpm discourse:up
```

### Deployment

1. Initialize Terraform:
```bash
pnpm terraform:init
```

2. Deploy infrastructure:
```bash
pnpm terraform:apply
```

3. Deploy web application (via GitHub Actions on push to main)

## Architecture

- **Frontend**: Next.js 14 with App Router, Tailwind CSS
- **Forum**: Discourse with Docker on Azure VM
- **Database**: Azure Database for PostgreSQL Flexible Server
- **Storage**: Azure Blob Storage for uploads and backups
- **Hosting**: Azure Static Web Apps + Front Door
- **Infrastructure**: Terraform for Azure resource management

## Features

- Single-page article with MDX content
- Evidence gallery with lightbox
- Embedded Discourse comments
- SEO optimization with OpenGraph and JSON-LD
- Security headers and HTTPS enforcement
- Mobile-responsive design with dark/light themes
- Automated CI/CD with GitHub Actions

## Documentation

- [Deployment Guide](docs/DEPLOYMENT.md)
- [Operations Runbook](docs/RUNBOOK.md)
- [Security Guide](docs/SECURITY.md)

## License

Private project - All rights reserved.