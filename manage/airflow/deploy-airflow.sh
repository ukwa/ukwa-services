#!/usr/bin/env bash

set -euxo pipefail

# read script environ argument, check, and read envars
CONTEXT_ENV_FILE=$1
if ! [[ -f ${CONTEXT_ENV_FILE} ]]; then
	echo "ERROR: Script $0 argument [${CONTEXT_ENV_FILE}] missing"
	exit
fi

set -a # automatically export all variables
source ${CONTEXT_ENV_FILE}
set +a

if ! [[ ${DEPLOYMENT_CONTEXT} =~ DEV|BETA|PROD|INGEST ]]; then
        echo "ERROR: Script $0 DEPLOYMENT_CONTEXT envar not (DEV|BETA|PROD|INGEST)"
        exit
fi


#if [[ ${ENVIRON} == 'dev' ]]; then
#	export CONTEXT_ENV_FILE=/mnt/nfs/config/gitlab/ukwa-services-env/dev.env
#	# Additional config for this enviroment (purple like ACT but made paler so it's usable):
#	export AIRFLOW__WEBSERVER__NAVBAR_COLOR="#ff80ff"
#	# BETA
#	#export AIRFLOW__WEBSERVER__NAVBAR_COLOR="darkred"
#elif [[ ${ENVIRON} == 'ingest' ]]; then
#	export CONTEXT_ENV_FILE=/root/gitlab/ukwa-services-env/ingest.env
#	export AIRFLOW__WEBSERVER__INSTANCE_NAME="Airflow (Production/Ingest)"
#else
#        export PUSH_GATEWAY=monitor.wa.bl.uk:9091
#	echo "ERROR - not yet configured!"
#	exit
#fi


# Storage:
echo Setup ${STORAGE_PATH} ...
# Storage locations for Airflow itself:
mkdir -p ${STORAGE_PATH}/airflow/logs
mkdir -p ${STORAGE_PATH}/airflow/postgres
# Storage location for data exported from e.g. W3ACT, like access lists used for playback
mkdir -p ${STORAGE_PATH}/hadoop_lsr
mkdir -p ${STORAGE_PATH}/data_exports
echo "Directory ${STORAGE_PATH}/hadoop_lsr should be owned by user 1000"
echo "Directory ${STORAGE_PATH} (recursive) should be in group airflow"
# Clone the Git repo used to store access-control lists
GIT_URL=http://git.wa.bl.uk/bl-services/wayback_excludes_update.git 
FOLDER=${STORAGE_PATH}/wayback_acls
if [ ! -d "$FOLDER" ] ; then
    git clone $GIT_URL $FOLDER
else
    cd "$FOLDER"
    git pull $GIT_URL
    cd -
fi

# deploy container
docker stack deploy -c docker-compose.yaml airflow
