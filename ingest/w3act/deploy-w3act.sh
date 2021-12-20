#!/bin/sh

set -euo pipefail

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

# Set up the persistent data locations:
export W3ACT_PSQL_DIR=$W3ACT_STORAGE/postgresql
export W3ACT_DUMPS_DIR=$W3ACT_STORAGE/postgresql-dumps
export DDHAPT_SIPS_SUBMITTED_DIR=$W3ACT_STORAGE/dls-sips-submitted

# DDHAPT Database
export DDHAPT_PSQL_DIR=$W3ACT_STORAGE/ddhapt

# Metabase Database
export METABASE_PSQL_DIR=$W3ACT_STORAGE/metabase

# Make any required folders:
mkdir -p $W3ACT_PSQL_DIR
mkdir -p $DDHAPT_SIPS_SUBMITTED_DIR
mkdir -p $W3ACT_DUMPS_DIR
mkdir -p $DDHAPT_PSQL_DIR
mkdir -p $METABASE_PSQL_DIR

# Launch the common configuration with these environment variable:
docker stack deploy -c docker-compose.yml w3act
