#!/bin/sh

# Pull in sensitive environment variables:
#source ~/gitlab/ukwa-services-env/w3act/dev/w3act.env

# Set up the dev.webarchive.org.uk vars
export SERVER_NAME=dev.webarchive.org.uk
export USE_HTTPS=false
export KAFKA_BROKER=192.168.45.15:9094
export DEPLOYMENT_TAG=dev
export STORAGE_PATH=/mnt/nfs/
export LOG_SERVER="udp://logs.wa.bl.uk:12201"

# Set up folders needed by different components
mkdir ${STORAGE_PATH}
mkdir ${STORAGE_PATH}/open-access-acl
mkdir ${STORAGE_PATH}/shine-postgres-data
mkdir ${STORAGE_PATH}/ukwa-collections-solr

# Set up a tmp space for the web renderer:
mkdir /tmp/webrender

# Launch the common configuration with these environment variable:
docker stack deploy -c ../docker-compose.yml access
