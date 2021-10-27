data "cloudflare_zone" "brandonstilson" {
  name = "brandonstilson.com"
}

resource "cloudflare_record" "brandonstilson" {
  zone_id = data.cloudflare_zone.brandonstilson.id
  name    = "brandonstilson.com"
  value   = digitalocean_droplet.brandonstilson.ipv4_address
  type    = "A"
  ttl     = 300
}

resource "cloudflare_record" "www" {
  zone_id = data.cloudflare_zone.brandonstilson.id
  name    = "www"
  value   = digitalocean_droplet.brandonstilson.ipv4_address
  type    = "A"
  ttl     = 1 # automatic
  proxied = true
}

resource "cloudflare_record" "minecraft" {
  zone_id = data.cloudflare_zone.brandonstilson.id
  name    = "minecraft"
  value   = digitalocean_droplet.brandonstilson.ipv4_address
  type    = "A"
  ttl     = 1 # automatic
  proxied = true
}
