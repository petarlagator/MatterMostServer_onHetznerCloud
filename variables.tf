variable "hcloud_token" {
  type      = string
  sensitive = true
}

variable "server_name" {
  type    = string
  default = "MatterMostOnHetznerCloudTest"
}

variable "server_type" {
  type    = string
  default = "cx33"
}

variable "location" {
  type    = string
  default = "nbg1"
}

variable "ssh_public_key" {
  type        = string
  description = "Your SSH public key (e.g. ~/.ssh/id_ed25519.pub)"
}

variable "domain" {
  type    = string
  default = "mattermost.your.domain"
}

variable "db_user" {
  type    = string
  default = "mattermost"
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "db_name" {
  type    = string
  default = "mattermost"
}

variable "storage_box_host" {
  type = string
}

variable "storage_box_user" {
  type = string
}

variable "storage_box_password" {
  type      = string
  sensitive = true
}

variable "storage_box_backup_dir" {
  type        = string
  description = "Subdirectory name on storage box for this Mattermost instance backups"
  default     = "mattermost-backups"
}

variable "enable_cloudflare" {
  type    = bool
  default = true
}

variable "cloudflare_api_token" {
  type      = string
  sensitive = true
}

variable "cloudflare_zone_id" {
  type = string
}

variable "restrict_country_code" {
  type    = string
  default = "ME"
}

variable "restrict_to_cloudflare_ips" {
  type    = bool
  default = true
}

variable "cloudflare_ip_ranges" {
  type = list(string)
  default = [
    "173.245.48.0/20",
    "103.21.244.0/22",
    "103.22.200.0/22",
    "103.31.4.0/22",
    "141.101.64.0/18",
    "108.162.192.0/18",
    "190.93.240.0/20",
    "188.114.96.0/20",
    "197.234.240.0/22",
    "198.41.128.0/17",
    "162.158.0.0/15",
    "104.16.0.0/13",
    "104.24.0.0/14",
    "172.64.0.0/13",
    "131.0.72.0/22",
    "2400:cb00::/32",
    "2606:4700::/32",
    "2803:f800::/32",
    "2405:b500::/32",
    "2405:8100::/32",
    "2a06:98c0::/29",
    "2c0f:f248::/32"
  ]
}

variable "enable_portainer" {
  type    = bool
  default = true
}

variable "watchtower_api_token" {
  description = "HTTP API token for Watchtower (used for /v1/update etc.). Change this to a strong value."
  type        = string
  default     = "changeme-please"
}

variable "ssh_port" {
  type        = number
  default     = 46892
  description = "SSH server port"
}

# SMTP Configuration Variables
variable "smtp_username" {
  type        = string
  description = "SMTP authentication username"
  default     = ""
}

variable "smtp_password" {
  type        = string
  description = "SMTP authentication password"
  sensitive   = true
  default     = ""
}

variable "smtp_server" {
  type        = string
  description = "SMTP server hostname (e.g., smtp.gmail.com)"
  default     = ""
}

variable "smtp_port" {
  type        = number
  description = "SMTP server port (e.g., 587 for STARTTLS, 465 for TLS)"
  default     = 587
}

variable "smtp_connection_security" {
  type        = string
  description = "SMTP connection security: STARTTLS, TLS, or empty string for none"
  default     = "STARTTLS"
  validation {
    condition     = contains(["", "STARTTLS", "TLS"], var.smtp_connection_security)
    error_message = "smtp_connection_security must be STARTTLS, TLS, or empty string."
  }
}

variable "enable_smtp_auth" {
  type        = bool
  description = "Enable SMTP authentication"
  default     = true
}

variable "feedback_email" {
  type        = string
  description = "Email address displayed on email notifications sent from Mattermost"
  default     = ""
}

variable "reply_to_address" {
  type        = string
  description = "Email address used in the Reply-To header when sending notification emails"
  default     = ""
}

variable "sysadmin_email" {
  type        = string
  description = "System administrator email address for OS security update notifications (failures and errors)"
  default     = ""
}

variable "storage_box_backup_dir" {
  type        = string
  description = "Subdirectory name on storage box for this Mattermost instance backups"
  default     = "mattermost-backups"
}
