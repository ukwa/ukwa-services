#!/bin/sh

set -e

if [[ "$1" != "" ]]; then
    ENV_TAG="$1"
else
    echo "You must give an argument that specifies the deployment, e.g. crawler06 uses prod-env-crawler06.sh."
    exit 1
fi


source ./prod-env-${ENV_TAG}.sh

mkdir -p ${STORAGE_PATH}/zookeeper/data
mkdir -p ${STORAGE_PATH}/zookeeper/datalog
mkdir -p ${STORAGE_PATH}/kafka

docker stack deploy -c ../fc-kafka/docker-compose.yml fc_kafka
