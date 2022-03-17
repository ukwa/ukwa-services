#!/bin/sh

# Where to store shared files:
export STORAGE_PATH_SHARED=/home/access/rrwb-acls

# Username and password to use to access the locks pages:
export LOCKS_AUTH=demouser:demopass

# Which version of PyWB to use:
export PYWB_IMAGE=ukwa/ukwa-pywb:master

# Deploy as a Docker Stack
docker stack deploy -c docker-compose.yml access_rrwb
