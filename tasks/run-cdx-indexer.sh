#!/bin/bash

# Fail on errors:
set -e

# Common vars:
export DIR=$(dirname "$0")
source ${DIR}/task.env.sh

# Specific vars:
export STREAM="frequent"
export YEAR="2020"

# Ensure we only run one copy of this script at a time:
LOCKFILE="/var/tmp/`basename $0`.lock"
touch $LOCKFILE
unset lockfd
(
    # Check lock and exit if locked:
    flock -n $lockfd || { echo `basename $0` "is already running!"; exit 1; }

    echo "Listing WARCs to index for ${STREAM} ${YEAR} using ${TASK_IMG}..."
    docker run -e TRACKDB_URL -i $TASK_IMG trackdb warcs --stream $STREAM --year $YEAR \
        --field cdx_index_ss _NONE_ list --limit 1000 --ids-only > warcs-to-index.ids

) {lockfd}< $LOCKFILE

