#!/bin/sh

# Common setup:
source ./common.env

# Which dump to use
FILENAME="/2_backups/prod1.n45.wa.bl.uk/w3act_postgres/w3act.pgdump-20211201"

echo "Downloading $FILENAME to ${W3ACT_DUMPS_DIR}"
curl -o ${W3ACT_DUMPS_DIR}/w3act_dump.sql "http://hdfs.api.wa.bl.uk/webhdfs/v1${FILENAME}?op=OPEN&user.name=access"
