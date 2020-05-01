#!/bin/sh

# Source env
source ~/gitlab/ukwa-services-env/w3act/dev/w3act.env
export ALLOWS_FILE=/mnt/nfs/data/website/open-access-acl/allows.aclj

# Dump W3ACT DB as CSV
echo "Dumping W3ACT database to CSV..."
docker run -i -v $PWD/w3act-db-csv:/w3act-db-csv ukwa/python-w3act w3act -d /w3act-db-csv get-csv -H 192.168.45.60 -P 5434 -p $W3ACT_PSQL_PASSWORD

# Generate the OA access list
echo "Generating open-access allow list..."
docker run -i -v $PWD/w3act-db-csv:/w3act-db-csv ukwa/python-w3act w3act -d /w3act-db-csv gen-acl /w3act-db-csv/allows.aclj

# Copy the allows, and then update atomically:
echo "Updating allow list at ${ALLOWS_FILE}"
cp $PWD/w3act-db-csv/allows.aclj ${ALLOWS_FILE}.new
mv -f ${ALLOWS_FILE}.new ${ALLOWS_FILE}
