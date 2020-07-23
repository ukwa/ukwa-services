#!/bin/sh

# Common setup
source ./common.env
echo "DOCKER_COMMAND: [${DOCKER_COMMAND}]"
echo "W3ACT_PSQL_DIR: [${W3ACT_PSQL_DIR}]"
echo "W3ACT_DUMPS_DIR:[${W3ACT_DUMPS_DIR}]"
echo "W3ACT_PSQL_PASSWORD: [${W3ACT_PSQL_PASSWORD}]"

# Where to put the results:
export HDFS_W3ACT_DB_BKP=/2_backups/w3act/dev/w3act_dump.sql

# restore dump into this instance
echo "Dumping W3ACT DB to ${W3ACT_DUMPS_DIR}..."
export PGPASSWORD=$W3ACT_PSQL_PASSWORD
docker run -i --net w3act_default -v $W3ACT_DUMPS_DIR:/host -e PGPASSWORD postgres:9.6.2 pg_dump -v -U w3act -h postgres --format=c --file=/host/w3act_dump.sql w3act

# Push to HDFS:
echo "Uploading W3ACT DB dump to ${HDFS_W3ACT_DB_BKP}..."
docker run -i -v $W3ACT_DUMPS_DIR:/host anjackson/ukwa-manage:trackdb-lib store -u ingest put --backup-and-replace /host/w3act_dump.sql $HDFS_W3ACT_DB_BKP