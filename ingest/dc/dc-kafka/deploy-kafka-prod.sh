#!/bin/sh
export STORAGE_PATH=/mnt/gluster/dc2019kafka
docker stack deploy -c docker-compose.yml dc_kafka

