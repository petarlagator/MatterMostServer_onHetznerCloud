# -----------------------------------------------------
# SSH key for Hetzner server
# -----------------------------------------------------
resource "hcloud_ssh_key" "me" {
  name       = "mm-admin-key"
  public_key = var.ssh_public_key
}

# -----------------------------------------------------
# Hetzner Firewall
# -----------------------------------------------------
resource "hcloud_firewall" "mm" {
  name = "${var.server_name}-fw"

  # SSH open to all (for your secure Hetzner firewall rules to limit externally)
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = var.ssh_port
    source_ips = ["0.0.0.0/0", "::/0"]
  }


  # HTTPS restricted to Cloudflare IPs if enabled
  dynamic "rule" {
    for_each = var.restrict_to_cloudflare_ips ? var.cloudflare_ip_ranges : ["0.0.0.0/0", "::/0"]
    content {
      direction  = "in"
      protocol   = "tcp"
      port       = "443"
      source_ips = [rule.value]
    }
  }
}

# -----------------------------------------------------
# Cloudflare Configuration
# -----------------------------------------------------
# DNS A record for Mattermost
resource "cloudflare_dns_record" "mm_a" {
  count   = var.enable_cloudflare ? 1 : 0
  zone_id = var.cloudflare_zone_id
  name    = var.domain
  type    = "A"
  content = hcloud_server.mm.ipv4_address
  proxied = true
  ttl     = 1
}

# Generate private key for origin cert
resource "tls_private_key" "origin_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_cert_request" "origin_csr" {
  private_key_pem = tls_private_key.origin_key.private_key_pem

  subject {
    common_name = var.domain
  }
}


resource "cloudflare_origin_ca_certificate" "origin" {
  count              = var.enable_cloudflare ? 1 : 0
  csr                = tls_cert_request.origin_csr.cert_request_pem
  hostnames          = [var.domain]
  request_type       = "origin-rsa"
  requested_validity = 5475
}



# Free-tier Geo Restriction (Rulesets API)
resource "cloudflare_ruleset" "geo_lock" {
  count       = var.enable_cloudflare ? 1 : 0
  zone_id     = var.cloudflare_zone_id
  name        = "Geo Restriction for ${var.domain}"
  description = "Block all but ${var.restrict_country_code}"
  kind        = "zone"
  phase       = "http_request_firewall_custom"

  rules = [{
    action      = "block"
    description = "Block all except ${var.restrict_country_code}"
    enabled     = true
    expression  = "(not ip.geoip.country in {\"${var.restrict_country_code}\"}) and http.host eq \"${var.domain}\""
  }]
}

# -----------------------------------------------------
# Cloud-init template for Docker, Nginx, MM, Portainer, Backups
# -----------------------------------------------------
data "template_file" "cloud_init" {
  template = file("${path.module}/cloud-init.yaml.tftpl")

  vars = {
    domain               = var.domain
    db_user              = var.db_user
    db_password          = var.db_password
    db_name              = var.db_name
    storage_box_host     = var.storage_box_host
    storage_box_user     = var.storage_box_user
    storage_box_password = var.storage_box_password
    watchtower_api_token = var.watchtower_api_token
    ssh_port             = var.ssh_port

    # Fix PEM formatting and indent 6 spaces for YAML
    origin_cert = indent(6, replace(trimspace(cloudflare_origin_ca_certificate.origin[0].certificate), "\\n", "\n"))
    origin_key  = indent(6, replace(trimspace(tls_private_key.origin_key.private_key_pem), "\\n", "\n"))
  }
}


# -----------------------------------------------------
# Hetzner Server (CPX22 / NBG1)
# -----------------------------------------------------
resource "hcloud_server" "mm" {
  name        = var.server_name
  server_type = var.server_type
  image       = "ubuntu-24.04"
  location    = var.location
  ssh_keys    = [hcloud_ssh_key.me.id]
  user_data   = data.template_file.cloud_init.rendered
  backups     = true # Enable automatic snapshots/backups
}

# Attach the firewall to the server
resource "hcloud_firewall_attachment" "mm_attach" {
  firewall_id = hcloud_firewall.mm.id
  server_ids  = [hcloud_server.mm.id]
}

# -----------------------------------------------------
# End of configuration
# -----------------------------------------------------
