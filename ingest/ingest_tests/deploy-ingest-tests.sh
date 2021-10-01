#!/bin/sh

# read script environ argument
ENVIRON=$1
if ! [[ ${ENVIRON} =~ dev|beta|prod ]]; then
        echo "ERROR: Script $0 requires environment argument (dev|beta|prod)"
        exit
fi

if [[ ${ENVIRON} == 'dev' ]]; then
	# Set up the dev.webarchive.org.uk vars
        set -a # automatically export all variables
        source /mnt/nfs/config/gitlab/ukwa-services-env/dev.env
        set +a
        export EXTRA_TESTS="/tests_destructive"
else
        export PUSH_GATEWAY=monitor.wa.bl.uk:9091
	echo "ERROR - not yet configured!"
	exit
fi

# --
echo Running tests using TEST_HOST = $TEST_HOST
echo WARNING! Tests will fail if the TEST_HOST variable has a trailing slash!

#docker stack deploy -c docker-compose.yml ingest_tests
docker-compose run robot

