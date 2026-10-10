variable "cf_api_token" {
  type      = string
  sensitive = true
}

variable "cf_api_token_page_rules" {
  type      = string
  sensitive = true
}

variable "account_id" {
  type = string
}

variable "zone_a" {
  type = object({
    zone_id = string
    domain  = string
  })
}

variable "zone_b" {
  type = object({
    zone_id = string
    domain  = string
  })
  default = null
}

variable "tunnel_name" {
  type = string
}

variable "services" {
  type    = map(string)
  default = {}
}

variable "tags" {
  default = ["owner:terraform", "repository:iac"]
}
