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
    'warc_tidy_up',
    default_args=default_args,
    description='Tidy up WARCs from crawlers.',
    schedule_interval='@hourly',
    start_date=days_ago(1),
    max_active_runs=1,
    catchup=False,
    tags=['ingest'],
) as dag:
    dag.doc_md = f"""
### Tidy-up WARCs

This task performs some work to tidy up the WARCs from the crawler.  It

* Moves WARCs from warcprox into the right place in the /heritrix/output folders.
* **TBA** 'Closes' WARCs that are .open, if they are older than a few days.

Configuration:

* The tasks are configured to scan `/mnt/gluster/fc`.
* The push gateway is configured to be `{c.push_gateway}`.

How to check it's working:

* Task Instance logs show how many WARCs were moved.
* Prometheus updated via Push Gateway with `ukwa_files_moved_total_count{{kind='warcprox-warcs'}}` counts.
    * Look for job results in [the push gateway configured for this task](http://{c.push_gateway}).
    * For example results from Prometheus in production, see [here](http://monitor-prometheus.api.wa.bl.uk/graph?g0.expr=ukwa_files_moved_total_count{{kind='warcprox-warc'}}&g0.tab=0&g0.stacked=0&g0.range_input=4w).

""" 

    tidy = DockerOperator(
        task_id='move-warcprox-warcs',
        image=c.ukwa_task_image,
        command='store -v warctidy',
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

