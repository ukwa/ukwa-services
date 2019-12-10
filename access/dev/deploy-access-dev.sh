#!/bin/sh

# Pull in sensitive environment variables:
#source /mnt/nfs/config/gitlab/ukwa-services-env/w3act/dev/w3act.env

# Set up the dev.webarchive.org.uk hostname
export ACCESS_SERVER_NAME=https://dev.webarchive.org.uk

# Launch the common configuration with these environment variable:
docker stack deploy -c ../docker-compose.yml access
