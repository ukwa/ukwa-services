#!/bin/sh

# Use current host
export LOCALHOST_IP=`hostname -I | awk '{print $1}'`

# Common setup
source ./common.env
echo "DOCKER_COMMAND: [${DOCKER_COMMAND}]"
echo "W3ACT_PSQL_DIR: [${W3ACT_PSQL_DIR}]"
echo "W3ACT_DUMPS_DIR:[${W3ACT_DUMPS_DIR}]"
echo "W3ACT_PSQL_PASSWORD: [${W3ACT_PSQL_PASSWORD}]"

# start postgres
$DOCKER_COMMAND down
$DOCKER_COMMAND up -d postgres
sleep 5

# display instructions
echo 
echo "----------------------------------------------------------------------------------------------------"
echo "In a moment you'll be dropped into the psql console container where you can inspect the database"
echo "Once satisfied, exit the container and shut down postgres via:"
echo -e "\tdocker-compose down"
echo "----------------------------------------------------------------------------------------------------"
echo 

# Run psql container
#docker run -it -e PGPASSWORD=${W3ACT_PSQL_PASSWORD} postgres:9.6.2 psql -h ${LOCALHOST_IP} -p 5432 -U w3act
