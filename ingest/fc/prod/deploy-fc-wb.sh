#!/bin/sh

set -e

if [[ "$1" != "" ]]; then
    ENV_TAG="$1"
else
    echo "You must give an argument that specifies the deployment, e.g. crawler06 uses prod-env-crawler06.sh."
    exit 1
fi


source ./prod-env-${ENV_TAG}.sh

docker stack deploy -c ../fc-wb/docker-compose.yml fc_wb
