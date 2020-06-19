#!/bin/bash

# Fail on errors:
set -e

# Check args
if [ "$#" -ne 2 ]; then
    echo `basename $0` "<trackdb-url>" "<hdfs-absolute-path>"
    exit 1
fi

# Common vars:
export DIR=$(dirname "$0")
export TASK_IMG=${TASK_IMG:-ukwa/ukwa-manage}

# Specify which TrackDB to populate:
export TRACKDB_URL=$1
# Specify which path to list:
export HADOOP_PATH=$2

# Check needed variables are set:
if [ -z "$NAMENODE_IP" ] || [ -z "$JOBTRACKER_IP" ]
then
      echo "The \$NAMENODE_IP, \$JOBTRACKER_IP environment variables must be set!"
      exit 1
fi

# Ensure we only run one copy of this script at a time:
LOCKFILE="/var/tmp/`basename $0`.lock"
touch $LOCKFILE
chmod a+rw $LOCKFILE # cope if different users use the same lockfile
unset lockfd
(
    # Check lock and exit if locked:
    flock -n $lockfd || { echo `basename $0` "is already running!"; exit 1; }

    echo "TODO: Should we check if this has already run today? Or just re-run?"

    # Run the Hadoop recursive list command and collect the result:
    echo "Running 'hadoop fs -lsr" $HADOOP_PATH "'..."
    docker run -i --add-host=namenode:$NAMENODE_IP --add-host=jobtracker:$JOBTRACKER_IP \
        ukwa/docker-hadoop:hadoop-0.20 hadoop fs -lsr $HADOOP_PATH > hadoop-lsr.txt

    # Convert the recursive list to enriched JSONL:
    echo "Converting lsr to jsonl..."
    cat hadoop-lsr.txt | docker run -i $TASK_IMG store lsr-to-jsonl - - > hadoop-lsr.jsonl

    # Import the JSONL into the TrackDB:
    echo "Importing jsonl into the TrackDB at ${TRACKDB_URL}..."
    cat hadoop-lsr.jsonl |  docker run -i $TASK_IMG trackdb import -t $TRACKDB_URL files -

) {lockfd}< $LOCKFILE
