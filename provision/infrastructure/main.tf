terraform {
  required_version = "~> 1.0.0"

  required_providers {
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

variable "digitalocean_token" {}
variable "doppler_token" {}

# Configure the DigitalOcean Provider
provider "digitalocean" {
  token = var.digitalocean_token
}

provider "doppler" {
  doppler_token = var.doppler_token
  verify_tls = true
}
