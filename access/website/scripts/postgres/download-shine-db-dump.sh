#!/bin/sh

HDFS_FILE="/2_backups/access/access_shinedb/shine.pgdump-20201218"

echo "Downloading from ${HDFS_FILE}..."
curl -o shine_dump.sql "http://hdfs.api.wa.bl.uk/webhdfs/v1${HDFS_FILE}?op=OPEN&user.name=access"
