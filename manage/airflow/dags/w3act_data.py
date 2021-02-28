"""
## w3act_to_hdfs.py
"""
import json
import os

from airflow.decorators import dag, task
from airflow.utils.decorators import apply_defaults
from airflow.utils.dates import days_ago
from airflow.operators.bash import BashOperator
from airflow.operators.docker_operator import DockerOperator

from _common_ import Config

# Pick up shared configuration:
c = Config()

# These args will get passed on to each operator/task:
default_args = c.get_default_args_for_access()

# ----------------------------------------------------------------------------
# Define common tasks as Operators:
# ----------------------------------------------------------------------------

class W3ACTDumpCleanupOperator(DockerOperator):
        @apply_defaults
        def __init__(self,**kwargs) -> None:
            super().__init__(
                task_id = 'cleanup_db_folder',
                image = c.w3act_task_image,
                command = 'rm -fr /storage/{{ params.dump_name }} /storage`/{{ params.dump_name }}.sql',
                do_xcom_push = False,
                **kwargs)

class W3ACTDumpOperator(DockerOperator):
        @apply_defaults
        def __init__(self, **kwargs) -> None:
            super().__init__(
                task_id = 'dump_w3act',
                image = c.w3act_task_image,
                command = 'w3act -d /storage/{{ params.dump_name }} get-csv -H {{ params.host }} -P {{ params.port }} -p {{ params.pw }}',
                do_xcom_push = False,
                **kwargs)


# ----------------------------------------------------------------------------
# ----------------------------------------------------------------------------
# Define workflow DAGs:
# ----------------------------------------------------------------------------
# ----------------------------------------------------------------------------

# ----------------------------------------------------------------------------
# Generate data exports:
# ----------------------------------------------------------------------------
@dag(
    default_args=default_args, 
    schedule_interval='@hourly',
    start_date=days_ago(1),
    catchup=False,
    params={
        'host': c.access_w3act_host,
        'port': c.access_w3act_port,
        'pw': c.w3act_password,
        'dump_name': 'w3act_export',
        'storage_path': c.storage_path,
        'tag': c.deployment_context.lower()
    },
    tags=['access', 'w3act']
)
def w3act_export():
    """
### Export data from W3ACT

This dumps the W3ACT database and extracts useful data from it. This includes:

- Crawl feeds
- Access lists
- Annotations files

These are necessary pre-requisites for access processes, like indexing and playback.
    """

    # Shared operator definitions:
    cleanup = W3ACTDumpCleanupOperator()
    dump = W3ACTDumpOperator()
    
    # Define workflow dependencies:
    cleanup >> dump

# ----------------------------------------------------------------------------
# Backup to HDFS
# ----------------------------------------------------------------------------
@dag(
    default_args=default_args, 
    schedule_interval='0 0,12 * * *', # Twice a day
    start_date=days_ago(1),
    catchup=False,
    params={
        'host': c.access_w3act_host,
        'port': c.access_w3act_port,
        'pw': c.w3act_password,
        'dump_name': 'w3act_dump',
        'tag': c.deployment_context.lower()
    },
    tags=['ingest', 'w3act']
)
def w3act_backup():
    """
### Backup W3ACT DB to HDFS

This dumps the W3ACT database and uploads it to HDFS for safe-keeping and 
so the access services can download the lastest version.
    """

    # Shared operator definitions:
    cleanup = W3ACTDumpCleanupOperator()
    dump = W3ACTDumpOperator()

    # Make into a ZP:
    zip = DockerOperator(
        task_id='zip_csv',
        image=c.ukwa_task_image,
        command='zip -r /storage/{{ params.dump_name }}.zip /storage/{{ params.dump_name }}',
        do_xcom_push=False,
    )

    # Push up to W3ACT in the location used for access:
    upload_csv = DockerOperator(
        task_id='upload_csv_to_hdfs',
        image=c.ukwa_task_image,
        command='store -u ingest put --backup-and-replace /storage/{{ params.dump_name }}.zip /9_processing/w3act/{{ params.tag }}/{{ params.dump_name }}.zip',
        do_xcom_push=False,
    )

    # Also make a SQL dump
    pg_dump = DockerOperator(
        task_id='w3act_pg_dump',
        image=c.postgres_image,
        command='pg_dump -v -U w3act -h {{ params.host }} -p {{ params.port }} --format=c --file=/storage/{{ params.dump_name }}.sql w3act',
        environment={
            'PGPASSWORD': "{{ params.pw }}"
        },
        do_xcom_push=False,
    )

    # Push up to W3ACT in the location used for access:
    upload_sql = DockerOperator(
        task_id='upload_sql_to_hdfs',
        image=c.ukwa_task_image,
        command='store -u ingest put --backup-and-replace /storage/{{ params.dump_name }}.sql /2_backups/w3act/{{ params.tag }}/{{ params.dump_name }}.sql',
        do_xcom_push=False,
    )

    # CSV upload goes...
    cleanup >> dump >> zip >> upload_csv

    # SQL upload goes...
    cleanup >> pg_dump >> upload_sql

# Create the DAGs:
w3act_backup_dag = w3act_backup()
w3act_export_dag = w3act_export()