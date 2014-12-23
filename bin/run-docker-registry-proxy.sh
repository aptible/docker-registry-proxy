#!/bin/bash
: ${AUTH_CREDENTIALS:?"Error: environment variable AUTH_CREDENTIALS should be populated with a comma-separated list of user:password pairs. Example: \"admin:pa55w0rD\"."}
: ${SERVER_NAME:?"Error: environment variable SERVER_NAME should container the FQDN of the server, e.g., 'registry.example.com'."}

if [ ! -f /etc/nginx/ssl/docker-registry-proxy.crt ]; then
    echo "Error: /etc/nginx/ssl/docker-registry-proxy.crt does not exist. This file should be mapped in" \
         "to the container using a flag like '-v /local/path/to/keypair:/etc/nginx/ssl'"
    exit 1
fi
if [ ! -f /etc/nginx/ssl/docker-registry-proxy.key ]; then
    echo "Error: /etc/nginx/ssl/docker-registry-proxy.key does not exist. This file should be mapped in" \
         "to the container using a flag like '-v /local/path/to/keypair:/etc/nginx/ssl'"
    exit 1
fi

# Parse auth credentials, add to a htpasswd file.
AUTH_PARSER="
create_opt = 'c'
ENV['AUTH_CREDENTIALS'].split(',').map do |creds|
  user, password = creds.split(':')
  %x(htpasswd -b#{create_opt} /etc/nginx/conf.d/docker-registry-proxy.htpasswd #{user} #{password})
  create_opt = ''
end"
ruby -e "$AUTH_PARSER" || \
(echo "Error creating htpasswd file from credentials '$AUTH_CREDENTIALS'" && exit 1)

erb -T 2 ./docker-registry-proxy.erb > /etc/nginx/sites-enabled/docker-registry-proxy || \
(echo "Error creating nginx configuration." && exit 1)

service nginx start
touch /var/log/nginx/access.log /var/log/nginx/error.log
tail -fq /var/log/nginx/access.log /var/log/nginx/error.log
