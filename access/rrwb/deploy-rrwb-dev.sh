#!/bin/sh

export STORAGE_PATH_SHARED=/mnt/nfs/data/airflow/data_exports

docker stack deploy -c docker-compose.yml access_rrwb
