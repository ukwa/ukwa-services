#!/bin/sh

# Set up the env
# ---

# Which Kafka to talk to for recent FC activity:
export KAFKA_BROKER=192.168.45.15:9094

# Where to store persistant data:
export STORAGE_PATH=/mnt/nfs/data/access_data

# ---

# Create needed folders:
mkdir -p $STORAGE_PATH/w3act_export
mkdir -p $STORAGE_PATH/fc_analysis
mkdir -p $STORAGE_PATH/collections_solr_cores
mkdir -p $STORAGE_PATH/collections_solr_logs
chmod a+w $STORAGE_PATH/collections_solr_*

# Launch the common configuration with these environment variable:
docker stack deploy -c ../docker-compose.yml access_data
