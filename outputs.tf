output "server_ipv4" { value = hcloud_server.mm.ipv4_address }
output "ssh_example" { value = "ssh root@${hcloud_server.mm.ipv4_address}" }
output "url" { value = "https://${var.domain}" }
output "cloudflare_note" {
  value       = var.enable_cloudflare ? "CF DNS + Origin CA + AOP + country rule configured" : "Cloudflare automation disabled"
  description = "Status"
}
