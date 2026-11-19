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

resource "hcloud_ssh_key" "main" {
  name       = "id_ed25519"
  public_key = file(var.ssh_public_key_location)
}

locals {
  target_rfc_key = "id_rfc.pub"
}
# Convert the SSH key to RFC4716 format for Hetzner
resource "terraform_data" "convert_key" {
  triggers_replace = [
    filemd5(var.ssh_public_key_location)
  ]

  provisioner "local-exec" {
    command = "ssh-keygen -e -f ${var.ssh_public_key_location} > ${local.target_rfc_key}"
  }
}

# 2. Read the generated file once the command finishes
data "local_file" "rfc4716_key" {
  filename   = local.target_rfc_key
  depends_on = [terraform_data.convert_key]
}

# Hetzner doesn't provide wo password
resource "random_password" "backups_password" {
  length           = 128
  override_special = "^!$%/()=?+#-.,;:~*@{}_&"
}

resource "hcloud_storage_box" "backups" {
  name             = "backups"
  storage_box_type = "bx11"
  location         = "hel1"
  # We don't care about the password as we access via ssh key, but field is
  # required
  password = random_password.backups_password.result

  ssh_keys = [
    hcloud_ssh_key.main.public_key,
    data.local_file.rfc4716_key.content
  ]

  access_settings = {
    ssh_enabled          = true
    reachable_externally = true
  }

  snapshot_plan = {
    max_snapshots = 3
    minute        = 0
    hour          = 4
    day_of_month  = 1
  }

  delete_protection = true

  lifecycle {
    ignore_changes = [
      ssh_keys
    ]

    prevent_destroy = true
  }
}
