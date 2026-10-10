terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5"
    }
  }
  backend "s3" {
    region                      = "auto"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
    use_path_style              = true
    endpoints                   = { s3 = "https://${var.account_id}.eu.r2.cloudflarestorage.com" }
  }
}

provider "cloudflare" {
  api_token = var.cf_api_token
}

provider "cloudflare" {
  alias     = "page-rules"
  api_token = var.cf_api_token_page_rules
}
