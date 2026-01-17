# Mattermost on Hetzner Cloud (Terraform)

Deploy a production-ready Mattermost stack on **Hetzner Cloud** using **Terraform** and **Docker**, with Cloudflare in front for TLS and optional extra hardening. [file:3]

This project provisions a Hetzner VM, installs Docker, and starts Mattermost + PostgreSQL + NGINX (reverse proxy) plus optional operational tooling (Portainer, Watchtower) and basic backups. [file:3]

## What this deploys

- **Hetzner Cloud VM** (default: CPX22) in **NBG1** (Nuremberg), with optional Hetzner automatic backups enabled. [file:3]
- **Dockerized services**:
  - Mattermost
  - PostgreSQL
  - NGINX reverse proxy (ports **80/443** on the host)
  - Portainer (local access)
  - Watchtower (automatic container updates) [file:3]
- **Cloudflare integration**:
  - Cloudflare Origin CA certificate for origin TLS
  - Cloudflare Authenticated Origin Pulls (AOP) so NGINX only serves HTTPS when requests come via Cloudflare (prevents direct-IP bypass) [file:3]
- **Backups** (to a mounted backup path):
  - Daily `pg_dump` with retention
  - Periodic Mattermost files/config archive with retention [file:3]

## Architecture overview

Traffic flow is: **Internet → Cloudflare → NGINX (443) → Mattermost container (internal Docker network)**. [file:3]

PostgreSQL is not exposed publicly; it is only reachable from the internal Docker network on the VM. [file:3]

## Prerequisites

Accounts / services:
- Hetzner Cloud account + API token. [file:3]
- Cloudflare zone for your domain (the hostname you plan to use for Mattermost). [file:3]

Local tools:
- Terraform installed (see `versions.tf` for constraints). [file:6]
- SSH keypair available for provisioning access. [file:3]

## Quick start

1) Clone the repo and enter it. [file:3]

2) Create your variables file:
- Copy `example.tfvars` → `terraform.auto.tfvars`
- Fill in the values (tokens, domain/zone details, SSH key settings, etc.). [file:3][file:10]

3) Initialize and deploy:
```bash
terraform init
terraform plan
terraform apply



## Docker Server Directory mappings:
    - /mattermost/MMserver/config – Mattermost config file (config.json) will be stored here.
    - /mattermost/MMserver/data – All user-uploaded files (images, attachments) will persist here
    - /mattermost/MMserver/logs – Log files.
    - /mattermost/MMserver/plugins and client_plugins – any installed server or web client plugins.
    - /mattermost/MMserver/bleve-indexes – search index data (if using Bleve for search).
    - /mattermost/PgSQL/data – PostgreSQL database files.
    - /mattermost/NGINX/cert - SSL keys obtained from CloudFlare Origin certificate service 

