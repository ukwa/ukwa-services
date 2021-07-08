#!/bin/bash

set -euxo pipefail

source $CONTEXT_ENV_FILE

#export $(cat $CONTEXT_ENV_FILE | egrep -v "(^#.*|^$)" | xargs)

export AIRFLOW_IMAGE_NAME=ukwa/airflow

echo Setup ${STORAGE_PATH} ...

mkdir -p ${STORAGE_PATH}/airflow/logs
mkdir -p ${STORAGE_PATH}/airflow/postgres

sudo chmod -R a+rwx ${STORAGE_PATH}

export STORAGE_PATH FERNET_KEY MANAGE_SENTRY_DSN AIRFLOW_UID AIRFLOW_GID

docker stack deploy -c docker-compose.yaml airflow
