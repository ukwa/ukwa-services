"""
## warc_tidy.py

Tasks for tidying up WARCs
"""
import logging
import json
import sys

from subprocess import check_output

from airflow.decorators import dag, task
from airflow.operators.python import get_current_context
from airflow.operators.docker_operator import DockerOperator
from airflow.utils.dates import days_ago

from _common_ import Config

# Pick up shared configuration:
c = Config()

# These args will get passed on to each operator/task:
default_args = c.get_default_args_for_access()

@dag(
    default_args=default_args, 
    schedule_interval='@hourly',
    start_date=days_ago(1),
    max_active_runs=1,
    catchup=False,
    tags=['ingest']
)
def warc_tidy_up():
    """
### Tidy-up WARCs

This task performs some work to tidy up the WARCs from the crawler.  It

* Moves WARCs from warcprox into the right place in the /heritrix/output folders.
* **TBA** 'Closes' WARCs that are .open, if they are older than a few days.

How to check it's working:

* Task Instance logs show how many WARCs were moved.
* If configured, Prometheus updated via Push Gateway with `ukwa_files_moved_total_count{job="warc_tidy"}` counts.

    """

    tidy = DockerOperator(
        task_id='move-warcprox-warcs',
        image=c.ukwa_task_image,
        command='store -v warctidy',
        user=0, # Run as root due to file permissions
        volumes=['/mnt/gluster/fc:/mnt/gluster/fc'],
        environment={
            'PUSH_GATEWAY': c.push_gateway,
        },
        tty=True, # <-- So we see logging
        do_xcom_push=False,
    )

warc_tidy_up_dag = warc_tidy_up()
