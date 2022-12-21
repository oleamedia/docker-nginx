# docker-nginx

[![Docker Pulls](https://img.shields.io/docker/pulls/oleamedia/nginx?color=brightgreen)](https://hub.docker.com/r/oleamedia/nginx)
![GitHub](https://img.shields.io/github/license/oleamedia/docker-nginx)
[![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-v2.0%20adopted-ff69b4.svg)](code_of_conduct.md)

Alpine Linux image with nginx with HTTP/3 (QUIC), TLSv1.3, brotli, NJS, Cookie-Flag support, and RTMP.

Sources are available on
[Github](https://github.com/oleamedia/docker-nginx).

Images are available on
[Docker Hub](https://hub.docker.com/r/oleamedia/nginx).

## Usage

**Docker Hub:** `docker pull oleamedia/nginx`

This is a base image like the default _nginx_ image. It is meant to be used as a
drop-in replacement for the nginx base image.

Example:

```Dockerfile
# Base Nginx HTTP/3 Image
FROM oleamedia/nginx:latest

# Copy your certs.
COPY ssl/* /etc/ssl/

# Copy config files.
COPY nginx.conf /etc/nginx/
COPY conf.d/* /etc/nginx/conf.d/
COPY sites-available/* /etc/nginx/sites-available/
COPY sites-enabled/* /etc/nginx/sites-enabled/
RUN  chown -R nginx:nginx /etc/nginx/
```

H3 runs over UDP so, you will need to port map both TCP and UDP. Ex:
`docker run -p 80:80 -p 443:443/tcp -p 443:443/udp ...`

**NOTE**: Please note that you need a valid
[CA](https://en.wikipedia.org/wiki/Certificate_authority) signed certificate for
the client to upgrade you to HTTP/3. [Let's Encrypt](https://letsencrypt.org/)
is a option for getting a free valid CA signed certificate.

## Features

- HTTP/3 (QUIC)
- HTTP/2 (with Server Push)
- HTTP/2
- BoringSSL (Google's flavor of OpenSSL)
- RTMP 1.2.2
- TLS 1.3
- Brotli compression
- [headers-more-nginx-module](https://github.com/openresty/headers-more-nginx-module)
- [NJS](https://www.nginx.com/blog/introduction-nginscript/)
- [nginx_cookie_flag_module](https://www.nginx.com/products/nginx/modules/cookie-flag/)
- Alpine Linux (total size of **10 MB** compressed)

