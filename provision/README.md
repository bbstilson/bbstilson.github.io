# Provision

This directory contains things used to run everything that I want to host on Digital Ocean.

## Deploying

I deploy a [Docker Droplet](https://do.co/2PQDXut) from the DigitalOcean marketplace. At the time of writing, I am using a $5 droplet (1 CPU/1GB RAM/25GB SSD).

I enabled monitoring and backups, and I name the server "personal-site-proxy".

I couldn't get user-data to work, so once the host is up and running, I SSHed onto the box and manually ran everything in the `user_data.sh` script.

If the host ever changes, I need to update the A record in Cloudflare to point to the IP address of the newly created host.
