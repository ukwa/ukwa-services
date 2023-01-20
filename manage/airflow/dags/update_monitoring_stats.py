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
from airflow.providers.ssh.operators.ssh import SSHOperator
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

# ----------------------------------------------------------------------------
# ----------------------------------------------------------------------------
# Define workflow DAGs:
# ----------------------------------------------------------------------------
# ----------------------------------------------------------------------------

with DAG(
    'update_monitoring_stats',
    description='Get system stats for monitoring purposes.',
    default_args=default_args, 
    schedule_interval='@hourly',
    start_date=days_ago(1),
    catchup=False,
    max_active_runs=1,
    params={
    },
    tags=['manage', 'monitor'],
) as dag1:
    dag1.doc_md = f"""
### Update Monitoring Stats

This task:

- Queries various source for service stats and metrics.
- Sends them to Prometheus.

Configuration:

* Updates [this Prometheus Push Gateway](http://{c.push_gateway}) _??? TBA ???_

How to check it's working:

* _TBA..._

Tool container versions:

 * Crawl Streams Image: `{c.stat_pusher_image}`

"""

    stat_push = DockerOperator(
        task_id='push_stats',
        image=c.stat_pusher_image,
        environment={
          "HTTPS_PROXY": EXTERNAL_WEB_PROXY,
          "ENVIRON": 'prod',
          'PUSH_GATEWAY': c.push_gateway,
        },
        # Runs with the default command. None set here.
    )
