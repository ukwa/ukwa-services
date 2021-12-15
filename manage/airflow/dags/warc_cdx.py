"""
## warc_cdx.py

Tasks handling CDX indexing.
"""
import json
import os
from urllib.parse import urlparse

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

# Connection to TrackDB to use:
trackdb_url = c.get_trackdb_url()

# CDX connection:
cdx_url = c.get_access_cdx_url()
cdx_parsed = urlparse(cdx_url)
cdx_host = cdx_parsed.netloc # include port
cdx_col = cdx_parsed.path[1:] # Strip leading slash

hadoop_service = 'h020'

with DAG(
    f"access_{hadoop_service}_warc_cdx_index",
    description='Index Hadoop 0.20 WARCs into OutbackCDX',
    default_args=default_args, 
    schedule_interval='@hourly', 
    start_date=days_ago(1),
    catchup=False,
    max_active_runs=1,
    params={
        'hadoop_service' : hadoop_service,
   	    'trackdb_url' : trackdb_url,
	    'cdx_service' : f"http://{cdx_host}",
	    'cdx_collection': cdx_col
    },
    tags=['access', 'index', 'cdx']
) as dag:
    dag.doc_md = f"""
### Index WARCs into CDX

This runs Hadoop `{dag.params['hadoop_service']}` jobs to index WARC content into the OutbackCDX service.

Configuration:

* Reads and updates TrackDB at `{dag.params['trackdb_url']}`
* Processes WARCS on Hadoop `{dag.params['hadoop_service']}`
* Updates CDX collection `{dag.params['cdx_collection']}` on CDX service `{dag.params['cdx_service']}`
* The push gateway is configured to be `{c.push_gateway}`.


How to check it's working, you can:

* Check for various Prometheus metrics via the Push Gateway:
    * For Webrecorder WARCs:
        * `ukwa_task_event_timestamp{{job="cdx-index-{dag.params['hadoop_service']}-webrecorder", status="success"}}`
        * `ukwa_task_total_sent_record_count{{job="cdx-index-{dag.params['hadoop_service']}-webrecorder", status="success"}}`
    * For Frequent Crawl WARCs:
        * `ukwa_task_event_timestamp{{job="cdx-index-{dag.params['hadoop_service']}-frequent", status="success"}}`
        * `ukwa_task_total_sent_record_count{{job="cdx-index-{dag.params['hadoop_service']}-frequent", status="success"}}`
    * For Domain Crawl WARCs:
        * `ukwa_task_event_timestamp{{job="cdx-index-{dag.params['hadoop_service']}-domain", status="success"}}`
        * `ukwa_task_total_sent_record_count{{job="cdx-index-{dag.params['hadoop_service']}-domain", status="success"}}`
* The number of WARCs marked as indexed in TrackTB should increase:
    * [For Webrecorder WARCs]({dag.params['trackdb_url']}/select?q=cdx_index_ss:{dag.params['cdx_collection']} AND stream_s:webrecorder)
    * [For Frequent WARCs]({dag.params['trackdb_url']}/select?q=cdx_index_ss:{dag.params['cdx_collection']} AND stream_s:frequent)
    * [For Domain WARCs]({dag.params['trackdb_url']}/select?q=cdx_index_ss:{dag.params['cdx_collection']} AND stream_s:domain)

Tool container versions:

 * UKWA Manage Task Image: `{c.ukwa_task_image}`

    """

    cdx_h020_wr = DockerOperator(
        task_id='index_h020_webrecorder_cdx',
        image=c.ukwa_task_image,
	# Add Hadoop 0.20 settings:
	entrypoint='/entrypoint-h020.sh',
	environment= {
	    'MRJOB_CONF': '/etc/mrjob.conf',
        'PUSH_GATEWAY': c.push_gateway,
	},
        command='windex cdx-index -v -t {{ params.trackdb_url }} -H {{ params.hadoop_service }} -S webrecorder -c {{ params.cdx_service }} -C {{ params.cdx_collection }} -B 2',
    ) 

    cdx_h020_fc = DockerOperator(
        task_id='index_h020_frequent_cdx',
        image=c.ukwa_task_image,
	# Add Hadoop 0.20 settings:
	entrypoint='/entrypoint-h020.sh',
	environment= {
	    'MRJOB_CONF': '/etc/mrjob.conf',
        'PUSH_GATEWAY': c.push_gateway,
	},
        command='windex cdx-index -v -t {{ params.trackdb_url }} -H {{ params.hadoop_service }} -S frequent -c {{ params.cdx_service }} -C {{ params.cdx_collection }} -B 2',
    ) 

    cdx_h020_dc = DockerOperator(
        task_id='index_h020_domain_cdx',
        image=c.ukwa_task_image,
	# Add Hadoop 0.20 settings:
	entrypoint='/entrypoint-h020.sh',
	environment= {
	    'MRJOB_CONF': '/etc/mrjob.conf',
        'PUSH_GATEWAY': c.push_gateway,
	},
        command='windex cdx-index -v -t {{ params.trackdb_url }} -H {{ params.hadoop_service }} -S domain -c {{ params.cdx_service }} -C {{ params.cdx_collection }} -B 2',
    ) 

    cdx_h020_wr >> cdx_h020_fc >> cdx_h020_dc
