#!/bin/sh

export STORAGE_PATH_SHARED=/mnt/nfs/data/airflow/data_exports

export PYWB_IMAGE=ukwa/ukwa-pywb:2.6.4

docker stack deploy -c docker-compose.yml access_rrwb
