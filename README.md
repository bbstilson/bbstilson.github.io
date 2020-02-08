# Personal Site

[Personal Site](https://brandonstilson.com)

I wanted to self-host comment and analytics services using privacy-focused, OSS tools, but also have Github host the actual content. I use NGINX as a reverse-proxy to send traffic accordingly:

![personal site diagram](./personal_site_diagram.png)

Everything is hosted on a single Digital Ocean Droplet in a single Docker Compose network at the moment.

For commenting, I run [Commento](https://www.commento.io/).
For analytics, I run [Ackee](https://ackee.electerious.com/).

Built on the [reverie theme](https://www.amitmerchant.com/reverie/).
