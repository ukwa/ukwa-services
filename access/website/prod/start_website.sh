#!/bin/sh

# Set up the beta.webarchive.org.uk vars
export SERVER_NAME=www.webarchive.org.uk
export USE_HTTPS=true
export KAFKA_BROKER=192.168.45.15:9094
export DEPLOYMENT_TAG=prod
export STORAGE_PATH=/mnt/nfs/data/website
export SOLR_FULL_TEXT_SEARCH_PATH='http://solr.api.wa.bl.uk'
export SOLR_UID=$UID
#export LOG_SERVER="udp://logs.wa.bl.uk:12201"

# Set up folders needed by different components
mkdir -p ${STORAGE_PATH}/open-access-acl
mkdir -p ${STORAGE_PATH}/shine-postgres-data
mkdir -p ${STORAGE_PATH}/ukwa-collections-solr/mycores
mkdir -p ${STORAGE_PATH}/ukwa-collections-solr/logs
#chgrp -R $SOLR_GROUP ${STORAGE_PATH}/ukwa-collections-solr
#chmod -R g+rwx ${STORAGE_PATH}/ukwa-collections-solr

# Set up a tmp space for the web renderer:
mkdir -p /tmp/webrender

# Launch the common configuration with these environment variable:
docker stack deploy -c ../docker-compose.yml website
