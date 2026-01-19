# Mattermost on Hetzner Cloud (Terraform)

Deploy a production-ready Mattermost stack on **Hetzner Cloud** using **Terraform** and **Docker**, with Cloudflare in front for TLS and optional extra hardening.

This project provisions a Hetzner VM, installs Docker, and starts Mattermost + PostgreSQL + NGINX (reverse proxy) plus optional operational tooling (Portainer, Watchtower) and basic backups.

## What this deploys

- **Hetzner Cloud VM** (default: CPX22) in **NBG1** (Nuremberg), with optional Hetzner automatic backups enabled.
- **Dockerized services**:
  - Mattermost
  - PostgreSQL
  - NGINX reverse proxy (ports **80/443** on the host)
  - Portainer (local access)
  - Watchtower (automatic container updates)
- **Cloudflare integration**:
  - Cloudflare Origin CA certificate for origin TLS
  - Cloudflare Authenticated Origin Pulls (AOP) so NGINX only serves HTTPS when requests come via Cloudflare (prevents direct-IP bypass)
- **Automated maintenance**:
  - Automatic security updates scheduled for Tuesdays at 4:00 AM
  - Email notifications on security update failures
  - Daily database backups with retention
  - Periodic Mattermost files/config archive with retention
- **SMTP email configuration**:
  - Email settings configured via Terraform variables
  - Shared SMTP configuration for both Mattermost and OS notifications
  - No manual System Console configuration needed

## Architecture overview

Traffic flow is: **Internet → Cloudflare → NGINX (443) → Mattermost container (internal Docker network)**.

PostgreSQL is not exposed publicly; it is only reachable from the internal Docker network on the VM.

## Prerequisites

Accounts / services:
- Hetzner Cloud account + API token.
- Cloudflare zone for your domain (the hostname you plan to use for Mattermost).
- SMTP server credentials for email notifications (optional but recommended).

Local tools:
- Terraform installed (see `versions.tf` for constraints).
- SSH keypair available for provisioning access.

## Quick start

1) Clone the repo and enter it.

2) Create your variables file:
- Copy `example.tfvars` → `terraform.auto.tfvars`
- Fill in the values (tokens, domain/zone details, SSH key settings, SMTP configuration, etc.).

3) Initialize and deploy:
```bash
terraform init
terraform plan
terraform apply
```

4) Wait for the VM to come up, install Docker, and start all containers. First boot takes a few minutes.

5) Access your Mattermost instance at `https://your.domain` and complete the initial setup.

## Performance - 🏆 CPX32 is the Champion!

Comprehensive load tests reveal **CPX32 (4 AMD EPYC cores) is the ULTIMATE WINNER** - handling 1500 concurrent users with 35ms median response and 99.58% success rate! See [PERFORMANCE.md](PERFORMANCE.md) for complete benchmarks.

### 📊 All Instances @ 1250 Users - THE SHOWDOWN

| Instance | CPU Type | Cores | Price/mo | Median | 95%ile | 99%ile | Failures | CPU Idle | Winner? |
|----------|----------|-------|----------|--------|--------|--------|----------|----------|---------|
| **CPX22** | AMD EPYC | 2 | €6 | 470ms | 2200ms | 3100ms | **4.5%** | 23% | ❌ Failed |
| **CCX13** | AMD EPYC (ded) | 2 | €12 | 930ms | 3100ms | 7100ms | **6.7%** | 0% | ❌ Failed |
| **CX33** | Intel | 4 | €5 | 1000ms | 3100ms | 4200ms | **6.0%** | 59% | ❌ Failed |
| **CPX32** | AMD EPYC | 4 | **€10.50** | **35ms** | **190ms** | **440ms** | **0.07%** | **24%** | ✅ **CHAMPION** |

**CPX32 is 93-96% faster with 98-99% fewer failures than all others!**

### Quick Recommendations

| Your Scale | Best Instance | Price | Capacity | Median | Why |
|------------|--------------|-------|----------|--------|-----|
| **0-400 users** | **CX23** | €3/mo | 400 | 46ms | Cheapest, good enough |
| **400-750 users** | **CPX22** | €6/mo | 750 | **35ms** | Best value, fastest at this scale |
| **750-1000 users** | **CX33** | €5/mo | 1000 | 46ms | More cores, great value |
| **1000-1500+ users** | **CPX32** | **€10.50/mo** | **1500+** | **35ms** | **Unbeatable performance!** |

### Value Analysis

| Instance | Peak Capacity | Price | Cost per 100 Users | Value Rating |
|----------|---------------|-------|-------------------|--------------|
| CX23 | 400 | €3.00 | €0.75 | ⭐⭐⭐ |
| CPX22 | 750 | €6.00 | €0.80 | ⭐⭐⭐⭐⭐ Best Budget |
| CX33 | 1000 | €5.00 | **€0.50** | ⭐⭐⭐⭐⭐ Best Value |
| CCX13 | 900 | €12.00 | €1.33 | ⭐⭐⭐ Premium |
| **CPX32** | **1500+** | **€10.50** | **€0.70** | ⭐⭐⭐⭐⭐ **Best Performance** |

**Key Finding**: 4 AMD EPYC cores (CPX32) = best of both worlds. Fast single-thread performance + excellent parallelization. Worth every cent for 1000+ users!

## Maintenance Timeline Schedule

The server is configured with automated maintenance tasks that run at scheduled times to ensure reliability and security:

| Time | Day | Task | Description |
|------|-----|------|-------------|
| 02:30 AM | Daily | Database Backup | PostgreSQL dump of Mattermost database (65-day retention) |
| 03:00 AM | Daily | Container Updates Check | Watchtower checks for new container images |
| 03:10 AM | Every 14 days | Files Backup | Tar archive of Mattermost data, config, plugins (30-day retention) |
| 03:15 AM | Daily | Backup Cleanup | Remove database backups older than 65 days |
| 03:20 AM | Daily | Backup Cleanup | Remove file archives older than 30 days |
| **04:00 AM** | **Tuesday** | **Security Updates** | Automatic installation of Ubuntu security patches |
| **04:30 AM** | **Tuesday** | **Auto-Reboot** | System reboot if required by security updates |

### Maintenance Notes

- **Security updates run only on Tuesdays** to provide a predictable maintenance window
- **Only security patches are installed** (not general updates) to minimize risk of breaking changes
- **Automatic reboot occurs if needed** (e.g., kernel updates) at 4:30 AM
- **Backups complete before updates** ensuring fresh backups exist before any system changes
- **Email notifications sent on failures** to the configured sysadmin email address
- **All maintenance activities are logged** to syslog for audit purposes
- The Tuesday 4:00 AM time slot is chosen to minimize impact on users

### Customizing the Schedule

To change the security update schedule, modify the cron entry in `cloud-init.yaml.tftpl`:
```bash
# Current: Every Tuesday at 4:00 AM
0 4 * * 2 root /usr/bin/unattended-upgrade -v

# Change to different day/time as needed
# Format: minute hour day_of_month month day_of_week
# Example: Sundays at 3:00 AM would be:
# 0 3 * * 0 root /usr/bin/unattended-upgrade -v
```

## Docker Server Directory Mappings

- `/mattermost/MMserver/config` – Mattermost config file (config.json) will be stored here
- `/mattermost/MMserver/data` – All user-uploaded files (images, attachments) will persist here
- `/mattermost/MMserver/logs` – Log files
- `/mattermost/MMserver/plugins` and `client_plugins` – Any installed server or web client plugins
- `/mattermost/MMserver/bleve-indexes` – Search index data (if using Bleve for search)
- `/mattermost/PgSQL/data` – PostgreSQL database files
- `/mattermost/NGINX/cert` - SSL keys obtained from CloudFlare Origin certificate service
- `/backups/MMserver` - Mattermost file backups (mounted from Hetzner Storage Box)
- `/backups/PgSQL` - PostgreSQL database backups (mounted from Hetzner Storage Box)

## SMTP Email Configuration

Email functionality is configured via Terraform variables. The same SMTP credentials are used for both:
1. **Mattermost application emails** (password resets, notifications, etc.)
2. **OS-level security update notifications** (failure alerts)

### Required Variables

Add these to your `terraform.auto.tfvars`:

```hcl
# SMTP credentials (shared by Mattermost and OS notifications)
smtp_username            = "your-email@gmail.com"
smtp_password            = "your-app-password"
smtp_server              = "smtp.gmail.com"
smtp_port                = 587
smtp_connection_security = "STARTTLS"
enable_smtp_auth         = true

# Mattermost email settings
feedback_email   = "mattermost@your.domain"  # Sender for Mattermost emails
reply_to_address = "noreply@your.domain"     # Reply-to for Mattermost

# System administrator email for OS update notifications
sysadmin_email = "admin@your.domain"  # Receives security update failure alerts
```

### Email Notification Behavior

**Security Update Notifications** are configured as `only-on-error`:
- ✅ **Successful updates** - No email sent (silent operation)
- ❌ **Failed updates** - Email sent to `sysadmin_email` with error details
- ❌ **Package conflicts** - Email sent with conflict information
- ❌ **Download failures** - Email sent with failure reasons

This ensures you're only notified when something needs attention, not on every successful update.

### Common SMTP Providers

- **Gmail**: `smtp.gmail.com:587` (use App Password, not regular password)
- **Office 365**: `smtp.office365.com:587`
- **Outlook.com**: `smtp-mail.outlook.com:587`
- **SendGrid**: `smtp.sendgrid.net:587`

### Testing Email Configuration

After deployment, test the OS email system:
```bash
# SSH into your server
ssh -p 46892 root@your-server-ip

# Send a test email
echo "Test email from Mattermost server" | mail -s "Test Email" admin@your.domain

# Check mail logs
sudo tail -f /var/log/mail.log
```

## Security Features

- **Automated security updates** - Only security patches, scheduled for predictable maintenance window
- **Email alerts on failures** - Immediate notification if updates encounter errors
- **Cloudflare Authenticated Origin Pulls** - Server only responds to Cloudflare requests
- **Geographic restriction** - Optional country-based access control via Cloudflare
- **Custom SSH port** - Reduces automated attack surface
- **Fail2ban** - Protection against brute force attacks
- **Automatic backups** - Both Hetzner VM snapshots and application-level backups

## Troubleshooting

### Checking Update Logs

To view automatic update logs:
```bash
sudo journalctl -u unattended-upgrades
sudo cat /var/log/unattended-upgrades/unattended-upgrades.log
```

### Manual Security Update

To manually trigger security updates:
```bash
sudo unattended-upgrade -v
```

### Checking Next Scheduled Update

```bash
sudo cat /etc/cron.d/unattended-upgrades-tuesday
```

### Testing Email Notifications

To test if email notifications work:
```bash
# This will trigger a dry-run and send a test if configured
sudo unattended-upgrade --dry-run -d
```

### Checking Postfix Mail Queue

```bash
# View mail queue
sudo mailq

# View Postfix logs
sudo tail -f /var/log/mail.log
```

## License

MIT