"""
## launch_crawls.py

Tasks handling the launching of crawls, using the data from the w3act_export
"""
import json
import os

from airflow.decorators import task
from airflow.utils.decorators import apply_defaults
from airflow.utils.dates import days_ago
from airflow.operators.bash import BashOperator
from airflow.providers.ssh.operators.ssh import SSHOperator
from airflow.operators.docker_operator import DockerOperator
from airflow.operators.python import get_current_context
from airflow.models import Variable, Connection, DAG

from _common_ import Config

# Pick up shared configuration:
c = Config()

# These args will get passed on to each operator/task:
default_args = c.get_default_args()

# Which Crawler Kafka service to talk to:
fc_crawler_kafka = Connection.get_connection_from_secrets("fc_crawler_kafka")


# ----------------------------------------------------------------------------
# ----------------------------------------------------------------------------
# Define workflow DAGs:
# ----------------------------------------------------------------------------
# ----------------------------------------------------------------------------

with DAG(
    'launch_crawls',
    description='Launch crawls based on data from W3ACT exports.',
    default_args=default_args, 
    schedule_interval='@hourly',
    start_date=days_ago(1),
    catchup=False,
    max_active_runs=1,
    params={
        'storage_path': c.storage_path,
        'fc_crawler_kafka': f'{fc_crawler_kafka.host}:{fc_crawler_kafka.port}'
    },
    tags=['ingest', 'crawls'],
) as dag1:
    dag1.doc_md = f"""
### Launch Crawls

This task:

- Reads crawl feeds and block lists (`crawl_feed_bypm.jsonl`, `crawl_feed_npld.jsonl`, `never_crawl.surts`)
- Talks to the FC Crawler Kafka service at: `{dag1.params['fc_crawler_kafka']}` 
- Reads the `npld` feed and launches URLs for the current hour to the `fc.tocrawl.npld` topic.
- Reads the `bypm` feed and launches URLs for the current hour to the `fc.tocrawl.bypm` topic.

Configuration:

* Reads input files from `/storage/data_exports` which is held under `{c.storage_path}` on the host machine.
* Updates [this Prometheus Push Gateway](http://{c.push_gateway}) _??? TBA ???_

How to check it's working:

* _TBA..._

Tool container versions:

 * Crawl Streams Image: `{c.crawlstreams_image}`

"""

    # Launch crawls now the files are updated:
    launch_bypm = DockerOperator(
        task_id='launch_bypm_fc_crawl_urls',
        image=c.crawlstreams_image,
        command='launcher -k {{ params.fc_crawler_kafka }} -L {{ next_execution_date }} fc.tocrawl.bypm /storage/data_exports/crawl_feed_bypm.jsonl',
    )

    launch_npld = DockerOperator(
        task_id='launch_npld_fc_crawl_urls',
        image=c.crawlstreams_image,
        command='launcher -k {{ params.fc_crawler_kafka }} -L {{ next_execution_date }} fc.tocrawl.npld /storage/data_exports/crawl_feed_npld.jsonl',
    )

