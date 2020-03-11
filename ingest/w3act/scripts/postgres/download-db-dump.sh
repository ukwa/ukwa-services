#!/bin/sh

# Common setup:
source ./common.env

# Which dump to use
FILENAME="/2_backups/ingest/ife_prod_postgres/w3act.pgdump-20200311"

echo "Downloading $FILENAME"
curl -o ${W3ACT_DUMPS_DIR}/w3act_dump.sql "http://hdfs:14000/webhdfs/v1${FILENAME}?op=OPEN&user.name=access"
