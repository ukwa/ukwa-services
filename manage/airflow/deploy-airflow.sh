#!/bin/bash

export AIRFLOW_GID=992 # Run in the Docker group

export CONTEXT_ENV_FILE=$1

docker stack deploy -c docker-compose.yaml airflow
