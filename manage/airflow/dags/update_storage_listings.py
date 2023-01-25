"""
## update_monitoring_stats.py

Tasks that support service monitoring by gathering stats/metrics
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

# Need a proxy to talk to our websites on their public IPs/names:
EXTERNAL_WEB_PROXY = os.environ['EXTERNAL_WEB_PROXY']

# AWS S3
aws_s3 = Connection.get_connection_from_secrets('amazon_s3')

# ----------------------------------------------------------------------------
# ----------------------------------------------------------------------------
# Define workflow DAGs:
# ----------------------------------------------------------------------------
# ----------------------------------------------------------------------------

with DAG(
    'update_storage_listings',
    description='Generate file store lists for reporting purposes.',
    default_args=default_args, 
    schedule_interval='@daily',
    start_date=days_ago(1),
    catchup=False,
    max_active_runs=1,
    params={
        'aws_id': aws_s3.login,
        'aws_pw': aws_s3.password,
    },
    tags=['manage', 'report'],
) as dag1:
    dag1.doc_md = f"""
### Update Storage Listings

This task:

- Lists all the current files known to TrackDB.
- Lists all the web archive files on AWS S3.

Configuration:

* Uses AWS keys defined in an Airflow Connection called `amazon_s3`.

How to check it's working:

* Fresh JSONL listings in {c.storage_path}: `trackdb_list.jsonl`, `aws_s3_list.jsonl`
* The [holdings report](https://www.webarchive.org.uk/act/nbapps/voila/render/ukwa-holdings-summary-report.ipynb) is working and presenting that data.

Tool container versions:

 * UKWA Manage Task Image: `{c.ukwa_task_image}`


"""

    tdb = DockerOperator(
        task_id='export_trackdb_list',
        image=c.ukwa_task_image,
        # Using bash to redirect stdout:
        command="bash -c 'python -m lib.filedb.trackdb_lister > /storage/trackdb_list.jsonl'",
    )

    tdb = DockerOperator(
        task_id='export_aws_s3_list',
        image=c.ukwa_task_image,
        # Using bash to redirect stdout:
        command="bash -c 'python -m lib.filedb.aws_s3_lister > /storage/aws_s3_list.jsonl'",
        environment={
            'AWS_ACCESS_KEY_ID': "{{ params.aws_id }}",
            'AWS_SECRET_ACCESS_KEY': "{{ params.aws_pw }}",
            'HTTPS_PROXY': EXTERNAL_WEB_PROXY,
        },
    )

