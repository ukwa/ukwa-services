#!/bin/bash

# Fail on errors:
set -e

# Common vars:
export DIR=$(dirname "$0")
source ${DIR}/task.env.sh

# Specific vars:
# TODO These should be command arguments
export STREAM="frequent"
export YEAR="2020"

# Ensure we only run one copy of this script at a time:
LOCKFILE="/var/tmp/`basename $0`.lock"
touch $LOCKFILE
chmod a+rw $LOCKFILE # cope if different users use the same lockfile
unset lockfd
(
    # Check lock and exit if locked:
    flock -n $lockfd || { echo `basename $0` "is already running!"; exit 1; }

    echo "CDX indexing WARCs from $TRACKDB_URL for ${STREAM} ${YEAR} and using ${TASK_IMG}, into ${CDX_SERVICE}/${CDX_COLLECTION}..."
    docker run -i $TASK_IMG windex cdx-index \
        --trackdb-url $TRACKDB_URL \
        --stream $STREAM \
        --year $YEAR \
        --cdx-collection $CDX_COLLECTION \
        --cdx-service $CDX_SERVICE \
        --batch-size 1000

) {lockfd}< $LOCKFILE

