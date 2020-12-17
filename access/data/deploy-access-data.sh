#!/bin/bash

# Fail on errors:
set -e

# read script environ argument
ENVIRON=$1
if ! [[ ${ENVIRON} =~ dev|beta|prod ]]; then
        echo "ERROR: Script $0 requires environment argument (dev|beta|prod)"
        exit
fi


# Where to store persistant data (current same for dev|beta|prod):
if [[ ${ENVIRON} == 'dev' ]]; then
	export STORAGE_PATH=/mnt/nfs/data/access_data
elif [[ ${ENVIRON} == 'beta' ]]; then
	export STORAGE_PATH=/mnt/nfs/data/access_data
elif [[ ${ENVIRON} == 'prod' ]]; then
	export STORAGE_PATH=/mnt/nfs/data/access_data
else
	echo "ERROR: STORAGE_PATH not set for ${ENVIRON}!"
        exit
fi

# Which Kafka to talk to for recent FC activity:
# 192.168.45.15 is crawler05.n45
export KAFKA_BROKER=192.168.45.15:9094

# Get the UID so we can run services as the same UID:
export CURRENT_UID=$(id -u):$(id -g)

# Create needed folders:
mkdir -p $STORAGE_PATH/w3act_export
mkdir -p $STORAGE_PATH/fc_analysis
mkdir -p $STORAGE_PATH/collections_solr_cores
mkdir -p $STORAGE_PATH/collections_solr_logs
chmod a+w $STORAGE_PATH/collections_solr_*

# Launch the common configuration with these environment variable:
docker stack deploy -c docker-compose.yml access_data
