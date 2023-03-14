"""
## update_data_sources.py

Tasks handling pulling data from other sources
"""
import json
import os
import datetime as dt

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

# SSH connection to a server that can download external data and push it to HDFS:
EXT_DATA_SSH_CONN_ID = 'external_data_ingest_server'
ext_data_server = Connection.get_connection_from_secrets(EXT_DATA_SSH_CONN_ID)
nominet_scp = Connection.get_connection_from_secrets("nominet_scp")


# ----------------------------------------------------------------------------
# ----------------------------------------------------------------------------
# Define workflow DAGs:
# ----------------------------------------------------------------------------
# ----------------------------------------------------------------------------

with DAG(
    'update_nominet_data',
    description='Update our copy of domain data from Nominet.',
    default_args=default_args, 
    schedule_interval='@monthly',
    # Needs a proper start date in order to schedule properly:
    start_date=dt.datetime(2023, 1, 1),
    catchup=False,
    max_active_runs=1,
    params={
        'NOM_HOST': nominet_scp.host,
        'NOM_USER': nominet_scp.login,
        'NOM_PWD': nominet_scp.password,
        'TASK_CONTAINER_IMAGE': c.ukwa_task_image,
    },
    tags=['ingest', 'sources'],
) as dag1:
    dag1.doc_md = f"""
### Update domain data from Nominet

As we are a member of Nominet, we are permitted to download lists of registered domains. This can 
be used to help seed the domain crawl.

This task:

- Logs into the server `{ext_data_server.host}`
- Runs a Dockerized script (`{dag1.params['TASK_CONTAINER_IMAGE']}`) that talks to Nominet at `{nominet_scp.host}`.
- Checks for files in recent days, downloads the relevant file and uploads to Hadoop3.

Configuration:

* TBC Updates [this Prometheus Push Gateway](http://{c.push_gateway}) _??? TBA ???_

How to check it's working:

* Recent monthly files showing up at <http://h3nn.api.wa.bl.uk/explorer.html#/1_data/nominet>

Tool container versions:

 * UKWA Manage task image: `{c.ukwa_task_image}`

"""

    update_nom_data = SSHOperator(
        task_id='update_nominet_data',
        ssh_conn_id=EXT_DATA_SSH_CONN_ID,
        # Can't use environment without modifying SSH AcceptEnv setup.
        command="docker run -e NOM_HOST={{ params.NOM_HOST }} -e NOM_USER={{ params.NOM_USER }} -e NOM_PWD='{{ params.NOM_PWD }}' --add-host h3httpfs.api.wa.bl.uk:192.168.45.40 {{ params.TASK_CONTAINER_IMAGE }} python -m lib.store.nominet"
    )


