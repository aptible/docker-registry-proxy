#!/bin/bash
# Deploy to staging on master merges (not PRs)

set -e

# Don't deploy on PRs
if [ "$TRAVIS_PULL_REQUEST" != "false" ]; then
  exit 0
fi

if [ "$TRAVIS_BRANCH" == "master" ]; then
  # Deploy to staging on a merge to master
  docker login -e="$DOCKER_EMAIL" -u="$DOCKER_USERNAME" -p="$DOCKER_PASSWORD" quay.io
  docker push quay.io/aptible/registry-proxy
  bundle exec opsworks apps:deploy registry --timeout 600 --stack staging
fi
