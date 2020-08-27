#!/bin/sh
#export SERVER_NAME=intranet.dapi.wa.bl.uk
export SERVER_NAME=dev1.n45.wa.bl.uk:90
export KAFKA_BROKER=192.168.45.15:9094
export CRAWLER_WEBHDFS=192.168.45.15:8001/by-filename/
export DEPLOYMENT_TAG=dev

docker stack deploy -c docker-compose.yml intranet
