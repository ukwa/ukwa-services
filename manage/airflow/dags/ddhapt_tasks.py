"""
## ddhapt_tasks.py

Tasks that are for the Document Harvester a.k.a. DDHAPT.
"""
import logging
import json
import sys
import os
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

# Static location of crawl feed for watched targets:
CRAWL_FEED_NPLD = '/storage/data_exports/crawl_feed_npld.jsonl'

# Pick up proxy for external connections:
EXTERNAL_WEB_PROXY = os.environ['EXTERNAL_WEB_PROXY']


with DAG(
    'ddhapt_log_analyse',
    default_args=default_args,
    description='Log analysis and document extraction.',
    schedule_interval='0 4 * * *',
    start_date=datetime(2022, 6, 12), #'2022-06-24' for the Border Operating Model example
    max_active_runs=1,
    catchup=True,
    params={
        'trackdb_url' : trackdb_url,
        'df_db': c.ddhapt_df_db.get_uri(),
        'crawl_feed': CRAWL_FEED_NPLD,
    },
    tags=['ingest', 'docharv', 'h3'],
) as dag:
    dag.doc_md = f"""
### Analyse logs and extract documents

This task performs the log analysis required to extract documents.

* Runs the `windex log-analyse` command, which:
    * Checks for log files in TrackDB with a Last Modified date of the day of the run.
        * This needs TrackDB to be up-to-date, so no files with modification dates in the past suddenlty appear. This DAG runs at 4am as this should be enough time for yesterday's file listings to be updated.
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
    * See [this query that lists recently processed crawl logs]({dag.params['trackdb_url']}/select?indent=true&q=log_analysis_ss%3A[*%20TO%20*]&sort=modified_at_dt%20desc).
    * And [this query lists recent crawl logs that have not been processed]({dag.params['trackdb_url']}/select?indent=true&q=-log_analysis_ss%3A%5B*%20TO%20*%5D+kind_s:crawl-logs+stream_s:frequent&sort=modified_at_dt%20desc&rows=100).
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


with DAG(
    'ddhapt_process_docs',
    default_args=default_args,
    description='Gets metadata for found documents, pushes them to W3ACT.',
    schedule_interval='@hourly',
    start_date=days_ago(1),
    max_active_runs=1,
    catchup=False,
    params={
        'df_db': c.ddhapt_df_db.get_uri(),
        'crawl_feed': CRAWL_FEED_NPLD,
        'cdx_url': 'http://cdx.api.wa.bl.uk/data-heritrix', #c.get_access_cdx_url(),
        'w3act_url': f"http://{c.ddhapt_w3act_web_conn.host}/act",
        'w3act_user': c.ddhapt_w3act_web_conn.login,
        'w3act_pw': c.ddhapt_w3act_web_conn.password,
        'batch_size': 400,
    },
    tags=['ingest', 'docharv', 'w3act'],
) as dag2:
    dag2.doc_md = f"""
### Document Metadata Extraction to W3ACT

This task analyses documents extracts metadata and posts them to W3ACT.

* Runs the `ddhapt process` command, which:
    * Processes `{dag2.params['batch_size']}` _NEW_ records from the 'Documents Found' database, in small chunks.
    * For each one, it checks if it's in the CDX, and if so, it attempts to work out the document metadata and push the record to W3ACT.
    * The results are used to update the 'Documents Found' database, e.g. _NEW_ documents are _ACCEPTED_ (in W3ACT) or _REJECTED_.

Configuration:

* Uses crawl feed at `{dag2.params['crawl_feed']}`.
* The Documents Found database is configured to be `{dag2.params['df_db']}`.
* Refers to the CDX index at `{dag2.params['cdx_url']}`.
* Talks to W3ACT via `{dag2.params['w3act_url']}` using credentials `{dag2.params['w3act_user']}`/`{dag2.params['w3act_pw']}`.
* The push gateway is configured to be `{c.push_gateway}`.

How to check it's working:

* The Task Instance logs in Airflow will show e.g. how many document processed.
* Check for metrics in Prometheus (updated via Push Gateway):
    * Look for job result metrics in [the push gateway configured for this task](http://{c.push_gateway}), e.g.:
        * `ukwa_task_batch_size{{job="???", status="success"}}`
        * `ukwa_task_event_timestamp{{job="???"}}`

Tool container versions:

 * UKWA Manage Task Image: `{c.ukwa_task_image}`

""" 

    doc_job = DockerOperator(
        task_id='ddhapt_process_docs_found',
        image=c.ukwa_task_image,
        # Add proxy settings:
        environment= {
            'PUSH_GATEWAY': c.push_gateway,
            "HTTP_PROXY": EXTERNAL_WEB_PROXY,
            "HTTPS_PROXY": EXTERNAL_WEB_PROXY,
            "NO_PROXY": "wa.bl.uk,ad.bl.uk",
        },
        command='docharv process -v \
            --act-url {{ params.w3act_url }} \
            --act-user {{ params.w3act_user }} \
            --act-pw {{ params.w3act_pw }} \
            --cdx {{ params.cdx_url }} \
            --batch-size {{ params.batch_size }} \
            -T {{ params.crawl_feed }} \
            -D {{ params.df_db }}',
        tty=True, # <-- So we see logging (stderr is inline?)
        do_xcom_push=False,
    ) 

 
