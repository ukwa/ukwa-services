"""
## warc_tidy.py

Tasks for tidying up WARCs
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
    'crawler_tidy_up',
    default_args=default_args,
    description='Tidy up WARCs and logs from crawlers.',
    schedule_interval='@hourly',
    start_date=days_ago(1),
    max_active_runs=1,
    catchup=False,
    tags=['ingest'],
) as dag:
    dag.doc_md = f"""
### Tidy-up WARCs and logs from crawlers

This task performs some work to tidy up the WARCs and logs from the crawler.  It

* Moves WARCs from warcprox (the `/heritrix/wren` folder) into the right place in the `/heritrix/output` folders.
* **TBA** 'Closes' WARCs that are .open, if they are older than a few days.
* Checks all the expected log files are present, e.g. crawl.log.
* Replaces missing log files with empty files, so the crawler can checkpoint successfully.
* Records the size of the crawl logs in Prometheus so we can tell if they stop growing (metrics are `ukwa_crawler_log_size_bytes`, `ukwa_crawler_log_touch_seconds`).

Configuration:

* The tasks are configured to scan folders on `/mnt/gluster/fc`.
* The push gateway is configured to be `{c.push_gateway}`.

How to check it's working:

* Task Instance logs show how many WARCs were moved.
* Prometheus updated via Push Gateway with e.g. `ukwa_files_moved_total_count{{kind='warcprox-warcs'}}` counts.
    * Look for job results in [the push gateway configured for this task](http://{c.push_gateway}).
    * For example results from Prometheus in production, see e.g.:
        * [ukwa_files_moved_total_count](http://monitor-prometheus.api.wa.bl.uk/graph?g0.expr=ukwa_files_moved_total_count{{kind%3D"warcprox-warcs"}}&g0.tab=0&g0.stacked=0&g0.range_input=1w).
        * [ukwa_crawler_log_size_bytes](http://monitor-prometheus.api.wa.bl.uk/graph?g0.expr=ukwa_crawler_log_size_bytes&g0.tab=0&g0.stacked=0&g0.range_input=1w).

""" 

    tidy_warcs = DockerOperator(
        task_id='tidy-up-warcs',
        image=c.ukwa_task_image,
        command='tidy-warcs --prefix /mnt/gluster/fc',
        user=0, # Run as root due to file permissions
        mounts= [
            Mount( source='/mnt/gluster/fc', target='/mnt/gluster/fc', type='bind' )
        ],
        environment={
            'PUSH_GATEWAY': c.push_gateway,
        },
        tty=True, # <-- So we see logging
        do_xcom_push=False,
    )

    tidy_logs = DockerOperator(
        task_id='tidy-up-fc-npld-crawl-logs',
        image=c.ukwa_task_image,
        command='tidy-logs --job-dir /mnt/gluster/fc/heritrix/output/frequent-npld',
        user=0, # Run as root due to file permissions
        mounts= [
            Mount( source='/mnt/gluster/fc', target='/mnt/gluster/fc', type='bind' )
        ],
        environment={
            'PUSH_GATEWAY': c.push_gateway,
        },
        tty=True, # <-- So we see logging
        do_xcom_push=False,
    )
