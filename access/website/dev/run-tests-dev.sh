#!/bin/sh

source /mnt/nfs/config/gitlab/ukwa-services-env/website/dev/website.env

echo Running tests using HOST = $HOST
echo WARNING! Tests will fail if the HOST variable has a trailing slash!
cd ../tests
docker-compose run robot
