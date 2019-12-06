#!/bin/sh

source /etc/sysconfig/w3act-beta

export W3ACT_DUMPS_DIR=$PWD

PASS_COMMAND="docker-compose exec postgres"

#(re)start postgres
docker-compose down
docker-compose up -d postgres
sleep 5

#(re)create the instance we are going to load the dumps into
$PASS_COMMAND dropdb -U postgres w3act
$PASS_COMMAND createdb -U postgres w3act

#restore dump into this instance
echo "Importing data..."
$PASS_COMMAND pg_restore -v -U w3act -n public -d w3act /var/lib/postresql/dumps/w3act_dump.sql

#done - we now have a postgres instance (in a volume which will persist outside this container if we've mounted it) with the Shine dump restored to it
echo "Shutting down..."
docker-compose down


