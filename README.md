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
3. Auth Credentials
* A comma-separated list of colon-delimited basic auth credentials, e.g., "user1:password1,user2:password2".
* Or a htpasswd file created with htpasswd to be mounted

Once you have everything in the list above, you can launch the registry proxy container. Here's an
example:

With comma-separated list of credentials:

```bash
# Run the Docker registry as a 'local' registry with images stored in /tmp.
docker run -itd --name docker-registry -P -e SETTINGS_FLAVOR=local registry

# EXTERNAL_PORT is the port where this proxy (and therefore, the registry) will be exposed.
EXTERNAL_PORT=46022

# KEYPAIR_DIRECTORY should contain a .crt and .key.
KEYPAIR_DIRECTORY=/tmp/my-certs

# AUTH_CREDENTIALS contains one or more user:password pairs, separated by commas.
AUTH_CREDENTIALS=admin:admin123

# Run the registry proxy container. The registry container must be linked in as
# 'registry' to allow the proxy to discover the address it's listening to.
docker run -itd --link docker-registry:registry \
    -p "$EXTERNAL_PORT":443 \
    -e AUTH_CREDENTIALS=$AUTH_CREDENTIALS \
    -v $KEYPAIR_DIRECTORY:/etc/nginx/ssl \
    quay.io/aptible/registry-proxy
```

If you would rather use an htpasswd file directly:

```bash
# Run the Docker registry as a 'local' registry with images stored in /tmp.
docker run -itd --name docker-registry -P -e SETTINGS_FLAVOR=local registry

# EXTERNAL_PORT is the port where this proxy (and therefore, the registry) will be exposed.
EXTERNAL_PORT=46022

# KEYPAIR_DIRECTORY should contain a .crt and .key.
KEYPAIR_DIRECTORY=/tmp/my-certs

# CREDENTIALS_LOCATION absolute path to credentials file
CREDENTIALS_LOCATION=/tmp/my-passwords.htpasswd

# Run the registry proxy container. The registry container must be linked in as
# 'registry' to allow the proxy to discover the address it's listening to.
docker run -itd --link docker-registry:registry \
    -p "$EXTERNAL_PORT":443 \
    -v $CREDENTIALS_LOCATION:/etc/nginx/conf.d/docker-registry-proxy.htpasswd \
    -v $KEYPAIR_DIRECTORY:/etc/nginx/ssl \
    quay.io/aptible/registry-proxy
```

## Deployment

To build and push this Docker image to Quay, run `make release`.

### Continuous Deployment

The `master` branch of this repo is deployed to the "staging" OpsWorks stack upon a successful build.

### Credentials for CI

This repo contains a `.travis.yml` file that will automatically deploy the application to staging. 
To do this, our AWS credentials and our quay.io credentials for the "deploy-opsworks" user are encrypted and stored on Travis. 
To update these credentials, run the following commands (inserting the credential values):

    echo AWS_ACCESS_KEY_ID=... AWS_SECRET_ACCESS_KEY=... DOCKER_EMAIL=... DOCKER_USERNAME=... DOCKER_PASSWORD=... > .env
    cat .env | travis encrypt -r aptible/registry-proxy --split
    
Update .travis.yml with the output that the command produces. Make sure to prepend each `secure` line with a `-`, and insert
these lines under the `global` section of the .travis.yml file. It should look something like this:

    env:
       global:
         - secure: ...
         - secure: ...
         - secure: ...
         - secure: ...
         - secure: ...

## Copyright and License

MIT License, see [LICENSE](LICENSE.md) for details.

Copyright (c) 2014 [Aptible](https://www.aptible.com) and contributors.

[<img src="https://s.gravatar.com/avatar/c386daf18778552e0d2f2442fd82144d?s=60" style="border-radius: 50%;" alt="@aaw" />](https://github.com/aaw)
