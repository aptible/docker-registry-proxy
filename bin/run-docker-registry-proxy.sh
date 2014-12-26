#!/bin/bash
# Make sure required environment variables are set.
: ${AUTH_CREDENTIALS:?"Error: environment variable AUTH_CREDENTIALS should be populated with a comma-separated list of user:password pairs. Example: \"admin:pa55w0rD\"."}
: ${REGISTRY_PORT:?"Error: Missing REGISTRY_PORT environment variable. This variable should be defined by creating a named link 'registry' to another container running a Docker registry."}

# Make sure there's exactly one certificate provided and store its path in CERT_FILE
NUM_CERTS=`ls -l /etc/nginx/ssl/*.crt | wc -l`
if [ $NUM_CERTS -eq 0 ]; then
    echo "No certificate file (*.crt) provided in the directory /etc/nginx/ssl."
    exit 1
elif [ $NUM_CERTS -gt 1 ]; then
    echo "Multiple certificate files (*.crt) found in /etc/nginx/ssl. Please remove all but one."
    exit 1
fi
export CERT_FILE=`find /etc/nginx/ssl -maxdepth 1 -name '*.crt' -print`

# Make sure there's exactly one key provided and store its path in KEY_FILE
NUM_KEYS=`ls -l /etc/nginx/ssl/*.key | wc -l`
if [ $NUM_KEYS -eq 0 ]; then
    echo "No key file (*.key) provided in the directory /etc/nginx/ssl."
    exit 1
elif [ $NUM_KEYS -gt 1 ]; then
    echo "Multiple key files (*.key) found in /etc/nginx/ssl. Please remove all but one."
    exit 1
fi
export KEY_FILE=`find /etc/nginx/ssl -maxdepth 1 -name '*.key' -print`

# Parse the NGiNX server name from the certificate if possible.
export SERVER_NAME=`openssl x509 -noout -subject -in $CERT_FILE | sed -n '/^subject/s/^.*CN=//p'`
if [ ! $SERVER_NAME ]; then
  export SERVER_NAME=example.com
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

# Parse address of registry server from the linked REGISTRY_PORT environment variable.
export REGISTRY_SERVER=${REGISTRY_PORT##*/}

# Generate the NGiNX configuration.
erb -T 2 ./docker-registry-proxy.erb > /etc/nginx/sites-enabled/docker-registry-proxy || \
(echo "Error creating nginx configuration." && exit 1)

# Start NGiNX, tail error and access logs.
service nginx start
touch /var/log/nginx/access.log /var/log/nginx/error.log
tail -fq /var/log/nginx/access.log /var/log/nginx/error.log
