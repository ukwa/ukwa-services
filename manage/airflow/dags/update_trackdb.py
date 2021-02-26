"""
## update-trackdb.py

This file defines DAGs for listing HDFS paths and updating TrackDB.

To avoid code duplication, we [create the DAG dynamically](https://airflow.apache.org/docs/apache-airflow/stable/faq.html#how-can-i-create-dags-dynamically)
"""
import json
import os

from airflow.models import Variable, DAG
from airflow.decorators import dag, task
from airflow.utils.dates import days_ago
from airflow.operators.docker_operator import DockerOperator

# Define the parameters that can vary between deployment contexts:
trackdb_url = Variable.get('trackdb_url')
hadoop_namenode_ip = Variable.get('hadoop_namenode_ip')
hadoop_jobtracker_ip = Variable.get('hadoop_jobtracker_ip')
webhdfs_url = Variable.get('webhdfs_url', 'http://webhdfs.api.wa.bl.uk/')
webhdfs_user = Variable.get('webhdfs_user', 'access')
storage_path = Variable.get('storage_path')

# Define the common parameters for running Docker tasks:
volumes = ['%s:/storage' % storage_path ]
hadoop_docker_image = 'ukwa/docker-hadoop:hadoop-0.20'
ukwa_task_image = 'ukwa/ukwa-manage:latest'
# This is how the Hadoop jobs know where to run:
extra_hosts = {
    'namenode': hadoop_namenode_ip,
    'jobtracker': hadoop_jobtracker_ip
}

# These args will get passed on to each operator
# You can override them on a per-task basis during operator initialization
default_args = {
    'owner': 'airflow',
}

# Use a function to generate parameterised DAGs:
def generate_update_dag(path, schedule_interval):
    dag_id = 'update_trackdb%s' % path.replace('/','_')
    with DAG(
        dag_id=dag_id,
        default_args=default_args, 
        schedule_interval=schedule_interval, 
        start_date=days_ago(1),
        catchup=False,
        tags=['trackdb', 'manage']
    ) as update_trackdb_dag:
        update_trackdb_dag.doc_md = \
"""
### Update TrackDB with WARCs from HDFS

This lists %s and updates TrackDB. 

""" % path

        #
        hadoop_lsr_path = path
        hadoop_lsr_txt = '/storage/hadoop_lsr_%s.txt' % dag_id
        hadoop_lsr_jsonl = '/storage/hadoop_lsr_%s.jsonl' % dag_id

        # List HDFS location using Hadoop lsr command.
        # This returns 255/-1 if there are permission-denied errors, so we use '; true' for now.
        # TODO User that scans HDFS should have (ideally read-only) access to _EVERYTHING_.
        lsr = DockerOperator(
            task_id='list_hadoop_fs',
            image=hadoop_docker_image,
            command='bash -c "hadoop fs -lsr %s > %s; true"' % (hadoop_lsr_path, hadoop_lsr_txt),
            do_xcom_push=False,
            extra_hosts=extra_hosts,
            volumes=volumes
        )

        lsr_to_jsonl = DockerOperator(
            task_id='convert_lsr_to_jsonl',
            image=ukwa_task_image,
            command='store lsr-to-jsonl %s %s' % (hadoop_lsr_txt, hadoop_lsr_jsonl),
            do_xcom_push=False,
            extra_hosts=extra_hosts,
            volumes=volumes
        )

        jsonl_to_trackdb = DockerOperator(
            task_id='jsonl_to_trackdb',
            image=ukwa_task_image,
            command='trackdb import -v -t %s files %s ' % (trackdb_url, hadoop_lsr_jsonl),
            do_xcom_push=False,
            extra_hosts=extra_hosts,
            volumes=volumes
        )

        lsr >> lsr_to_jsonl >> jsonl_to_trackdb
        
        globals()[dag_id] = update_trackdb_dag

# Create DAGs for each path and schedule:
generate_update_dag('/heritrix/output', '@hourly')
generate_update_dag('/', '@daily')
