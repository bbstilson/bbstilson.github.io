output "ip_address" {
  value = digitalocean_droplet.brandonstilson.ipv4_address
  description = "The public IP address of your Droplet application."
}
