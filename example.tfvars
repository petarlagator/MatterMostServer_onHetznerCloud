# Duplicate this file and name it terraform.auto.tfvars. 
# terraform.auto.tfvars is already added to the .gitignore file so it will never be uploaded to git in case you save your forked project there
# Set variables as you see fit

# API key for your Hetzner Cloud project that you have created for this
hcloud_token        = "xxx"
# Server instance size and type
server_type         = "cx23"
# Hetzner Datacenter location: nbg1 for Nurmberg is default
location            = "nbg1"

# Your SSH public key so you can remote into the server when its created
ssh_public_key      = "ssh-ed25519 AAAAC3... your@host"
# SSH custom port number for security hardening (default: 46892) 
ssh_port = 46892
# The name of the server (VM) that you are creating on hetzner cloud
server_name         = "MattermostTestServer.your.domain"
# The DNS name over which this instance will be available over the internet
domain              = "mattermost.your.domain"

# PGSQL DB name and credentials
db_user             = "mattermost"
db_password         = "CHANGE_ME_LONG_RANDOM"
db_name             = "mattermost"

# Name and credentials of the storage box you have created in your Hetzner project that will host the backups
# This you have to create by hand and destroy by hand so it will not be able to be destroyed when invoking "terraform destroy" by intent or accident
# This way backups will persist trough terraform changes and disasters and can be accessed from another instance in case of emergency
storage_box_host     = "u123456.your-storagebox.de"
storage_box_user     = "u123456"
storage_box_password = "CHANGE_ME_STORAGEBOX"
storage_box_backup_dir = "mattermost-backups"

# Your cloudflare account API key and DNS zone ID to which you will bind this server
enable_cloudflare     = true
cloudflare_api_token  = "xxx"
cloudflare_zone_id    = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
# Country codes for CloudFlare Georestriction - your MatterMost instance will be available for use only from these countries, saves you from some bots and hackers
restrict_country_code = "ME"

# The HTTP/S server for Mattermost will be available only via cloudflare. It will not respond to direct ip address HTTP/S requests if someone gets to it via brute force or Hetzner IP range service discovery. Potentially saves you from some more bots and hackers.
restrict_to_cloudflare_ips = true
# Enable portainer if you want a GUI for viewing container statuses inside the server. Disable if you do it via CLI or want to save on resources. 
enable_portainer           = true

# SMTP Configuration
# These credentials are used for both Mattermost email notifications AND OS-level security update notifications
# Configure these to enable email functionality (password resets, notifications, etc.)
smtp_username            = "your-email@example.com"
smtp_password            = "your-smtp-password"
smtp_server              = "smtp.example.com"  # e.g., smtp.gmail.com, smtp.office365.com
smtp_port                = 587                  # 587 for STARTTLS, 465 for TLS
smtp_connection_security = "STARTTLS"           # STARTTLS, TLS, or empty string
enable_smtp_auth         = true
feedback_email           = "mattermost@your.domain"  # Email shown as sender in Mattermost
reply_to_address         = "noreply@your.domain"     # Reply-to address for Mattermost

# System administrator email for OS security update failure notifications
# This email will receive alerts if automatic security updates encounter errors
sysadmin_email = "admin@your.domain"

# Block Storage Volume Configuration
# Name of the Hetzner block storage volume that will hold all persistent Mattermost data
volume_name = "mattermost-data-volume"
# Size of the block storage volume in GB (default: 30GB)
volume_size = 30
