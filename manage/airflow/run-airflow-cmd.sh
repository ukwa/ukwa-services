#!/bin/bash

source $1

export AIRFLOW_GID=992 # Run in the Docker group
export AIRFLOW_IMAGE_NAME=ukwa/airflow

export CONTEXT_ENV_FILE=$1

export STORAGE_PATH FERNET_KEY

docker-compose run --no-deps airflow-scheduler "${@:2}"
