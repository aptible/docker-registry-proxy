FROM quay.io/aptible/alpine:latest

# Install NGiNX.
RUN apk-install apache2-utils curl nginx openssl ruby

# Ensure that the nginx user can write to temp paths like client_body_temp_path.
RUN chown -R nginx:nginx /var/lib/nginx

# Overwrite default nginx config with our config.
RUN mkdir -p /etc/nginx/sites-enabled
ADD nginx.conf /etc/nginx/nginx.conf
ADD templates/sites-enabled /

# Add script that starts NGiNX in front of the registries and tails the NGiNX access/error logs.
ADD bin .
RUN chmod 700 ./run-docker-registry-proxy.sh

# Run tests.
ADD test /tmp/test
RUN bats /tmp/test

# When running a container from this image, map a directory containing
# docker-registry-proxy.crt and docker-registry-proxy.key to this volume, e.g.,
# "-v /path/to/my/keys:/etc/nginx/ssl"
VOLUME /etc/nginx/ssl

EXPOSE 443

CMD ["./run-docker-registry-proxy.sh"]
