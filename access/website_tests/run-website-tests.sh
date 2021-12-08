#!/bin/sh

# read script environ argument
ENVIRON=$1
if ! [[ ${ENVIRON} =~ dev|beta|prod ]]; then
        echo "ERROR: Script $0 requires environment argument (dev|beta|prod)"
        exit
fi

if [[ ${ENVIRON} == 'dev' ]]; then
	# Set up the dev.webarchive.org.uk vars
        source ~/gitlab/ukwa-services-env/access/website/dev.env
        export HOST=https://dev:${DEV_WEBSITE_PW}@dev.webarchive.org.uk
        export PUSH_GATEWAY=monitor-pushgateway.dapi.wa.bl.uk:80
elif [[ ${ENVIRON} == 'beta' ]]; then
	# Set up the beta.webarchive.org.uk vars
        export HOST=https://beta.webarchive.org.uk
        export PUSH_GATEWAY=monitor-pushgateway.bapi.wa.bl.uk:80
elif [[ ${ENVIRON} == 'prod' ]]; then
	# Set up the www.webarchive.org.uk vars
        export HOST=https://www.webarchive.org.uk
        export PUSH_GATEWAY=monitor-pushgateway.api.wa.bl.uk:80
else
        export PUSH_GATEWAY=monitor.wa.bl.uk:9091
	echo "ERROR"
	exit
fi

# Add environ tag to job name for Prometheus metrics:
export PROMETHEUS_JOB_NAME=access_website_rf_tests_${ENVIRON}

# --
echo Running tests using HOST = $HOST
echo WARNING! Tests will fail if the HOST variable has a trailing slash!

docker-compose run robot

