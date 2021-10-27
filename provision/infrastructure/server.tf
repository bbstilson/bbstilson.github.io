data "doppler_secrets" "secrets" {
  project = "development"
  config = "all"
}

resource "digitalocean_droplet" "brandonstilson" {
  image = "docker-20-04"
  name = "brandonstilson"
  region = "sfo2"
  size = "s-1vcpu-1gb"
  monitoring = true
  backups = false
  ssh_keys = [ data.doppler_secrets.secrets.map.DIGITAL_OCEAN_SSH_KEY_ID ]
  user_data = file("userdata.sh")
}
