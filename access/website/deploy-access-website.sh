#!/bin/sh

# read script environ argument
ENVIRON=$1
if ! [[ ${ENVIRON} =~ dev|beta|prod ]]; then
        echo "ERROR: Script $0 requires environment argument (dev|beta|prod)"
        exit
fi

# Set up environment variables
if [[ ${ENVIRON} == 'prod' ]]; then
	export SERVER_NAME=www.webarchive.org.uk
	export DEPLOYMENT_TAG=prod
	export STORAGE_PATH=/mnt/nfs/data/prod1/website
	export CONFIG_PATH=/mnt/nfs/prod1/access/config/gitlab/ukwa-services-env/access/pywb
elif [[ ${ENVIRON} == 'beta' ]]; then
	export SERVER_NAME=beta.webarchive.org.uk
	export DEPLOYMENT_TAG=beta
	export STORAGE_PATH=/mnt/nfs/data/website
	export CONFIG_PATH=/mnt/nfs/access/config/gitlab/ukwa-services-env/access/pywb
else
	# dev vars
	export SERVER_NAME=dev.webarchive.org.uk
	export DEPLOYMENT_TAG=dev
	export STORAGE_PATH=/mnt/nfs/data/website
	export CONFIG_PATH=/mnt/nfs/access/config/gitlab/ukwa-services-env/access/pywb
fi

# Common configuration
export CDX_SERVER="http://cdx.api.wa.bl.uk/data-heritrix"
export UKWA_INDEX="${CDX_SERVER}?url={url}&closest={closest}&sort=closest&filter=!statuscode:429&filter=!mimetype:warc/revisit"
export UKWA_ARCHIVE="webhdfs://hdfs.api.wa.bl.uk"
export USE_HTTPS=true
export SOLR_FULL_TEXT_SEARCH_PATH="http://solr.api.wa.bl.uk"
export SHINE_SOLR="http://solr-jisc.api.wa.bl.uk/solr/jisc"
export CURRENT_UID=$(id -u):$(id -g)
export KAFKA_BROKER=192.168.45.15:9094
export PROXYHOST=http://194.66.232.92
export PROXYPORT=3127

#export LOG_SERVER="udp://logs.wa.bl.uk:12201"
# Set up folders needed by different components
mkdir -p ${STORAGE_PATH}/shine-postgres-data
mkdir -p ${STORAGE_PATH}/cache
mkdir -p ${STORAGE_PATH}/iiif_cache
chmod a+w ${STORAGE_PATH}/iiif_cache # IIIF server runs as specific container user

# Set up a tmp space for the web renderer that only gets deleted on reboot:
export WEB_RENDER_TMP=${STORAGE_PATH}/webrender-tmp
mkdir -p ${WEB_RENDER_TMP}

# ensure data owned by user
chown -R ${CURRENT_UID} ${STORAGE_PATH}

# Launch the common configuration with these environment variable:
docker stack deploy -c docker-compose.yml access_website
