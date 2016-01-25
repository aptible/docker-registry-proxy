#!/usr/bin/env bats

setup() {
  mkdir /etc/nginx/ssl
  openssl req -x509 -batch -nodes -newkey rsa:2048 -keyout /etc/nginx/ssl/docker-registry-proxy.key \
  -out /etc/nginx/ssl/docker-registry-proxy.crt
}

teardown() {
  /usr/sbin/nginx -s stop
  pkill tail
  rm /etc/nginx/conf.d/docker-registry-proxy.htpasswd || true
  rm /etc/nginx/sites-enabled/docker-registry-proxy || true
  rm -rf /etc/nginx/ssl || true
  rm /var/log/nginx/access.log || true
  rm /var/log/nginx/error.log || true
}

@test "docker-registry-proxy uses an nginx version >= 1.7.5" {
  # We need at least 1.7.5 for built-in handling of chunked transfer encoding (1.3.9)
  # and support for the "always" parameter in the "add_header" directive (1.7.5).
  run apk-install dpkg && \
      dpkg --compare-versions `/usr/sbin/nginx -v 2>&1 | grep -oE "\d+.\d+.\d+"` ">=" "1.7.5" &&
      apk del dpkg
  [ "$status" -eq 0 ]
}

@test "docker-registry-proxy requires the AUTH_CREDENTIALS environment variable to be set" {
  export REGISTRY_PORT=tcp://172.17.0.70:5000
  export DOCKER_REGISTRY_TAG=latest
  run timeout -t 1 /bin/bash run-docker-registry-proxy.sh
  [ "$status" -eq 1 ]
  [[ "$output" =~ "AUTH_CREDENTIALS" ]]
}

@test "docker-registry-proxy requires the REGISTRY_PORT environment variable to be set" {
  export AUTH_CREDENTIALS=foobar:password
  export DOCKER_REGISTRY_TAG=latest
  run timeout -t 1 /bin/bash run-docker-registry-proxy.sh
  [ "$status" -eq 1 ]
  [[ "$output" =~ "REGISTRY_PORT" ]]
}

@test "docker-registry-proxy requires a key in /etc/nginx/ssl" {
  export AUTH_CREDENTIALS=foobar:password
  export REGISTRY_PORT=tcp://172.17.0.70:5000
  export DOCKER_REGISTRY_TAG=latest
  rm /etc/nginx/ssl/docker-registry-proxy.key
  run timeout -t 1 /bin/bash run-docker-registry-proxy.sh
  [ "$status" -eq 1 ]
  [[ "$output" =~ "No key file" ]]
}

@test "docker-registry-proxy returns an error if more than one key is provided" {
  export AUTH_CREDENTIALS=foobar:password
  export REGISTRY_PORT=tcp://172.17.0.70:5000
  export DOCKER_REGISTRY_TAG=latest
  touch /etc/nginx/ssl/extra-key.key
  run timeout -t 1 /bin/bash run-docker-registry-proxy.sh
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Multiple key files" ]]
}

@test "docker-registry-proxy requires a certificate in /etc/nginx/ssl" {
  export AUTH_CREDENTIALS=foobar:password
  export REGISTRY_PORT=tcp://172.17.0.70:5000
  export DOCKER_REGISTRY_TAG=latest
  rm /etc/nginx/ssl/docker-registry-proxy.crt
  run timeout -t 1 /bin/bash run-docker-registry-proxy.sh
  [ "$status" -eq 1 ]
  [[ "$output" =~ "No certificate file" ]]
}

@test "docker-registry-proxy returns an error if more than one certificate is provided" {
  export AUTH_CREDENTIALS=foobar:password
  export REGISTRY_PORT=tcp://172.17.0.70:5000
  export DOCKER_REGISTRY_TAG=latest
  touch /etc/nginx/ssl/extra-cert.crt
  run timeout -t 1 /bin/bash run-docker-registry-proxy.sh
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Multiple certificate files" ]]
}

@test "docker-registry-proxy configures a v1 registry proxy if DOCKER_REGISTRY_TAG is omitted" {
  export AUTH_CREDENTIALS=foobar:password
  export REGISTRY_PORT=tcp://172.17.0.70:5000
  timeout -t 1 /bin/bash run-docker-registry-proxy.sh || true
  run bash -c "ls /etc/nginx/sites-enabled | wc -l"
  [[ "$output" == "1" ]]
  run cat /etc/nginx/sites-enabled/docker-registry-proxy
  [[ "$output" =~ "location /v1" ]]
  [[ ! "$output" =~ "location /v2" ]]
}

@test "docker-registry-proxy configures a v1 registry proxy if DOCKER_REGISTRY_TAG=latest" {
  export AUTH_CREDENTIALS=foobar:password
  export REGISTRY_PORT=tcp://172.17.0.70:5000
  export DOCKER_REGISTRY_TAG=latest
  timeout -t 1 /bin/bash run-docker-registry-proxy.sh || true
  run bash -c "ls /etc/nginx/sites-enabled | wc -l"
  [[ "$output" == "1" ]]
  run cat /etc/nginx/sites-enabled/docker-registry-proxy
  [[ "$output" =~ "location /v1" ]]
  [[ ! "$output" =~ "location /v2" ]]
}

@test "docker-registry-proxy configures a v2 registry proxy if DOCKER_REGISTRY_TAG=2" {
  export AUTH_CREDENTIALS=foobar:password
  export REGISTRY_PORT=tcp://172.17.0.70:5000
  export DOCKER_REGISTRY_TAG=2
  timeout -t 1 /bin/bash run-docker-registry-proxy.sh || true
  run bash -c "ls /etc/nginx/sites-enabled | wc -l"
  [[ "$output" == "1" ]]
  run cat /etc/nginx/sites-enabled/docker-registry-proxy
  [[ ! "$output" =~ "location /v1" ]]
  [[ "$output" =~ "location /v2" ]]
}

@test "docker-registry-proxy configures a v2 registry proxy if DOCKER_REGISTRY_TAG=2.2" {
  export AUTH_CREDENTIALS=foobar:password
  export REGISTRY_PORT=tcp://172.17.0.70:5000
  export DOCKER_REGISTRY_TAG=2.2
  timeout -t 1 /bin/bash run-docker-registry-proxy.sh || true
  run bash -c "ls /etc/nginx/sites-enabled | wc -l"
  [[ "$output" == "1" ]]
  run cat /etc/nginx/sites-enabled/docker-registry-proxy
  [[ ! "$output" =~ "location /v1" ]]
  [[ "$output" =~ "location /v2" ]]
}
