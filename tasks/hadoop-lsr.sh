#!/bin/bash

# Fail on errors:
set -e

# Check args
if [ "$#" -ne 1 ]; then
    echo `basename $0` "<hdfs-absolute-path>"
    exit 1
fi

# Common vars:
export DIR=$(dirname "$0")
source ${DIR}/task.env.sh

# Specify which path to list:
export HADOOP_PATH=$1

# Ensure we only run one copy of this script at a time:
LOCKFILE="/var/tmp/`basename $0`.lock"
touch $LOCKFILE
unset lockfd
(
    # Check lock and exit if locked:
    flock -n $lockfd || { echo `basename $0` "is already running!"; exit 1; }

    echo "TODO: Should check the output file exists and is up to date before running..."

    # Run the Hadoop recursive list command and collect the result:
    echo "Running 'hadoop fs -lsr" $HADOOP_PATH "'..."
    docker run -i --add-host=namenode:$NN_IP --add-host=jobtracker:$JT_IP \
        ukwa/docker-hadoop:hadoop-0.20 hadoop fs -lsr $HADOOP_PATH > hadoop-lsr.txt

    # Convert the recursive list to enriched JSONL:
    echo "Converting lsr to jsonl..."
    cat hadoop-lsr.txt | docker run -i $TASK_IMG store lsr-to-jsonl - - > hadoop-lsr.jsonl

    # Import the JSONL into the TrackDB:
    echo "Importing jsonl into the TrackDB at ${TRACKDB_URL}..."
    cat hadoop-lsr.jsonl |  docker run -e TRACKDB_URL -i $TASK_IMG trackdb files import -

) {lockfd}< $LOCKFILE
