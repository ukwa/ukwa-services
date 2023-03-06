#!/bin/bash

# Shared vars:
source ../prod.env

export CURRENT_UID=$(id -u):$(id -g)

echo "Will run as ${CURRENT_UID},,,"

sudo mkdir -p ${STORAGE_PATH}/cdx-data
sudo mkdir -p ${STORAGE_PATH}/heritrix/state
sudo mkdir -p ${STORAGE_PATH}/heritrix/scratch
sudo mkdir -p ${STORAGE_PATH}/heritrix/output/prometheus/config
sudo mkdir -p ${STORAGE_PATH}/heritrix/output/prometheus/data

# Ensure Heritrix user group can write to output folder:
echo "Ensure file ownership and permissions are correct..."
sudo chgrp -R docker ${STORAGE_PATH}/heritrix/output
sudo chgrp -R docker ${STORAGE_PATH}/heritrix/scratch
sudo chgrp -R docker ${STORAGE_PATH}/heritrix/state
sudo chmod -R g+w ${STORAGE_PATH}/heritrix/output
sudo chmod -R g+w ${STORAGE_PATH}/heritrix/scratch
sudo chmod -R g+w ${STORAGE_PATH}/heritrix/state


cp prometheus/config/* ${STORAGE_PATH}/heritrix/output/prometheus/config

mkdir -p ./shared

#mkdir -p /heritrix/state/clamav

docker stack deploy -c docker-compose.yml dc_crawl
