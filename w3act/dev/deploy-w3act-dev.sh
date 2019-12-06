#!/bin/sh

# Pull in configuration environment variables:
source /etc/sysconfig/w3act-dev
export PYWB_NGINX_CONF=$PWD/pywb-nginx.conf

# Launch with correct combined configuration:
#docker stack deploy -c ../docker-compose.yml -c docker-compose-beta.yml ife_beta
docker stack deploy -c ../docker-compose.yml ife_dev
