#!/bin/bash

set -euo pipefail

docker exec $(docker ps -q -n 1 -f name=airflow_airflow) "${@}"
