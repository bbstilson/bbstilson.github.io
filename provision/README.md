# Provision

Since I want to self-host comments and analytics using privacy-focused tools, but also have Github host the actual content, I use NGINX as a reverse-proxy to send traffic accordingly:

Everything is hosted on a single Digital Ocean Droplet in a single Docker Compose network.

## Deploying

I deploy a [Docker Droplet](https://cloud.digitalocean.com/marketplace/5ba19751fc53b8179c7a0071?i=9e6a44) from the DigitalOcean marketplace. At the time of writing, I am using a $5 droplet (1 CPU/1GB RAM/25GB SSD).

I enabled "User data", "Monitoring", and backups, and I name the server "personal-site-proxy".


## Comments

[Commento](https://www.commento.io/).

## Analytics

[Ackee](https://ackee.electerious.com/).
