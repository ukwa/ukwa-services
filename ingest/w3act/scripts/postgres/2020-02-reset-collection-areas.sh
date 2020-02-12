#!/bin/sh

export MY_IP=`hostname -I | awk '{print $1}'`

docker run -it -e PGPASSWORD=$W3ACT_PSQL_PASSWORD -v $PWD:/scripts postgres:9.6.2 psql -h $MY_IP -p 5432 -U w3act -d w3act -f /scripts/2020-02-reset-collection-areas.sql

