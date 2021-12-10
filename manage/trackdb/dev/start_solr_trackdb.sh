#!/usr/bin/env bash

export DATA_TRACKDB=/mnt/nfs/data/trackdb

# start the solr trackdb container
docker stack deploy -c docker-compose.yml trackdb
