#!/bin/bash

# Stop on errors:
set -e

# Source env
export HDFS_W3ACT_DB_CSV=/9_processing/w3act/w3act-db-csv.zip
export ALLOWS_FILE=/w3act_export/pywb/allows.aclj
export BLOCKS_FILE=/w3act_export/pywb/blocks.aclj

# Change into data export folder:
cd /w3act_export

# Dump W3ACT DB as CSV
echo "Downloading W3ACT CSV from Hadoop..."
rm -f w3act-db-csv.zip w3act-db-csv/*.*
python /w3act_export_scripts/download_w3act_dump.py

# Generate the OA access list
echo "Generating open-access allow list..."
w3act -d w3act-db-csv gen-acl allows.aclj
w3act -d w3act-db-csv gen-acl --format surts allows.txt
w3act -d w3act-db-csv gen-annotations annotations.json

# Copy the allows, and then update atomically:
echo "Updating allow list at ${ALLOWS_FILE}"
mkdir -p /w3act_export/pywb
cp allows.aclj ${ALLOWS_FILE}.new
mv -f ${ALLOWS_FILE}.new ${ALLOWS_FILE}

# Update the OA service blocks list:
echo "Pulling latest blocks file from GitLab..."
python /w3act_export_scripts/download_blocks.py

# Copy the blocks, and then update atomically:
echo "Updating block list at ${BLOCKS_FILE}"
cp blocks.aclj ${BLOCKS_FILE}.new
mv -f ${BLOCKS_FILE}.new ${BLOCKS_FILE}

# Worked, so sleeping
echo "Sleeping..."
sleep 5m

