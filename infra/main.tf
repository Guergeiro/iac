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

resource "cloudflare_dns_record" "tunnel_records_zone_b" {
  for_each = var.zone_b != null ? var.services : {}

  zone_id = var.zone_b.zone_id
  type    = "CNAME"
  name    = each.key
  content = "${each.key}.${var.zone_a.domain}"
  ttl     = 1
  proxied = true
  comment = join(" - ", var.tags)
}

resource "cloudflare_page_rule" "redirects" {
  count = var.zone_b != null ? 1 : 0

  provider = cloudflare.page-rules
  zone_id  = var.zone_b.zone_id
  target   = "*.${var.zone_b.domain}/*"
  priority = 1
  status   = "active"
  actions = {
    forwarding_url = {
      url         = "https://$1.${var.zone_a.domain}/$2"
      status_code = 301
    }
  }
}
