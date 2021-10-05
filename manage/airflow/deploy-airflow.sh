#!/bin/bash

set -euxo pipefail

# read script environ argument
ENVIRON=$1
if ! [[ ${ENVIRON} =~ dev|beta|prod|ingest ]]; then
        echo "ERROR: Script $0 requires environment argument (dev|beta|prod|ingest)"
        exit
fi

if [[ ${ENVIRON} == 'dev' ]]; then
	export CONTEXT_ENV_FILE=/mnt/nfs/config/gitlab/ukwa-services-env/dev.env
	# Additional config for this enviroment:
	export AIRFLOW__WEBSERVER__NAVBAR_COLOR="purple"
	# BETA
	#export AIRFLOW__WEBSERVER__NAVBAR_COLOR="darkred"
elif [[ ${ENVIRON} == 'ingest' ]]; then
	export CONTEXT_ENV_FILE=/root/gitlab/ukwa-services-env/ingest.env
	export AIRFLOW__WEBSERVER__INSTANCE_NAME="Airflow (Production/Ingest)"
else
        export PUSH_GATEWAY=monitor.wa.bl.uk:9091
	echo "ERROR - not yet configured!"
	exit
fi

# Set up general Airflow configs (may be overridden in CONTEXT_ENV_FILE):
export AIRFLOW_IMAGE_NAME=ukwa/airflow:2.1.4
export AIRFLOW__WEBSERVER__INSTANCE_NAME=${ENVIRON}

# Pull in the rest of the environment variables:
echo Reading $CONTEXT_ENV_FILE
set -a # automatically export all variables
source ${CONTEXT_ENV_FILE}
set +a

# Storage:
echo Setup ${STORAGE_PATH} ...

# Storage locations for Airflow itself:
mkdir -p ${STORAGE_PATH}/airflow/logs
mkdir -p ${STORAGE_PATH}/airflow/postgres
# Storage location for data exported from e.g. W3ACT, like access lists used for playback
mkdir -p ${STORAGE_PATH}/data_exports

sudo chmod -R a+rwx ${STORAGE_PATH}

export STORAGE_PATH MANAGE_SENTRY_DSN AIRFLOW_UID AIRFLOW_GID

docker stack deploy -c docker-compose.yaml airflow
