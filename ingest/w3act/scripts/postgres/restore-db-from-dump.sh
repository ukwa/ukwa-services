#!/bin/sh

# Common setup
source ./common.env
echo "DOCKER_COMMAND: [${DOCKER_COMMAND}]"
echo "W3ACT_PSQL_DIR: [${W3ACT_PSQL_DIR}]"
echo "W3ACT_DUMPS_DIR:[${W3ACT_DUMPS_DIR}]"
echo "W3ACT_PSQL_PASSWORD: [${W3ACT_PSQL_PASSWORD}]"

# Inform
echo Attempting to restore using file ${W3ACT_DUMPS_DIR}/w3act_dump.sql ...

# (re)start postgres
$DOCKER_COMMAND down
$DOCKER_COMMAND up -d postgres
sleep 5

# (re)create the instance we are going to load the dumps into
$DOCKER_COMMAND exec postgres dropdb -U postgres w3act
$DOCKER_COMMAND exec postgres createdb -U postgres w3act

# restore dump into this instance
echo "Importing data..."
$DOCKER_COMMAND exec postgres pg_restore -v -U w3act -n public -d w3act /tmp/w3act_dump.sql

# done - we now have a postgres instance (in a volume which will persist outside this container if we've mounted it)
echo "Shutting down..."
$DOCKER_COMMAND down
