#!/bin/bash

#
# The following structure ensures only one copy of this scripts runs on one machine at a time.
# Buy using flock, we ensure the lock is released when this script exits. We don't have to clean up
# our own PID/lock files.
#
# Details of this Bash flock pattern were based on: 
# https://unix.stackexchange.com/questions/184259/can-someone-explain-how-to-use-flock-and-file-descriptors-to-lock-a-file-and-wri
#
LOCKFILE="/var/tmp/`basename $0`.lock"
touch $LOCKFILE
unset lockfd
(
    # Check lock status:
    flock -n $lockfd || { echo `basename $0` "is already running!"; exit 1; }
    # If all is well, run the tasks here:
    echo "Running..."
    source /mnt/nfs/config/gitlab/ukwa-services-env/w3act/dev/w3act.env
    docker run -ti -e W3ACT_PSQL_PASSWORD --network w3act_default anjackson/ukwa-manage:trackdb-lib w3act-to-hdfs.sh


) {lockfd}< $LOCKFILE