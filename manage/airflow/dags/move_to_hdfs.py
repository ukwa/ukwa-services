"""
## move_to_hdfs.py

Tasks for copying and/or moving content to HDFS
"""
import logging
import json
import sys

from subprocess import check_output

from airflow import DAG
from airflow.decorators import dag, task
from airflow.operators.python import get_current_context
from airflow.operators.docker_operator import DockerOperator
from airflow.utils.dates import days_ago

from docker.types import Mount

from _common_ import Config

# Pick up shared configuration:
c = Config()

# These args will get passed on to each operator/task:
default_args = c.get_default_args()

with DAG(
    'copy_to_hdfs',
    default_args=default_args,
    description='Copy WARCs/crawl logs from Gluster to Hadoop 3 HDFS',
    schedule_interval='@hourly',
    start_date=days_ago(1),
    max_active_runs=1,
    catchup=False,
    tags=['ingest'],
) as dag:
    dag.doc_md = f"""
### Copy WARCs and crawl logs from Gluster to Hadoop 3 HDFS

This task performs some work to tidy up the WARCs and logs from the crawler.

* Uses the rclone command to upload data to HDFS.
* Does not need to be backfilled, as each run always attempts to catch up with all uploads.
* **CURRENTLY HARDCODED TO DRY-RUN ONLY**

Configuration:

* The tasks are configured to look for files on `/mnt/gluster/fc`.
* The push gateway is configured to be `{c.push_gateway}`.

How to check it's working:

* The Task Instance logs in Airflow will show e.g. how many WARCs were copied.

Tool container versions:

 * Rclone Image: `{c.rclone_image}`

""" 

    up_to_hdfs = DockerOperator(
        task_id='upload-fc-npld-to-h3-hdfs',
        image=c.rclone_image,
        command='copy --hdfs-namenode h3nn.wa.bl.uk:54310 --hdfs-username ingest' \
		' /mnt/gluster/fc/heritrix/output/frequent-npld :hdfs:/heritrix/output/frequent-npld' \
		' --include "*.warc.gz" --include "crawl.log.cp*"' \
		' --no-traverse --dry-run',
        # rclone copy --max-age 48h --no-traverse /mnt/gluster/fc/heritrix/output/frequent-npld hadoop3:/heritrix/output/frequent-npld --include "*.warc.gz" --include "crawl.log.cp*"

        #user=0, # Run as root due to file permissions
        mounts= [
            Mount( source='/mnt/gluster/fc', target='/mnt/gluster/fc', type='bind' )
        ],
        tty=True, # <-- So we see logging
        do_xcom_push=False,
    )
