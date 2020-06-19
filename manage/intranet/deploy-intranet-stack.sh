#!/bin/sh
#export SERVER_NAME=intranet.dapi.wa.bl.uk
export SERVER_NAME=192.168.45.91:90
export KAFKA_BROKER=192.168.45.15:9094
export DEPLOYMENT_TAG=dev

docker stack deploy -c docker-compose.yml intranet
