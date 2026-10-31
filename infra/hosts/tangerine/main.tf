resource "hcloud_primary_ip" "ipv4" {
  name        = "tangerine-ipv4"
  location    = "hel1"
  type        = "ipv4"
  auto_delete = false
}

resource "hcloud_primary_ip" "ipv6" {
  name        = "tangerine-ipv6"
  location    = "hel1"
  type        = "ipv6"
  auto_delete = false
}

resource "hcloud_firewall" "firewall" {
  name = "tangerine-firewall"
  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "22"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
}

resource "hcloud_server" "server" {
  name               = "tangerine"
  server_type        = "cx23"
  location           = "hel1"
  delete_protection  = true
  rebuild_protection = true
  public_net {
    ipv4_enabled = true
    ipv4         = hcloud_primary_ip.ipv4.id
    ipv6_enabled = true
    ipv6         = hcloud_primary_ip.ipv6.id
  }
  firewall_ids = [hcloud_firewall.firewall.id]
}


resource "cloudflare_dns_record" "records_zone_a" {
  for_each = {
    "A"    = hcloud_primary_ip.ipv4.ip_address
    "AAAA" = cidrhost(hcloud_primary_ip.ipv6.ip_network, 1)
  }
  zone_id = var.zone_a.zone_id
  type    = each.key
  name    = "tangerine.${var.zone_a.domain}"
  content = each.value
  ttl     = 1
  proxied = false
  comment = join(" - ", var.tags)
}
