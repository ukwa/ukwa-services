#!/bin/sh

# Pull in sensitive environment variables:
#source /mnt/nfs/config/gitlab/ukwa-services-env/w3act/dev/w3act.env

export SERVER_NAME=dev.webarchive.org.uk
export USE_HTTPS=false
export KAFKA_BROKER=192.168.45.15:9094
export CDX_SERVER='http://cdx.api.wa.bl.uk/data-heritrix'
export WEBHDFS_PREFIX='http://hdfs.api.wa.bl.uk/webhdfs/v1'
export HTTPS_PROXY='http://explorer2:3128'

export UKWA_INDEX='xmlquery+http://cdx.api.wa.bl.uk/data-heritrix'
export UKWA_ARCHIVE='webhdfs://hdfs.api.wa.bl.uk'

export SOLR_FULL_TEXT_SEARCH_PATH='http://solr.api.wa.bl.uk'

export PROXYHOST='explorer2'
export PROXYPORT=3128

export SHINE_SOLR='http://solr-jisc.api.wa.bl.uk/solr/jisc'

# Set up a tmp space for the web renderer:
mkdir /tmp/webrender

# Launch the common configuration with these environment variable:
docker stack deploy -c ../docker-compose.yml access
