#!/bin/bash

set -euxo pipefail

docker exec $(docker ps -q -f name=airflow-scheduler) "${@}"
