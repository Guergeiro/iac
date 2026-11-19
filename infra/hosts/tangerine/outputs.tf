output "hetzner_server_ip" {
  value = {
    ipv4 = hcloud_primary_ip.ipv4.ip_address
    ipv6 = cidrhost(hcloud_primary_ip.ipv6.ip_network, 1)
  }
}

output "hetzner_backups" {
  value = {
    server   = hcloud_storage_box.backups.server
    username = hcloud_storage_box.backups.username
  }
}
