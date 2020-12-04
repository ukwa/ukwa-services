#!/bin/sh

# read script environ argument
ENVIRON=$1
if ! [[ ${ENVIRON} =~ dev|beta|prod ]]; then
        echo "ERROR: Script $0 requires environment argument (dev|beta|prod)"
        exit
fi

if [[ ${ENVIRON} == 'dev' ]]; then
	# Set up the dev.webarchive.org.uk vars
	export SERVER_NAME=dev.webarchive.org.uk
	export DEPLOYMENT_TAG=dev
	export STORAGE_PATH=/mnt/nfs/data/website
else
	echo "ERROR"
	exit
fi

# Common configuration
export CDX_SERVER="http://cdx.api.wa.bl.uk/data-heritrix"
export UKWA_INDEX="${CDX_SERVER}?url={url}&closest={closest}&sort=closest&filter=!statuscode:429"
export UKWA_ARCHIVE="webhdfs://hdfs.api.wa.bl.uk"
export USE_HTTPS=true
export SOLR_FULL_TEXT_SEARCH_PATH="http://solr.api.wa.bl.uk"
export SHINE_SOLR="http://solr-jisc.api.wa.bl.uk/solr/jisc"

#export LOG_SERVER="udp://logs.wa.bl.uk:12201"
# Set up folders needed by different components
mkdir -p ${STORAGE_PATH}/shine-postgres-data

# Set up a tmp space for the web renderer that only gets deleted on reboot:
export WEB_RENDER_TMP=${STORAGE_PATH}/webrender-tmp
mkdir -p ${WEB_RENDER_TMP}

# Launch the common configuration with these environment variable:
docker stack deploy -c docker-compose.yml access_website
