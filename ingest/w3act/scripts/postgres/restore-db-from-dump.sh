#!/bin/sh

# Common setup
source ./common.env
echo "DOCKER_COMMAND: [${DOCKER_COMMAND}]"
echo "W3ACT_PSQL_DIR: [${W3ACT_PSQL_DIR}]"
echo "W3ACT_DUMPS_DIR:[${W3ACT_DUMPS_DIR}]"
echo "W3ACT_PSQL_PASSWORD: [${W3ACT_PSQL_PASSWORD}]"

# Setup standard var
export PGPASSWORD=$W3ACT_PSQL_PASSWORD

# Drop the current DB:
echo "Dropping current DB, creating a new empty one..."
docker run -i --net w3act_default -v $W3ACT_DUMPS_DIR:/host -e PGPASSWORD postgres:9.6.2 dropdb -U w3act -h postgres w3act
sleep 5
docker run -i --net w3act_default -v $W3ACT_DUMPS_DIR:/host -e PGPASSWORD postgres:9.6.2 createdb -U w3act -h postgres w3act

# restore dump into this instance
echo "Restoring W3ACT DB to ${W3ACT_DUMPS_DIR}..."
docker run -i --net w3act_default -v $W3ACT_DUMPS_DIR:/host -e PGPASSWORD postgres:9.6.2 pg_restore -v -U w3act -h postgres -n public -d w3act /host/w3act_dump.sql

#  pg_restore -v -U w3act -n public -d w3act /tmp/w3act_dump.sql
