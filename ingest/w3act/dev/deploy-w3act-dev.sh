#!/bin/sh

# Pull in sensitive environment variables:
source /mnt/nfs/config/gitlab/ukwa-services-env/w3act/dev/w3act.env

# Pull in context variables:
source ./w3act.env

# Make any required folders:
mkdir -p $DDHAPT_PSQL_DIR
mkdir -p $METABASE_PSQL_DIR

# Launch the common configuration with these environment variable:
docker stack deploy -c ../docker-compose.yml w3act
