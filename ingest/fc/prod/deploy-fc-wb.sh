#!/bin/sh
set -e
ENVFILE=$1
DEBUG=


# read environment file
if [[ "${ENVFILE}" == "" ]]; then
	echo "ERROR: You must give an argument that specifies the deployment, e.g. crawler06 uses prod-env-crawler06.sh."
	exit 1
fi
if ! [[ -f ${ENVFILE} ]]; then
	echo "ERROR: argument [${ENVFILE}] environment file missing"
	exit 1
fi
source ./${ENVFILE}


# check pywb envars
if [[ "${WB_HOST}" == "" ]]; then
	echo "ERROR: WB_HOST not set"
	exit 1
fi

# start FC pywb
docker stack deploy -c ../fc-wb/docker-compose.yml fc_wb
