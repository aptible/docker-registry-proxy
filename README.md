# ![](https://gravatar.com/avatar/11d3bc4c3163e3d238d558d5c9d98efe?s=64) aptible/docker-registry-proxy

[![Docker Repository on Quay.io](https://quay.io/repository/aptible/registry-proxy/status)](https://quay.io/repository/aptible/registry-proxy)

An NGiNX proxy for [Docker registries](https://github.com/docker/docker-registry)
that terminates SSL and enforces HTTP basic authentication.

## Background

A Docker registry server lets you store and retrieve Docker images via
`docker pull` and `docker push`. This repository builds a Docker container that
runs NGiNX in front of such a registry server, handling SSL termination and
enforcing HTTP basic authentication.

This repository follows the [recommended Docker registry server NGiNX config for NGiNX 1.3.9 and later](https://github.com/docker/docker-registry/blob/master/contrib/nginx/nginx_1-3-9.conf) from the Docker registry server repo.

## Usage

First, pull the latest image from Quay:

```
docker pull quay.io/aptible/registry-proxy
```

Alternatively, you can build the image locally from this a clone of this repo by running `make build`.

You need three things to run this proxy in front of a Docker registry:

1. A running [Docker registry](https://github.com/docker/docker-registry).
2. A directory containing an SSL key pair.
3. A comma-separated list of colon-delimited basic auth credentials, e.g., "user1:password1,user2:password2".

Once you have everything in the list above, you can launch the registry proxy container. Here's an
example:

```bash
# Run the Docker registry on port 5000 as a 'local' registry with images stored in /tmp.
INTERNAL_PORT=5000
docker run -itd --name docker-registry -p $INTERNAL_PORT:5000 -e SETTINGS_FLAVOR=local registry

# EXTERNAL_PORT is the port where this proxy (and therefore, the registry) will be exposed.
EXTERNAL_PORT=46022

# KEYPAIR_DIRECTORY should contain a .crt and .key.
KEYPAIR_DIRECTORY=/tmp/my-certs

# AUTH_CREDENTIALS contains one or more user:password pairs, separated by commas.
AUTH_CREDENTIALS=admin:admin123

REGISTRY_IP=`docker inspect docker-registry | grep -oP "\"IPAddress\": \"\K[^\"]*"`
docker run -itd -p "$EXTERNAL_PORT":443 \
    -e AUTH_CREDENTIALS=$AUTH_CREDENTIALS \
    -e REGISTRY_SERVER=$REGISTRY_IP:$INTERNAL_PORT \
    -v $KEYPAIR_DIRECTORY:/etc/nginx/ssl \
    quay.io/aptible/docker-registry-proxy
```

## Deployment

To build and push this Docker image to Quay, run `make release`.

## Copyright and License

MIT License, see [LICENSE](LICENSE.md) for details.

Copyright (c) 2014 [Aptible](https://www.aptible.com) and contributors.

[<img src="https://s.gravatar.com/avatar/c386daf18778552e0d2f2442fd82144d?s=60" style="border-radius: 50%;" alt="@aaw" />](https://github.com/aaw)
