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
