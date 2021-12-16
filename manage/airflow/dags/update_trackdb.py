"""
## update-trackdb.py

This file defines DAGs for listing HDFS paths and updating TrackDB.

To avoid code duplication, we [create the DAG dynamically](https://airflow.apache.org/docs/apache-airflow/stable/faq.html#how-can-i-create-dags-dynamically)
"""
import json
import os

from airflow.models import Variable, DAG, Connection
from airflow.utils.dates import days_ago
from airflow.operators.docker_operator import DockerOperator

from _common_ import Config

# Pick up shared configuration:
c = Config()

# These args will get passed on to each operator/task:
default_args = c.get_default_args()

# Connection to TrackDB to use:
trackdb_url = c.get_trackdb_url()

# Use a function to generate parameterised DAGs:
def generate_update_dag(path, hadoop_service, schedule_interval, args):
    dag_id = 'update_trackdb_%s%s' % (hadoop_service, path.replace('/','_'))
    with DAG(
        dag_id=dag_id,
        default_args=args, 
        schedule_interval=schedule_interval, 
        start_date=days_ago(1),
        max_active_runs=1,
        catchup=False,
        params= {
            'path': path,
            'lsr_txt': '/storage/hadoop_lsr_%s.txt' % dag_id,
            'lsr_jsonl': '/storage/hadoop_lsr_%s.jsonl' % dag_id,
            'trackdb_url': trackdb_url,
            'hadoop_service': hadoop_service
        },
        tags=['trackdb', 'manage', hadoop_service]
    ) as update_trackdb_dag:
        escaped_path = path.replace('/','\/')
        update_trackdb_dag.doc_md = \
f"""
### Update TrackDB with file information from HDFS

This recursively lists the `{path}` folder of HDFS on Hadoop Service `{hadoop_service}` and updates TrackDB with information about those files. 

**NOTE** The user that scans HDFS should _ONLY_ have _read-only_ access, but be able to see _EVERYTHING_.

Configuration:

* The Hadoop service being scanned is: `{hadoop_service}`
* The HDFS path to scan is: `{ update_trackdb_dag.params['path']}`
* Intermediate task output files will be stored on the host server under the `{c.storage_path}` folder, mounted as `/storage` in Docker containers. 
* The intermediate output files are:
    * Text format HDFS file listing: `{ update_trackdb_dag.params['lsr_txt'] }`
    * Converted JSONLines HDFS listing: `{ update_trackdb_dag.params['lsr_jsonl'] }`
* This task is configured to update the TrackDB at: `{ update_trackdb_dag.params['trackdb_url'] }`

How to check it's working:

* The TrackDB should have up-to-date results for the configured path and Hadoop service, visible via [this reverse-chronological query]({trackdb_url}/select?q=file_path_s:{escaped_path}* AND hdfs_service_id_s:{hadoop_service}&sort=timestamp_dt+desc).

Tool container versions:

 * Hadoop Task Image: `{c.hadoop_docker_image}`
 * UKWA Manage Task Image: `{c.ukwa_task_image}`

"""

        # List HDFS location using Hadoop lsr command.
        # This returns 255/-1 if there are permission-denied errors, so we use '; true' for now.
        if hadoop_service is 'h020':
            lsr = DockerOperator(
                task_id='list_hadoop_fs',
                image=c.hadoop_docker_image,
                entrypoint='/entrypoint-h020.sh', # < This overrides the setup and uses H020
                command='bash -c "hadoop fs -lsr {{ params.path }} > {{ params.lsr_txt }}; true"',
            )
        else:
            lsr = DockerOperator(
                task_id='list_hadoop_fs',
                image=c.hadoop_docker_image,
                command='bash -c "hadoop fs -lsr {{ params.path }} > {{ params.lsr_txt }}; true"',
                # Note that H3 automatically picks up the right config dir
            )

        lsr_to_jsonl = DockerOperator(
            task_id='convert_lsr_to_jsonl',
            image=c.ukwa_task_image,
            command='store {{ params.hadoop_service }} lsr-to-jsonl {{ params.lsr_txt }} {{ params.lsr_jsonl }}',
        )

        jsonl_to_trackdb = DockerOperator(
            task_id='jsonl_to_trackdb',
            image=c.ukwa_task_image,
            command='trackdb import -t {{ params.trackdb_url }} files {{ params.lsr_jsonl }}',
        )

        lsr >> lsr_to_jsonl >> jsonl_to_trackdb

        globals()[dag_id] = update_trackdb_dag

# Create DAGs for each path and schedule (Hadoop 0.20)
generate_update_dag('/heritrix/output', 'h020', '@hourly', default_args)
generate_update_dag('/', 'h020', '@daily', default_args)

# Create DAGs for each path and schedule (Hadoop 3)
generate_update_dag('/heritrix/output', 'h3', '@hourly', default_args)
generate_update_dag('/', 'h3', '@daily', default_args)
