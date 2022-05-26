#!/bin/sh

# Pull in vars
set -a && . ./dev.env && set +a

# Deploy as a Docker Stack
docker stack deploy -c docker-compose.yml $EXTRA_CONFIG access_rrwb
