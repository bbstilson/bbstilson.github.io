terraform {
  required_version = "~> 1.0.0"

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 3.3"
    }
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
    doppler = {
      source = "DopplerHQ/doppler"
      version = "~> 1.0"
    }
  }
}

variable "doppler_token" {}

provider "cloudflare" {}
provider "digitalocean" {}
provider "doppler" {
  doppler_token = var.doppler_token
  verify_tls = true
}
