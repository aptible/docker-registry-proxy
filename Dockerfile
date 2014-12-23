FROM quay.io/aptible/ubuntu:14.04

# Install NGiNX.
RUN apt-get update
RUN apt-get install -y software-properties-common \
    python-software-properties && \
    add-apt-repository -y ppa:nginx/stable && apt-get update && \
    apt-get -y install curl ucspi-tcp apache2-utils nginx ruby

# Overwrite default nginx config with our config.
RUN rm /etc/nginx/sites-enabled/*
ADD templates/sites-enabled /

# Add script that starts NGiNX in front of Kibana and tails the NGiNX access/error logs.
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