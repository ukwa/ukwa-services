"""
## w3act_to_hdfs.py
"""
import json
import os

from airflow.decorators import dag, task
from airflow.utils.dates import days_ago
from airflow.operators.bash import BashOperator
from airflow.operators.docker_operator import DockerOperator

from _common_ import Config

# Pick up shared configuration:
c = Config()

# These args will get passed on to each operator/task:
default_args = c.get_default_args_for_access()

@dag(
    default_args=default_args, 
    schedule_interval='@hourly',
    start_date=days_ago(1),
    catchup=False,
    params={
        'host': c.access_w3act_host,
        'port': c.access_w3act_port,
        'pw': c.w3act_password,
        'sql_file': os.path.join(c.storage_path, 'w3act_dump.sql'),
        'db_dir': os.path.join(c.storage_path, 'w3act-db-csv'),
        'tag': c.deployment_context.lower()
    },
    tags=['ingest', 'w3act']
)
def w3act_backup_to_hdfs():
    """
### Backup W3ACT DB to HDFS

This dumps the W3ACT database and uploads it to HDFS for safe-keeping and 
so the access services can download the lastest version.
    """

    cleanup = BashOperator(
        task_id='cleanup_db_folder',
        bash_command='rm -fr {{ params.db_dir }} {{ params.sql_file }}',
    )

    dump = DockerOperator(
        task_id='dump_w3act',
        image=c.w3act_task_image,
        command='w3act -d /storage/w3act-db-csv get-csv -H {{ params.host }} -P {{ params.port }} -p {{ params.pw }}',
        do_xcom_push=False,
    )
    
    # Using a container as there is no ZIP command in the current Airflow image:
    zip = DockerOperator(
        task_id='zip_db_folder',
        image=c.ukwa_task_image,
        command='zip -r /storage/w3act-db-csv.zip /storage/w3act-db-csv',
        do_xcom_push=False,
    )
    
    # Push up to W3ACT in the location used for access:
    upload_csv = DockerOperator(
        task_id='upload_csv_to_hdfs',
        image=c.ukwa_task_image,
        command='store -u ingest put --backup-and-replace /storage/w3act-db-csv.zip /9_processing/w3act/{{ params.tag }}/w3act-db-csv.zip',
        do_xcom_push=False,
    )

    # Also make a SQL dump
    pg_dump = DockerOperator(
        task_id='w3act_pg_dump',
        image=c.postgres_image,
        command='pg_dump -v -U w3act -h {{ params.host }} -p {{ params.port }} --format=c --file=/storage/w3act_dump.sql w3act',
        environment={
            'PGPASSWORD': "{{ params.pw }}"
        },
        do_xcom_push=False,
    )

    # Push up to W3ACT in the location used for access:
    upload_sql = DockerOperator(
        task_id='upload_sql_to_hdfs',
        image=c.ukwa_task_image,
        command='store -u ingest put --backup-and-replace /storage/w3act_dump.sql /2_backups/w3act/{{ params.tag }}/w3act_dump.sql',
        do_xcom_push=False,
    )

    # CSV upload goes...
    cleanup >> dump >> zip >> upload_csv

    # SQL upload goes...
    cleanup >> pg_dump >> upload_sql

# Create the DAG:
w3act_to_hdfs_dag = w3act_backup_to_hdfs()