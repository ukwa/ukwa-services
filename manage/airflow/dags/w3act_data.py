"""
## w3act_data.py

Tasks handling the W3ACT database and data exports.
"""
import json
import os

from airflow.decorators import task
from airflow.utils.decorators import apply_defaults
from airflow.utils.dates import days_ago
from airflow.operators.bash import BashOperator
from airflow.operators.docker_operator import DockerOperator
from airflow.operators.python import get_current_context
from airflow.models import Variable, Connection, DAG

from _common_ import Config

# Pick up shared configuration:
c = Config()

# These args will get passed on to each operator/task:
default_args = c.get_default_args()

# Connection to W3ACT PostgreSQL DB to use:
access_w3act = Connection.get_connection_from_secrets("access_w3act")

# Which Collections Solr to update:
collections_solr = Connection.get_connection_from_secrets("access_collections_solr")

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
                **kwargs)

class W3ACTDumpOperator(DockerOperator):
        @apply_defaults
        def __init__(self, **kwargs) -> None:
            super().__init__(
                task_id = 'dump_w3act',
                image = c.w3act_task_image,
                command = 'w3act get-csv -d /storage/{{ params.dump_name }} -H {{ params.host }} -P {{ params.port }} -p {{ params.pw }}',
                **kwargs)


# ----------------------------------------------------------------------------
# ----------------------------------------------------------------------------
# Define workflow DAGs:
# ----------------------------------------------------------------------------
# ----------------------------------------------------------------------------

# ----------------------------------------------------------------------------
# Generate data exports:
# ----------------------------------------------------------------------------
with DAG(
    'w3act_export',
    description='Update operational data from what\'s in W3ACT.',
    default_args=default_args, 
    schedule_interval='@hourly',
    start_date=days_ago(1),
    catchup=False,
    max_active_runs=1,
    params={
        'host': access_w3act.host,
        'port': access_w3act.port,
        'pw': access_w3act.password,
        'dump_name': 'w3act_export',
        'storage_path': c.storage_path,
        'collections_solr': collections_solr.get_uri(),
    },
    tags=['access', 'w3act'],
) as dag1:
    dag1.doc_md = f"""
### Export data from W3ACT

This dumps the W3ACT database and extracts useful data from it. This includes:

- Access lists for Wayback:
    - `allows.aclj` derived from W3ACT,
    - `blocks.aclj` downloaded from GitLab.
- [Solr Collections]({dag1.params['collections_solr']}/select?q=*:*&wt=json&indent=on) for the website (Topics & Themes)
- Metadata used for full-text indexing (`allows.txt`, `annotations.json`)
- Crawl feeds and block lists (`crawl_feed_bypm.jsonl`, `crawl_feed_npld.jsonl`, `never_crawl.surts`)

These are necessary pre-requisites for access processes, like indexing and playback.

Configuration:

* Exports data from W3ACT DB at `{dag1.params['host']}:{dag1.params['port']}`.
* Outputs temporary files to `/storage/` which is held under `{c.storage_path}` on the host machine.
* Uses dump name `{dag1.params['dump_name']}` to distinguish this data dump from others.
* Outputs results to `/storage/data_exports` which is held under `{c.storage_path}` on the host machine.
* Updates the Topics & Themes Solr collection at `{dag1.params['collections_solr']}`.
* Updates [this Prometheus Push Gateway](http://{c.push_gateway}) with `w3act_export` line count metrics.

How to check it's working:

* All export files indicated above are present and up-to-date in the `{c.storage_path}` folder on the host machine. 
* The [`ukwa_record_count` metrics are up to date in Prometheus](http://monitor-prometheus.api.wa.bl.uk/graph?g0.expr=ukwa_record_count&g0.tab=0&g0.stacked=0&g0.show_exemplars=0&g0.range_input=2d).


"""

    # Shared operator definitions:
    cleanup = W3ACTDumpCleanupOperator()
    dump = W3ACTDumpOperator()

    aclj = DockerOperator(
        task_id='generate_allows_aclj',
        image=c.w3act_task_image,
        command='w3act gen-oa-acl -d /storage/{{ params.dump_name }} /storage/data_exports/allows.aclj.new',
    )

    acl = DockerOperator(
        task_id='generate_allows_acl',
        image=c.w3act_task_image,
        command='w3act gen-oa-acl -d /storage/{{ params.dump_name }} --format surts /storage/data_exports/allows.txt.new',
    )

    ann = DockerOperator(
        task_id='generate_solr_indexer_annotations',
        image=c.w3act_task_image,
        command='w3act gen-annotations -d /storage/{{ params.dump_name }} /storage/data_exports/annotations.json.new',
    )

    cfld = DockerOperator(
        task_id='generate_npld_crawl_feed',
        image=c.w3act_task_image,
        command='w3act crawl-feed -d /storage/{{ params.dump_name }} -F jsonl -f all -t npld --include-hidden /storage/data_exports/crawl_feed_npld.jsonl.new',
    )

    cfby = DockerOperator(
        task_id='generate_by_permission_crawl_feed',
        image=c.w3act_task_image,
        command='w3act crawl-feed -d /storage/{{ params.dump_name }} -F jsonl -f all -t bypm --include-hidden /storage/data_exports/crawl_feed_bypm.jsonl.new',
    )

    never = DockerOperator(
        task_id='generate_never_crawl_list',
        image=c.w3act_task_image,
        command='w3act list-urls -d /storage/{{ params.dump_name }} -f nevercrawl --include-hidden --include-expired -F surts /storage/data_exports/never_crawl.surts.new',
    )

    blk = DockerOperator(
        task_id='download_blocks_from_gitlab',
        image=c.ukwa_task_image,
        command='curl -o /storage/data_exports/blocks.aclj.new "http://git.wa.bl.uk/bl-services/wayback_excludes_update/-/raw/master/oukwa/acl/blocks.aclj"', 
    )

    socol = DockerOperator(
        task_id='update_collections_solr',
        image=c.w3act_task_image,
        command='w3act update-collections-solr -d /storage/{{ params.dump_name }} {{ params.collections_solr }}',
    )

    mvs = DockerOperator(
        task_id='atomic_update',
        image=c.w3act_task_image,
        command="""bash -c "
mv -f /storage/data_exports/annotations.json.new /storage/data_exports/annotations.json &&
mv -f /storage/data_exports/allows.txt.new /storage/data_exports/allows.txt &&
mv -f /storage/data_exports/allows.aclj.new /storage/data_exports/allows.aclj &&
mv -f /storage/data_exports/blocks.aclj.new /storage/data_exports/blocks.aclj &&
mv -f /storage/data_exports/never_crawl.surts.new /storage/data_exports/never_crawl.surts &&
mv -f /storage/data_exports/crawl_feed_npld.jsonl.new /storage/data_exports/crawl_feed_npld.jsonl &&
mv -f /storage/data_exports/crawl_feed_bypm.jsonl.new /storage/data_exports/crawl_feed_bypm.jsonl"
        """,
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
        make_line_gauge(g, '/storage/data_exports/never_crawl.surts', 'never_crawl.surts')
        make_line_gauge(g, '/storage/data_exports/crawl_feed_npld.jsonl', 'crawl_feed_npld.jsonl')
        make_line_gauge(g, '/storage/data_exports/crawl_feed_bypm.jsonl', 'crawl_feed_npld.jsonl')

        #context = get_current_context()
 
        # Successful task completion timestamp:
        g = Gauge('ukwa_task_workflow_complete', 'Last time this job (workflow) successfully finished', registry=registry)
        g.set_to_current_time()
        # And push:
        push_to_gateway(c.push_gateway, job='w3act_export', registry=registry)

    stat = push_w3act_data_stats()

    # Define workflow dependencies:
    cleanup >> dump >> [ acl, aclj, ann, blk, cfld, cfby, never ] >> mvs >> socol >> stat


# ----------------------------------------------------------------------------
# Backup to HDFS
# ----------------------------------------------------------------------------
with DAG(
    'w3act_backup',
    description='Backup W3ACT DB to HDFS.',
    default_args=default_args, 
    schedule_interval='0 0,12 * * *', # Twice a day
    start_date=days_ago(1),
    catchup=False,
    max_active_runs=1,
    params={
        'host': access_w3act.host,
        'port': access_w3act.port,
        'pw': access_w3act.password,
        'dump_name': 'w3act_dump',
        'hdfs_path': f"/2_backups/w3act/{c.deployment_context.lower()}"
    },
    tags=['ingest', 'w3act']
) as dag2:
    dag2.doc_md = f"""
### Backup W3ACT DB to HDFS

This dumps the W3ACT database and uploads it to HDFS for safe-keeping and 
so the access services can download the lastest version.

Configuration:

* Exports data from W3ACT DB at `{dag2.params['host']}:{dag2.params['port']}`.
* Outputs temporary files to `/storage/` which is held under `{c.storage_path}` on the host machine.
* Uses dump name `{dag2.params['dump_name']}` to distinguish this data dump from others.
* Backup are placed on HDFS at:
    * `{ dag2.params['hdfs_path'] }/w3act-db-csv.zip`
    * `{ dag2.params['hdfs_path'] }/w3act_dump.sql`
* Older backups are moved aside and given dated file suffixes corresponding to the date they were renamed.

How to check it's working:

* Look in [the `{ dag2.params['hdfs_path'] }` folder](http://hdfs.api.wa.bl.uk/webhdfs/v1{ dag2.params['hdfs_path'] }?op=LISTSTATUS&user.name=access)
* Check file sizes, names and dates are as expected.

    """

    # Shared operator definitions:
    cleanup = W3ACTDumpCleanupOperator()
    dump = W3ACTDumpOperator()

    # Make into a ZP:
    zip = DockerOperator(
        task_id='zip_csv',
        image=c.ukwa_task_image,
        command='zip -r /storage/{{ params.dump_name }}.zip /storage/{{ params.dump_name }}',
    )

    # Push up to W3ACT in the location used for access:
    upload_csv = DockerOperator(
        task_id='upload_csv_to_hdfs',
        image=c.ukwa_task_image,
        command='store -u ingest put --backup-and-replace /storage/{{ params.dump_name }}.zip {{ params.hdfs_path }}/w3act-db-csv.zip',
    )

    # Also make a SQL dump
    pg_dump = DockerOperator(
        task_id='w3act_pg_dump',
        image=c.postgres_image,
        command='pg_dump -v -U w3act -h {{ params.host }} -p {{ params.port }} --format=c --file=/storage/{{ params.dump_name }}.sql w3act',
        environment={
            'PGPASSWORD': "{{ params.pw }}"
        },
    )

    # Push up to W3ACT in the location used for access:
    upload_sql = DockerOperator(
        task_id='upload_sql_to_hdfs',
        image=c.ukwa_task_image,
        command='store -u ingest put --backup-and-replace /storage/{{ params.dump_name }}.sql {{ params.hdfs_path }}/w3act_dump.sql',
    )

    # CSV upload goes...
    cleanup >> dump >> zip >> upload_csv

    # SQL upload goes...
    cleanup >> pg_dump >> upload_sql


# ----------------------------------------------------------------------------
# Run W3ACT QA checks
# ----------------------------------------------------------------------------
with DAG(
    'w3act_qa_checks',
    description='Run some QA checks over W3ACT.',
    default_args=default_args, 
    schedule_interval='0 8 * * *', 
    start_date=days_ago(1),
    catchup=False,
    max_active_runs=1,
    params={
        'host': access_w3act.host,
        'port': access_w3act.port,
        'pw': access_w3act.password,
        'dump_name': 'w3act_qa_dump',
        'full_report_email': 'Andrew.Jackson@bl.uk',
        'summary_report_email': 'Andrew.Jackson@bl.uk',
    },
    tags=['ingest', 'w3act']
) as dag3:
    dag3.doc_md = f"""
### W3ACT data QA checks

This runs some QA checks on the database and sends out reports via email as appropriate.

Configuration:

* Exports data from W3ACT DB at `{dag3.params['host']}:{dag3.params['port']}`.
* Outputs temporary files to `/storage/` which is held under `{c.storage_path}` on the host machine.
* Uses dump name `{dag3.params['dump_name']}` to distinguish this data dump from others.
* Sends full reports to `{dag3.params['full_report_email']}`.
* Sends summary reports to `{dag3.params['summary_report_email']}`.

    """

    # Shared operator definitions:
    cleanup = W3ACTDumpCleanupOperator()
    dump = W3ACTDumpOperator()

    to_json =  DockerOperator(
        task_id='convert_to_json',
        image=c.w3act_task_image,
        command='w3act csv-to-json -d /storage/{{ params.dump_name }}',
    )

    qa_full = DockerOperator(
        task_id='run_full_report',
        image=c.w3act_task_image,
        command='w3act-qa-check -m "{{ params.full_report_email }}" -f -W /storage/{{ params.dump_name }}.json',
    ) 

    qa_short = DockerOperator(
        task_id='run_short_report',
        image=c.w3act_task_image,
        command='w3act-qa-check -m "{{ params.summary_report_email }}" -W /storage/{{ params.dump_name }}.json',
    ) 

    cleanup >> dump >> to_json >> qa_full >> qa_short
