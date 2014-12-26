#!/usr/bin/env bats

setup() {
  mkdir /etc/nginx/ssl
  openssl req -x509 -batch -nodes -newkey rsa:2048 -keyout /etc/nginx/ssl/docker-registry-proxy.key \
  -out /etc/nginx/ssl/docker-registry-proxy.crt
}

teardown() {
  service nginx stop
  rm /etc/nginx/conf.d/docker-registry-proxy.htpasswd || true
  rm /etc/nginx/sites-enabled/docker-registry-proxy || true
  rm -rf /etc/nginx/ssl || true
  rm /var/log/nginx/access.log || true
  rm /var/log/nginx/error.log || true
  pkill tcpserver || true
}

@test "docker-registry-proxy uses an nginx version >= 1.3.9" {
  # We need at least 1.3.9 for built-in handling of chunked transfer encoding.
  run dpkg --compare-versions `/usr/sbin/nginx -v 2>&1 | grep -oP "\d+.\d+.\d+"` ">=" "1.3.9"
  [ "$status" -eq 0 ]
}

@test "docker-registry-proxy requires the AUTH_CREDENTIALS environment variable to be set" {
  export REGISTRY_SERVER=localhost:5000
  run timeout 1 /bin/bash run-docker-registry-proxy.sh
  [ "$status" -eq 1 ]
  [[ "$output" =~ "AUTH_CREDENTIALS" ]]
}

@test "docker-registry-proxy requires the REGISTRY_SERVER environment variable to be set" {
  export AUTH_CREDENTIALS=foobar:password
  run timeout 1 /bin/bash run-docker-registry-proxy.sh
  [ "$status" -eq 1 ]
  [[ "$output" =~ "REGISTRY_SERVER" ]]
}

@test "docker-registry-proxy requires a key in /etc/nginx/ssl" {
  export AUTH_CREDENTIALS=foobar:password
  export REGISTRY_SERVER=foobar.com:5000
  rm /etc/nginx/ssl/docker-registry-proxy.key
  run timeout 1 /bin/bash run-docker-registry-proxy.sh
  [ "$status" -eq 1 ]
  [[ "$output" =~ "No key file" ]]
}

@test "docker-registry-proxy returns an error if more than one key is provided" {
  export AUTH_CREDENTIALS=foobar:password
  export REGISTRY_SERVER=foobar.com:5000
  touch /etc/nginx/ssl/extra-key.key
  run timeout 1 /bin/bash run-docker-registry-proxy.sh
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Multiple key files" ]]
}

@test "docker-registry-proxy requires a certificate in /etc/nginx/ssl" {
  export AUTH_CREDENTIALS=foobar:password
  export REGISTRY_SERVER=foobar.com:5000
  rm /etc/nginx/ssl/docker-registry-proxy.crt
  run timeout 1 /bin/bash run-docker-registry-proxy.sh
  [ "$status" -eq 1 ]
  [[ "$output" =~ "No certificate file" ]]
}

@test "docker-registry-proxy returns an error if more than one certificate is provided" {
  export AUTH_CREDENTIALS=foobar:password
  export REGISTRY_SERVER=foobar.com:5000
  touch /etc/nginx/ssl/extra-cert.crt
  run timeout 1 /bin/bash run-docker-registry-proxy.sh
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Multiple certificate files" ]]
}