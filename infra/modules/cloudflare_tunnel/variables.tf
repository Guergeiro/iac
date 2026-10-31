variable "account_id" {
  type        = string
  description = "Cloudflare Account ID"
}

variable "tunnel_name" {
  type        = string
  description = "Name of the cloudflared tunnel"
}

variable "services" {
  type        = map(string)
  description = "Map of subdomain key -> internal service target URL"
  default     = {}
}

variable "zone_a" {
  type = object({
    zone_id = string
    domain  = string
  })
}

variable "tags" {
  type    = list(string)
  default = ["owner:terraform", "repository:iac"]
}
