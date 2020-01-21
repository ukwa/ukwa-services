#!/bin/sh

# Pull in sensitive environment variables:
#source /mnt/nfs/config/gitlab/ukwa-services-env/w3act/dev/w3act.env

# Set up the dev.webarchive.org.uk hostname
export SERVER_NAME=dev.webarchive.org.uk
export USE_HTTPS=false
export KAFKA_BROKER=192.168.45.15:9094

# Set up a tmp space for the web renderer:
mkdir /tmp/webrender

# Launch the common configuration with these environment variable:
docker stack deploy -c ../docker-compose.yml access
