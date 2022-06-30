"""
## ddhapt_tasks.py

Tasks that are for the Document Harvester a.k.a. DDHAPT.
"""
import logging
import json
import sys
from datetime import datetime

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

# Connection to TrackDB to use:
trackdb_url = c.get_trackdb_url()


with DAG(
    'ddhapt_log_analyse',
    default_args=default_args,
    description='Log analysis and document extraction.',
    schedule_interval='@daily',
    start_date=datetime(2022, 6, 24), #'2022-06-24'
    max_active_runs=1,
    catchup=True,
    params={
        'trackdb_url' : trackdb_url,
        'df_db': c.ddhapt_df_db.get_uri(),
        'crawl_feed': '/storage/data_exports/crawl_feed_npld.jsonl',
    },
    tags=['ingest', 'docharv', 'h3'],
) as dag:
    dag.doc_md = f"""
### Analyse logs and extract documents

This task performs the log analysis required to extract documents.

* Runs the `windex log-analyse` command, which:
    * Checks for log files in TrackDB with a Last Modified date of the day of the run.
    * Runs a Hadoop 3 job to process the logs.
    * Post-processes the log results and pushes and documents to the 'Documents Found' database.

Configuration:

* Uses crawl feed at `{dag.params['crawl_feed']}`.
* The TrackDB database is configured to be `{dag.params['trackdb_url']}`.
* The Documents Found database is configured to be `{dag.params['df_db']}`.
* The push gateway is configured to be `{c.push_gateway}`.

How to check it's working:

* The Task Instance logs in Airflow will show e.g. how many document processed.
* Check TrackDB to see if it's being updated:
    * Processed log files should gain a `log_analysis_ss='done'` field.
    * See [this example query]({dag.params['trackdb_url']}/select?indent=true&q=log_analysis_ss%3A[*%20TO%20*]&sort=modified_at_dt%20desc).
* Check for metrics in Prometheus (updated via Push Gateway):
    * Look for job result metrics in [the push gateway configured for this task](http://{c.push_gateway}), e.g.:
        * `ukwa_task_batch_size{{job="log-analyse-h3-frequent", status="success"}}`
        * `ukwa_task_event_timestamp{{job="log-analyse-h3-frequent"}}`

Tool container versions:

 * UKWA Manage Task Image: `{c.ukwa_task_image}`

""" 

    log_job = DockerOperator(
        task_id='ddhapt_h3_log_analysis',
        image=c.ukwa_task_image,
        # Add Hadoop settings:
        environment= {
            'MRJOB_CONF': '/etc/mrjob_h3.conf',
            'PUSH_GATEWAY': c.push_gateway,
        },
        command='windex log-analyse -v \
            -t {{ params.trackdb_url }} \
            -H h3 \
            -T {{ params.crawl_feed }} \
            -D {{ params.df_db }} \
            -d {{ ds }}',
        tty=True, # <-- So we see logging
        do_xcom_push=False,
    ) 

      