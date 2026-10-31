resource "cloudflare_zero_trust_tunnel_cloudflared" "tunnel" {
  account_id = var.account_id
  name       = var.tunnel_name
  config_src = "cloudflare"
}

locals {
  ingress = concat(
    [for key, value in var.services : {
      hostname = "${key}.${var.zone_a.domain}"
      service  = value
      }
    ],
    [{
      service = "http_status:404"
    }]
  )
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "tunnel_config" {
  account_id = var.account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.tunnel.id
  config = {
    ingress = local.ingress
  }
}

resource "cloudflare_dns_record" "tunnel_records_zone_a" {
  for_each = var.services

  zone_id = var.zone_a.zone_id
  type    = "CNAME"
  name    = each.key
  content = "${cloudflare_zero_trust_tunnel_cloudflared.tunnel.id}.cfargotunnel.com"
  ttl     = 1
  proxied = true
  comment = join(" - ", var.tags)
}
