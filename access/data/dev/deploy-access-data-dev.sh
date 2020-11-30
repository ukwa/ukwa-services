#!/bin/sh

# Set up the env
export KAFKA_BROKER=192.168.45.15:9094
export STORAGE_PATH=/mnt/nfs/data/access_data
mkdir -p $STORAGE_PATH/w3act_export
mkdir -p $STORAGE_PATH/fc_analysis

# Launch the common configuration with these environment variable:
docker stack deploy -c ../docker-compose.yml access_data
