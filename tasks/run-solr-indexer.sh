#!/bin/bash

# Fail on errors:
set -e

# Common vars:
export DIR=$(dirname "$0")
source ${DIR}/task.env.sh

# Specific vars:
export STREAM="frequent"
export YEAR="2020"
export SOLR_COLLECTION=fc-2020-test
export SOLR_ZKS="dev-zk1:2182,dev-zk2:2182,dev-zk3:2182"

# Ensure we only run one copy of this script at a time:
LOCKFILE="/var/tmp/`basename $0`.lock"
touch $LOCKFILE
unset lockfd
(
    # Check lock and exit if locked:
    flock -n $lockfd || { echo `basename $0` "is already running!"; exit 1; }

    echo "Solr indexing WARCs from $TRACKDB_URL for ${STREAM} ${YEAR} and using ${TASK_IMG}..."
    docker run -i $TASK_IMG -v ${SHARED}:/shared windex solr-index \
        --trackdb-url $TRACKDB_URL \
        --stream $STREAM \
        --year $YEAR \
        --solr-collection ${SOLR_COLLECTION} \
        --zks ${SOLR_ZKS} \
        --batch-size 1000 \
        /shared/warc-npld.conf \
        /shared/annotations.json \
        /shared/allows.txt

) {lockfd}< $LOCKFILE

