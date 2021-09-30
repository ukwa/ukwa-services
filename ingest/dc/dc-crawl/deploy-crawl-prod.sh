#!/bin/bash

# Shared vars:
source ../prod.env

export CURRENT_UID=$(id -u):$(id -g)

echo "Will run as ${CURRENT_UID},,,"

sudo mkdir -p /heritrix/output/prometheus/config
sudo mkdir -p /heritrix/output/prometheus/data

# Ensure Heritrix user group can write to output folder:
echo "Ensure file ownership and permissions are correct..."
sudo chown -R ec2-user:1001 /heritrix/output
sudo chown -R ec2-user:1001 /heritrix/scratch
sudo chown -R ec2-user:1001 /heritrix/state
sudo chmod -R g+w /heritrix/output
sudo chmod -R g+w /heritrix/scratch
sudo chmod -R g+w /heritrix/state


cp prometheus/config/* /heritrix/output/prometheus/config

mkdir -p ./shared

#mkdir -p /heritrix/state/clamav

docker stack deploy -c docker-compose.yml dc_crawl
