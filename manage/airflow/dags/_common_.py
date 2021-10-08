"""
# _common_.py

This file holds values and variables that are shared across DAGs.
""" 
import os
from airflow.models import Variable, Connection
from docker.types import Mount

class Config():

    # Pick up definitions for the deployment context, and any secrets:
    deployment_context = os.environ['DEPLOYMENT_CONTEXT']
    storage_path = os.environ['STORAGE_PATH']
    hadoop_namenode_ip = os.environ['HADOOP_NAMENODE_IP']
    hadoop_jobtracker_ip = os.environ['HADOOP_JOBTRACKER_IP']

    # TODO Switch to using the connection form:  hadoop fs -fs hdfs://192.168.1.103:54310/ -lsr . 
    # Maybe not, as this can't be done for job tracking.
    # But storing the Hadoop details a Connections does make more sense either way.

    # Define the connection parameters, e.. you might want to change within a given deployment:
    wh_conn = Connection.get_connection_from_secrets("hadoop_020_webhdfs")
    webhdfs_access_url = f"http://{wh_conn.host}:{wh_conn.port}"
    webhdfs_access_user = wh_conn.login
    pg_conn = Connection.get_connection_from_secrets("metrics_push_gateway")
    push_gateway = f"{pg_conn.host}:{pg_conn.port}"

    # Define the common parameters for running Docker tasks:
    hadoop_docker_image = 'ukwa/docker-hadoop:hadoop-0.20'
    ukwa_task_image = 'ukwa/ukwa-manage:master'
    w3act_task_image = 'ukwa/python-w3act:master'
    postgres_image = 'postgres:9.6.2'

    # Get a copy of the default arguments:
    def get_default_args(self):
        return {
            # Shared configuration for all tasks:
            'owner': 'airflow',
            'retries': 3,
            # Shared configuration for all Docker tasks:
            'extra_hosts': {
                'namenode': self.hadoop_namenode_ip,
                'jobtracker': self.hadoop_jobtracker_ip
            },
            'mounts': [
                Mount( source=self.storage_path, target='/storage', type='bind' )
                 ],
            'email_on_failure': True,
            'email': [
                    Variable.get('alert_email_address')
                ],
            'auto_remove': False, # True is a bit aggressive and stops Airflow grabbing container logs.
            'do_xcom_push': False, # This is not currently working with DockerOperators so defaulting to off for now.
        }   
