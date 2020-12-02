#!/bin/bash

# Stop on errors:
set -e

# Source env
#export HDFS_W3ACT_DB_CSV=/9_processing/w3act/w3act-db-csv.zip

# Change into data export folder:
cd /w3act_export

# Dump W3ACT DB as CSV
echo "Downloading W3ACT CSV from Hadoop..."
rm -f w3act-db-csv.zip w3act-db-csv/*.*
python /w3act_export_scripts/download_w3act_dump.py

# Generate the OA access list
echo "Generating open-access allow list..."
w3act -d w3act-db-csv gen-acl allows.aclj.new
w3act -d w3act-db-csv gen-acl --format surts allows.txt.new
w3act -d w3act-db-csv gen-annotations annotations.json.new

# Copy the allows, and then update atomically:
echo "Updating allow lists etc..."
mv -f allows.aclj.new allows.aclj
mv -f allows.txt.new allows.txt
mv -f annotations.json.new annotations.json

# Update the OA service blocks list:
echo "Pulling latest blocks file from GitLab..."
python /w3act_export_scripts/download_blocks.py

# Copy the blocks, and then update atomically:
echo "Updating block list..."
mv -f blocks.aclj.new blocks.aclj

# Now update the Collections Solr:`
w3act -d w3act-db-csv update-collections-solr http://collections_solr:8983/solr/collections

# Worked, so sleeping
echo "Sleeping..."
sleep 20m

