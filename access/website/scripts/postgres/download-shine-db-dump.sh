#!/bin/sh

curl -o shine_dump.sql "http://hdfs.api.wa.bl.uk/webhdfs/v1/2_backups/access/access_shinedb/shine.pgdump-20191219?op=OPEN&user.name=access"
