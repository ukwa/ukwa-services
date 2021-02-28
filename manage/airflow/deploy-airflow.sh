#!/bin/bash

source $1

export AIRFLOW_GID=992 # Run in the Docker group
export AIRFLOW_IMAGE_NAME=ukwa/airflow

export CONTEXT_ENV_FILE=$1

echo Setup ${STORAGE_PATH} ...

mkdir -p ${STORAGE_PATH}/logs
mkdir -p ${STORAGE_PATH}/postgres

sudo chmod -R a+rwx ${STORAGE_PATH}

export STORAGE_PATH FERNET_KEY

docker stack deploy -c docker-compose.yaml airflow
