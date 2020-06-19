#!/bin/bash

# Exit when any (simple) command fails:
set -e

#
# The following structure ensures only one copy of this scripts runs on one machine at a time.
# Buy using flock, we ensure the lock is released when this script exits. We don't have to clean up
# our own PID/lock files.
#
# Details of this Bash flock pattern were based on: 
# https://unix.stackexchange.com/questions/184259/can-someone-explain-how-to-use-flock-and-file-descriptors-to-lock-a-file-and-wri
#

TAG=${1:-dev}
PSQL_HOST=${2:-postgres}
PSQL_PORT=${3:-5432}

# Ensure we only run one copy of this script at a time:
LOCKFILE="/var/tmp/`basename $0`.lock"
touch $LOCKFILE
chmod a+rw $LOCKFILE # cope if different users use the same lockfile
unset lockfd
(
    # Check lock status:
    flock -n $lockfd || { echo `basename $0` "is already running!"; exit 1; }

    # If all is well, run the tasks here:
    echo "TODO: Should check the output file exists and is up to date before running..."
    echo "Dumping the W3ACT database as CSV/JSON and uploading to HDFS.."
    source /mnt/nfs/config/gitlab/ukwa-services-env/w3act/dev/w3act.env
    # Make a folder for the CSV dump:
    mkdir -p w3act-db-csv

     # Download the CSV dump of the W3ACT database:
    docker run -t \
        -e W3ACT_PSQL_PASSWORD \
        -v $PWD/w3act-db-csv:/w3act-db-csv \
        ukwa/python-w3act \
        w3act -d /w3act-db-csv get-csv -H $PSQL_HOST -P $PSQL_PORT

    # ZIP it:
    zip -r w3act-db-csv.zip w3act-db-csv

    # Upload to HDFS, using the 'ingest' user account:
    docker run -t \
        -v $PWD/w3act-db-csv.zip:/w3act-db-csv.zip \
        ukwa/ukwa-manage \
        store -u ingest put --backup-and-replace /w3act-db-csv.zip /9_processing/w3act/${TAG}/w3act-db-csv.zip

) {lockfd}< $LOCKFILE