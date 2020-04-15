#!/bin/bash

# Fail and halt execution on errors
set -e

source ./prod-env.sh

mkdir -p ${STORAGE_PATH}/heritrix/output
mkdir -p ${STORAGE_PATH}/heritrix/wren
mkdir -p ${STORAGE_PATH}/surts/npld
mkdir -p ${STORAGE_PATH}/surts/bypm
mkdir -p ${TMP_STORAGE_PATH}/heritrix/npld/state
mkdir -p ${TMP_STORAGE_PATH}/heritrix/bypm/state
mkdir -p /tmp/webrender
mkdir -p ${STORAGE_PATH}/prometheus-data

docker stack deploy -c ../fc-crawl/docker-compose.yml fc_crawl
