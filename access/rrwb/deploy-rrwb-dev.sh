#!/bin/sh

# Where to store shared files:
export STORAGE_PATH_SHARED=/mnt/nfs/data/airflow/data_exports

# Username and password to use to access the locks pages:
export LOCKS_AUTH=demouser:demopass

# Which version of PyWB to use:
export PYWB_IMAGE=ukwa/ukwa-pywb:2.6.4

# Deploy as a Docker Stack
docker stack deploy -c docker-compose.yml access_rrwb
