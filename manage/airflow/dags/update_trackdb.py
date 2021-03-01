"""
## update-trackdb.py

This file defines DAGs for listing HDFS paths and updating TrackDB.

To avoid code duplication, we [create the DAG dynamically](https://airflow.apache.org/docs/apache-airflow/stable/faq.html#how-can-i-create-dags-dynamically)
"""
import json
import os

from airflow.models import Variable, DAG
from airflow.utils.dates import days_ago
from airflow.operators.docker_operator import DockerOperator

from _common_ import Config

# Pick up shared configuration:
c = Config()

# These args will get passed on to each operator/task:
default_args = c.get_default_args_for_access()

# Use a function to generate parameterised DAGs:
def generate_update_dag(path, schedule_interval):
    dag_id = 'update_trackdb%s' % path.replace('/','_')
    with DAG(
        dag_id=dag_id,
        default_args=default_args, 
        schedule_interval=schedule_interval, 
        start_date=days_ago(1),
        catchup=False,
        params= {
            'path': path,
            'lsr_txt': '/storage/hadoop_lsr_%s.txt' % dag_id,
            'lsr_jsonl': '/storage/hadoop_lsr_%s.jsonl' % dag_id,
            'trackdb_url': c.access_trackdb_url,
        },
        tags=['trackdb', 'manage']
    ) as update_trackdb_dag:
        update_trackdb_dag.doc_md = \
"""
### Update TrackDB with file information from HDFS

This recursively lists the `%s` folder of HDFS and updates TrackDB with information about those files. 

""" % path

        # List HDFS location using Hadoop lsr command.
        # This returns 255/-1 if there are permission-denied errors, so we use '; true' for now.
        # TODO User that scans HDFS should have _read-only_ access to _EVERYTHING_.
        lsr = DockerOperator(
            task_id='list_hadoop_fs',
            image=c.hadoop_docker_image,
            command='bash -c "hadoop fs -lsr {{ params.path }} > {{ params.lsr_txt }}; true"',
            do_xcom_push=False,
        )

        lsr_to_jsonl = DockerOperator(
            task_id='convert_lsr_to_jsonl',
            image=c.ukwa_task_image,
            command='store lsr-to-jsonl {{ params.lsr_txt }} {{ params.lsr_jsonl }}',
            do_xcom_push=False,
        )

        jsonl_to_trackdb = DockerOperator(
            task_id='jsonl_to_trackdb',
            image=c.ukwa_task_image,
            command='trackdb import -v -t {{ params.trackdb_url }} files {{ params.lsr_jsonl }}',
            do_xcom_push=False,
        )

        lsr >> lsr_to_jsonl >> jsonl_to_trackdb

        globals()[dag_id] = update_trackdb_dag

# Create DAGs for each path and schedule:
generate_update_dag('/heritrix/output', '@hourly')
generate_update_dag('/', '@daily')
