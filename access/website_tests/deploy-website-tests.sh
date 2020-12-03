#!/bin/sh


source ~/gitlab/ukwa-services-env/access/website/dev.env
export HOST=https://dev:${DEV_WEBSITE_PW}@dev.webarchive.org.uk

export PROMETHEUS_JOB_NAME=access_website_rf_tests_dev

export PUSH_GATEWAY=monitor.wa.bl.uk:9091

# --
echo Running tests using HOST = $HOST
echo WARNING! Tests will fail if the HOST variable has a trailing slash!

docker stack deploy -c docker-compose.yml access_website_tests

