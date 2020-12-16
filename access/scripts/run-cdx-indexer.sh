#!/bin/bash

# Fail on errors:
set -e

# read script environ argument
ENVIRON=$1
if ! [[ ${ENVIRON} =~ dev|beta|prod ]]; then
	echo "ERROR: Script $0 requires environment argument"
	exit
fi

# First load access.[dev|beta|prod].env:
export DIR=$(dirname "$0")
source ${DIR}/access.${ENVIRON}.env

# Check expected VARS exist:
if [[ -z ${TRACKDB_URL} || -z ${NAMENODE_IP} || -z ${JOBTRACKER_IP} || -z ${CDX_SERVICE} || -z ${CDX_COLLECTION} ]]; then
	echo "Expected vars not set! TRACKDB_URL, CDX_SERVICE, CDX_COLLECTION, NAMENODE_IP, JOBTRACKER_IP"
	exit 1
fi

# Get the current year (if the YEAR is unset):
if [ -z "${YEAR}" ]; then 
    YEAR=$(date +'%Y')
fi

# Ensure we only run one copy of this script at a time:
LOCKFILE="/var/tmp/`basename $0`.lock"
touch $LOCKFILE
chmod a+rw $LOCKFILE # cope if different users use the same lockfile
unset lockfd
(
    # Check lock and exit if locked:
    flock -n $lockfd || { echo `basename $0` "is already running!"; exit 1; }

    for STREAM in frequent webrecorder domain;
    do
        echo "Running CDX indexing of WARCs from $TRACKDB_URL for ${STREAM} ${YEAR} into ${CDX_SERVICE}/${CDX_COLLECTION}..."
        docker run -i \
            --add-host=namenode:$NAMENODE_IP \
            --add-host=jobtracker:$JOBTRACKER_IP \
            ukwa/ukwa-manage:latest windex cdx-index \
            --trackdb-url $TRACKDB_URL \
            --stream $STREAM \
            --year $YEAR \
            --cdx-collection $CDX_COLLECTION \
            --cdx-service $CDX_SERVICE \
            --batch-size 1000
    done

) {lockfd}< $LOCKFILE

