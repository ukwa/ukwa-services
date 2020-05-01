#!/bin/sh

# Source env
export HDFS_W3ACT_DB_CSV=/9_processing/w3act/w3act-db-csv.zip
export ALLOWS_FILE=/mnt/nfs/data/website/open-access-acl/allows.aclj

# Dump W3ACT DB as CSV
echo "Downloading W3ACT CSV from Hadoop..."
rm -f w3act-db-csv.zip w3act-db-csv/*.*
docker run -ti -v $PWD:/host anjackson/ukwa-manage:trackdb-lib store get $HDFS_W3ACT_DB_CSV /host/w3act-db-csv.zip 
unzip -o w3act-db-csv.zip

# Generate the OA access list
echo "Generating open-access allow list..."
docker run -i -v $PWD:/host ukwa/python-w3act w3act -d /host/w3act-db-csv gen-acl /host/allows.aclj

# Copy the allows, and then update atomically:
echo "Updating allow list at ${ALLOWS_FILE}"
cp allows.aclj ${ALLOWS_FILE}.new
mv -f ${ALLOWS_FILE}.new ${ALLOWS_FILE}
