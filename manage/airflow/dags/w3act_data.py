"""
## w3act_data.py

Tasks handling the W3ACT database and data exports.
"""
import json
import os

from airflow.decorators import dag, task
from airflow.utils.decorators import apply_defaults
from airflow.utils.dates import days_ago
from airflow.operators.bash import BashOperator
from airflow.operators.docker_operator import DockerOperator
from airflow.operators.python import get_current_context

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
                command = 'w3act get-csv -d /storage/{{ params.dump_name }} -H {{ params.host }} -P {{ params.port }} -p {{ params.pw }}',
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

    mkd = DockerOperator(
        task_id='make_dir',
        image=c.w3act_task_image,
        command='bash -c "mkdir -p /storage/data_exports && chmod a+rwx /storage/data_exports"',
        do_xcom_push=False,
    )

    aclj = DockerOperator(
        task_id='generate_allows_aclj',
        image=c.w3act_task_image,
        command='w3act gen-oa-acl -d /storage/{{ params.dump_name }} /storage/data_exports/allows.aclj.new',
        do_xcom_push=False,
    )

    acl = DockerOperator(
        task_id='generate_allows_acl',
        image=c.w3act_task_image,
        command='w3act gen-oa-acl -d /storage/{{ params.dump_name }} --format surts /storage/data_exports/allows.txt.new',
        do_xcom_push=False,
    )

    ann = DockerOperator(
        task_id='generate_solr_indexer_annotations',
        image=c.w3act_task_image,
        command='w3act gen-annotations -d /storage/{{ params.dump_name }} /storage/data_exports/annotations.json.new',
        do_xcom_push=False,
    )

    blk = DockerOperator(
        task_id='download_blocks_from_gitlab',
        image=c.ukwa_task_image,
        command='curl -o /storage/data_exports/blocks.aclj.new "http://git.wa.bl.uk/bl-services/wayback_excludes_update/-/raw/master/oukwa/acl/blocks.aclj"', 
        do_xcom_push=False,
    )

    mvs = DockerOperator(
        task_id='atomic_update',
        image=c.w3act_task_image,
        command="""bash -c "
mv -f /storage/data_exports/annotations.json.new /storage/data_exports/annotations.json &&
mv -f /storage/data_exports/allows.txt.new /storage/data_exports/allows.txt &&
mv -f /storage/data_exports/allows.aclj.new /storage/data_exports/allows.aclj &&
mv -f /storage/data_exports/blocks.aclj.new /storage/data_exports/blocks.aclj"
        """,
        do_xcom_push=False,
    )

    @task()
    def push_w3act_data_stats():
        from prometheus_client import CollectorRegistry, Gauge, push_to_gateway

        registry = CollectorRegistry()
        # Gather stats from files:
        g = Gauge('ukwa_record_count', 'Number of records', ['kind'], registry=registry)
        def make_line_gauge(g, filename, kind):
            lines = 0
            with open(filename) as f:
                for line in f:
                    lines += 1
            g.labels(kind=kind).set(lines)
        # Files to record:
        make_line_gauge(g, '/storage/data_exports/allows.txt', 'allows.txt')
        make_line_gauge(g, '/storage/data_exports/allows.aclj', 'allows.aclj')
        make_line_gauge(g, '/storage/data_exports/blocks.aclj', 'blocks.aclj')
        make_line_gauge(g, '/storage/data_exports/annotations.json', 'annotations.json')

        #context = get_current_context()
 
        # Successful task completion timestamp:
        g = Gauge('ukwa_task_workflow_complete', 'Last time this job (workflow) successfully finished', registry=registry)
        g.set_to_current_time()
        # And push:
        push_to_gateway(c.metrics_push_gateway, job='w3act_export', registry=registry)

    stat = push_w3act_data_stats()

    # Define workflow dependencies:
    cleanup >> dump >> mkd >> [ acl, aclj, ann, blk] >> mvs >> stat

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


# ----------------------------------------------------------------------------
# Run W3ACT QA checks
# ----------------------------------------------------------------------------
@dag(
    default_args=default_args, 
    schedule_interval='0 8 * * *', 
    start_date=days_ago(1),
    catchup=False,
    params={
        'host': c.access_w3act_host,
        'port': c.access_w3act_port,
        'pw': c.w3act_password,
        'dump_name': 'w3act_qa_dump',
        'tag': c.deployment_context.lower()
    },
    tags=['ingest', 'w3act']
)
def w3act_qa_checks():
    """
### W3ACT data QA checks

This runs some QA checks on the database and sends out reports via email as appropriate.
    """

    # Shared operator definitions:
    cleanup = W3ACTDumpCleanupOperator()
    dump = W3ACTDumpOperator()

    to_json =  DockerOperator(
        task_id='convert_to_json',
        image=c.w3act_task_image,
        command='w3act -d /storage/{{ params.dump_name }} csv-to-json',
        do_xcom_push=False,
    )

    qa_full = DockerOperator(
        task_id='run_full_report',
        image=c.w3act_task_image,
        command='w3act-qa-check -m "Andrew.Jackson@bl.uk" -f -W /storage/{{ params.dump_name }}.json',
        do_xcom_push=False,
    ) 

    qa_short = DockerOperator(
        task_id='run_short_report',
        image=c.w3act_task_image,
        command='w3act-qa-check -m "Andrew.Jackson@bl.uk" -W /storage/{{ params.dump_name }}.json',
        do_xcom_push=False,
    ) 

    cleanup >> dump >> to_json >> qa_full >> qa_short


# Create the DAGs:
w3act_backup_dag = w3act_backup()
w3act_export_dag = w3act_export()
w3act_qa_checks_dag = w3act_qa_checks()