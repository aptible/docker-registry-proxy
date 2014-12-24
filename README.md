# ![](https://gravatar.com/avatar/11d3bc4c3163e3d238d558d5c9d98efe?s=64) aptible/docker-registry-proxy

[![Docker Repository on Quay.io](https://quay.io/repository/aptible/docker-registry-proxy/status)](https://quay.io/repository/aptible/docker-registry-proxy)

An NGiNX proxy for [Docker registries](https://github.com/docker/docker-registry)
that terminates SSL and requires basic auth.

## Background

A Docker registry server lets you store and retrieve Docker images via
`docker pull` and `docker push`. This repository builds a Docker container that
runs NGiNX in front of such a registry server, handling SSL termination and
enforcing HTTP basic authentication.

This repository follows the [https://github.com/docker/docker-registry/blob/master/contrib/nginx/nginx_1-3-9.conf]
(recommended Docker registry server NGiNX config for NGiNX 1.3.9 and later) from the Docker registry server repo.

## Usage

First, pull the latest image from Quay:

```
docker pull quay.io/aptible/registry-proxy
```

Alternatively, you can build the image locally by running `make build`.

You need three things to run this proxy in front of a Docker registry:

1. A running [Docker registry](https://github.com/docker/docker-registry).
2. An SSL key pair named `docker-registry-proxy.crt` and `docker-registry-proxy.key`.
3. Basic auth credentials in the form "user1:password1,user2:password2".

Once you have everything in the list above, you can launch the registry proxy container.
Assuming the Docker registry is running on `localhost:5000`, the key pair is in the
local directory `/home/aaron/keys`, and the basic auth credentials you want to use
are `admin:pa55w0rd`, run:

```
docker run -itd -e AUTH_CREDENTIALS=admin:pa55w0rd REGISTRY_SERVER=localhost:5000 -v /home/aaw/keys:/etc/nginx/ssl quay.io/aptible/registry-proxy
```

## Deployment

To build and push this Docker image to Quay, run `make release`.

## Copyright and License

MIT License, see [LICENSE](LICENSE.md) for details.

Copyright (c) 2014 [Aptible](https://www.aptible.com) and contributors.

[<img src="https://s.gravatar.com/avatar/c386daf18778552e0d2f2442fd82144d?s=60" style="border-radius: 50%;" alt="@aaw" />](https://github.com/aaw)
