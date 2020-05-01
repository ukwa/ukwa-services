#!/bin/sh

# Source env:
source ~/gitlab/ukwa-services-env/w3act/dev/w3act.env

# HDFS location:
export HDFS_W3ACT_DB_CSV=/9_processing/w3act/w3act-db-csv.zip

# Dump W3ACT DB as CSV:
echo "Dumping W3ACT database to CSV..."
rm -f w3act-db-csv/*.*
docker run -i -v $PWD:/host ukwa/python-w3act w3act -d /host/w3act-db-csv get-csv -H 192.168.45.60 -P 5434 -p $W3ACT_PSQL_PASSWORD

# ZIP it:
rm -f w3act-db-csv.zip
zip -r w3act-db-csv.zip w3act-db-csv

# Push to Hadoop, and if there's already a file with that name, move it aside and keep it as a backup:
docker run -ti -v $PWD:/host anjackson/ukwa-manage:trackdb-lib store -u ingest put --backup-and-replace /host/w3act-db-csv.zip $HDFS_W3ACT_DB_CSV


