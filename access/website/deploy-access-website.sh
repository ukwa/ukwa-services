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

# Common config
export USE_HTTPS=true
export SOLR_FULL_TEXT_SEARCH_PATH='http://solr.api.wa.bl.uk'

#export LOG_SERVER="udp://logs.wa.bl.uk:12201"
# Set up folders needed by different components
mkdir -p ${STORAGE_PATH}/shine-postgres-data

# Set up a tmp space for the web renderer:
mkdir -p /tmp/webrender

# Launch the common configuration with these environment variable:
docker stack deploy -c docker-compose.yml access_website
