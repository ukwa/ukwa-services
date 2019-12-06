#!/bin/sh

curl -o w3act_dump.sql "http://hdfs:14000/webhdfs/v1/2_backups/crawler03/pulsefeprod_postgres_1/w3act.pgdump-20191028?op=OPEN&user.name=access"
