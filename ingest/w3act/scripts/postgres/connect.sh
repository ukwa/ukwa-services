#!/bin/sh

export MY_IP=`hostname -I | awk '{print $1}'`

docker run -it -e PGPASSWORD=$W3ACT_PSQL_PASSWORD postgres:9.6.2 psql -h $MY_IP -p 5432 -U w3act

