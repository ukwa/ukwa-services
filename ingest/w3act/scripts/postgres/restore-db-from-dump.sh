#!/bin/sh

###########################
DEBUG=
DBPAUSE=60
###########################
SLEEP=5

# Common setup
source ./common.env
echo "DOCKER_COMMAND: [${DOCKER_COMMAND}]"
echo "W3ACT_PSQL_DIR: [${W3ACT_PSQL_DIR}]"
echo "W3ACT_DUMPS_DIR:[${W3ACT_DUMPS_DIR}]"
echo "W3ACT_PSQL_PASSWORD: [${W3ACT_PSQL_PASSWORD}]"

# Inform
echo Attempting to restore using file ${W3ACT_DUMPS_DIR}/w3act_dump.sql ...

if [[ ${DEBUG} ]]; then
	echo "Deleting contents of previous Postgres database restore ----------------"		# DEBUG
	echo "from ${W3ACT_PSQL_DIR}"								# DEBUG
	[[ ${W3ACT_PSQL_DIR} ]] && rm -rf ${W3ACT_PSQL_DIR}/*					# DEBUG
fi

# (re)start postgres
echo "Downing all docker-compose.yml containers ------------------------------"
$DOCKER_COMMAND down
sleep ${SLEEP}
echo "Upping docker-compose.yml postgres container ---------------------------"
$DOCKER_COMMAND up -d postgres

echo "Pausing ${DBPAUSE} seconds for postgres to fully start -------------------"
while [[ ${DBPAUSE} -gt 0 ]]; do
	echo -n "${DBPAUSE} "
	DBPAUSE=$((DBPAUSE-1))
	sleep 1
done
echo 

# (re)create the instance we are going to load the dumps into
echo "dropdb ------------------------------------------------"
$DOCKER_COMMAND exec postgres dropdb -U postgres w3act
sleep ${SLEEP}
#echo "createdb ----------------------------------------------"
$DOCKER_COMMAND exec postgres createdb -U postgres w3act
sleep ${SLEEP}

# restore dump into this instance
echo "Importing data..."
$DOCKER_COMMAND exec postgres pg_restore -v -U w3act -n public -d w3act /tmp/w3act_dump.sql

# done - we now have a postgres instance (in a volume which will persist outside this container if we've mounted it)
echo "Shutting down..."
$DOCKER_COMMAND down
