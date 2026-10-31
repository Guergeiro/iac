module "tunnel" {
  source      = "../../modules/cloudflare_tunnel"
  account_id  = var.account_id
  tunnel_name = var.tunnel_name
  services    = var.services
  zone_a      = var.zone_a
  tags        = var.tags
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
  count    = var.zone_b != null ? 1 : 0
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

moved {
  from = cloudflare_zero_trust_tunnel_cloudflared.tunnel
  to   = module.tunnel.cloudflare_zero_trust_tunnel_cloudflared.tunnel
}

moved {
  from = cloudflare_zero_trust_tunnel_cloudflared_config.tunnel_config
  to   = module.tunnel.cloudflare_zero_trust_tunnel_cloudflared_config.tunnel_config
}

moved {
  from = cloudflare_dns_record.tunnel_records_zone_a
  to   = module.tunnel.cloudflare_dns_record.tunnel_records_zone_a
}
