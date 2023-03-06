#!/bin/bash

# Fail and halt execution on errors
set -e

if [[ "$1" != "" ]]; then
    ENV_TAG="$1"
else
    echo "You must give an argument that specifies the deployment, e.g. crawler06 uses prod-env-crawler06.sh."
    exit 1
fi


source ./env-${ENV_TAG}.sh

echo Using UID $H3_UID for Heritrix

mkdir -p ${STORAGE_PATH}/heritrix/output
mkdir -p ${STORAGE_PATH}/heritrix/wren
mkdir -p ${STORAGE_PATH}/surts/npld
mkdir -p ${STORAGE_PATH}/surts/bypm
mkdir -p ${TMP_STORAGE_PATH}/heritrix/npld/state
mkdir -p ${TMP_STORAGE_PATH}/heritrix/bypm/state
mkdir -p ${CDX_STORAGE_PATH}
mkdir -p /tmp/webrender
mkdir -p ${STORAGE_PATH}/prometheus-data

docker stack deploy -c ../fc-crawl/docker-compose.yml fc_crawl
