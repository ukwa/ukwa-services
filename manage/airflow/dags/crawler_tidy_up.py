"""
## crawler_tidy_up.py

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

This task performs some work to tidy up the WARCs and logs from the crawler.

* Runs the `tidy_logs` command, as defined [here](https://github.com/ukwa/ukwa-manage/blob/master/lib/store/tidy_logs.py), which:
    * Checks all the expected log files are present, e.g. `crawl.log`.
    * Replaces missing log files with empty files, so the crawler can checkpoint successfully.
    * Records the size of the crawl logs in Prometheus so we can tell if they stop growing (metrics are `ukwa_crawler_log_size_bytes`, `ukwa_crawler_log_touch_seconds`).
* Runs the `tidy_warcs` command, as defined [here](https://github.com/ukwa/ukwa-manage/blob/master/lib/store/tidy_warcs.py), which:
    * Moves WARCs from warcprox (which are output to the `/heritrix/wren` folder) into the right place in the `/heritrix/output` folders.
    * **TBA** 'Closes' WARCs that are .open, if they are older than a few days.

Configuration:

* The tasks are configured to scan folders on `/mnt/gluster/fc`.
* The push gateway is configured to be `{c.push_gateway}`.

How to check it's working:

* The Task Instance logs in Airflow will show e.g. how many WARCs were moved.
* Check for metrics in Prometheus (updated via Push Gateway):
    * Look for job result metrics in [the push gateway configured for this task](http://{c.push_gateway}), e.g.:
        * `ukwa_files_moved_total_count{{kind='warcprox-warcs'}}`
        * `ukwa_crawler_log_size_bytes`
    * For example results from Prometheus in production, see e.g.:
        * [Count of WARCS moved](http://monitor-prometheus.api.wa.bl.uk/graph?g0.expr=ukwa_files_moved_total_count{{kind%3D"warcprox-warcs"}}&g0.tab=0&g0.stacked=0&g0.range_input=1w).
        * [Size (in bytes) of crawler log files](http://monitor-prometheus.api.wa.bl.uk/graph?g0.expr=ukwa_crawler_log_size_bytes&g0.tab=0&g0.stacked=0&g0.range_input=1w).

Tool container versions:

 * UKWA Manage Task Image: `{c.ukwa_task_image}`

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
