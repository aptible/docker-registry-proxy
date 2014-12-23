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
  export SERVER_NAME=foobar.com
  run timeout 1 /bin/bash run-docker-registry-proxy.sh
  [ "$status" -eq 1 ]
  [[ "$output" =~ "AUTH_CREDENTIALS" ]]
}

@test "docker-registry-proxy requires the SERVER_NAME environment variable to be set" {
  export AUTH_CREDENTIALS=foobar
  run timeout 1 /bin/bash run-docker-registry-proxy.sh
  [ "$status" -eq 1 ]
  [[ "$output" =~ "SERVER_NAME" ]]
}

@test "docker-registry-proxy requires a key in /etc/nginx/ssl" {
  export AUTH_CREDENTIALS=foobar
  export SERVER_NAME=foobar.com
  rm /etc/nginx/ssl/docker-registry-proxy.key
  run timeout 1 /bin/bash run-docker-registry-proxy.sh
  [ "$status" -eq 1 ]
  [[ "$output" =~ "/etc/nginx/ssl/docker-registry-proxy.key" ]]
}

@test "docker-registry-proxy requires a certificate in /etc/nginx/ssl" {
  export AUTH_CREDENTIALS=foobar
  export SERVER_NAME=foobar.com
  rm /etc/nginx/ssl/docker-registry-proxy.crt
  run timeout 1 /bin/bash run-docker-registry-proxy.sh
  [ "$status" -eq 1 ]
  [[ "$output" =~ "/etc/nginx/ssl/docker-registry-proxy.crt" ]]
}
