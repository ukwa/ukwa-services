#!/bin/bash

# Stop on errors:
set -e

# Source env
export HDFS_W3ACT_DB_CSV=/9_processing/w3act/w3act-db-csv.zip
export ALLOWS_FILE=/mnt/nfs/data/website/open-access-acl/allows.aclj
export BLOCKS_FILE=/mnt/nfs/data/website/open-access-acl/blocks.aclj

# Dump W3ACT DB as CSV
echo "Downloading W3ACT CSV from Hadoop..."
rm -f w3act-db-csv.zip w3act-db-csv/*.*
docker run -ti -v $PWD:/host anjackson/ukwa-manage:trackdb-lib store get $HDFS_W3ACT_DB_CSV /host/w3act-db-csv.zip 
unzip -o w3act-db-csv.zip

# Generate the OA access list
echo "Generating open-access allow list..."
docker run -i -v $PWD:/host ukwa/python-w3act w3act -d /host/w3act-db-csv gen-acl /host/allows.aclj
docker run -i -v $PWD:/host ukwa/python-w3act w3act -d /host/w3act-db-csv gen-acl --format surts /host/allows.txt
docker run -i -v $PWD:/host ukwa/python-w3act w3act -d /host/w3act-db-csv gen-annotations /host/annotations.json

# Copy the allows, and then update atomically:
echo "Updating allow list at ${ALLOWS_FILE}"
cp allows.aclj ${ALLOWS_FILE}.new
mv -f ${ALLOWS_FILE}.new ${ALLOWS_FILE}

# Update the OA service blocks list:
echo "Pulling latest blocks file from GitLab..."
curl -o blocks.aclj "http://git.wa.bl.uk/bl-services/wayback_excludes_update/-/raw/master/oukwa/acl/blocks.aclj"

# Copy the blocks, and then update atomically:
echo "Updating block list at ${BLOCKS_FILE}"
cp blocks.aclj ${BLOCKS_FILE}.new
mv -f ${BLOCKS_FILE}.new ${BLOCKS_FILE}

