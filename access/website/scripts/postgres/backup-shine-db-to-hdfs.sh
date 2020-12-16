#!/bin/sh

# read script environ argument
ENVIRON=$1
if ! [[ ${ENVIRON} =~ dev|beta|prod ]]; then
        echo "ERROR: Script $0 requires environment argument (dev|beta|prod)"
        exit
fi

# Local file:
export SHINE_DUMP=shinedb-$(date '+%Y-%m-%d').sql
# HDFS destination:
export HDFS_W3ACT_DB_BKP=/2_backups/shine/${ENVIRON}/${SHINE_DUMP}

# restore dump into this instance
echo "Dumping Shine DB to ${SHINE_DUMP}..."
docker run --net access_website_default -v $PWD:/host postgres:9.6.2 pg_dump -v -U postgres -h shinedb --format=c --file=/host/${SHINE_DUMP} shine

# Push to HDFS:
echo "Uploading W3ACT DB dump to ${HDFS_W3ACT_DB_BKP}..."
docker run -v $PWD:/host ukwa/ukwa-manage store -u access put --backup-and-replace /host/${SHINE_DUMP} $HDFS_W3ACT_DB_BKP
