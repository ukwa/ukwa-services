"""
# _common_.py

This file holds values and variables that are shared across DAGs.
""" 
import os
from airflow.models import Variable, Connection

class Config():

    # Pick up definitions for the deployment context, and any secrets:
    deployment_context = os.environ['DEPLOYMENT_CONTEXT']
    storage_path = os.environ['STORAGE_PATH']

    # Define the parameters that you might want to change within a given deployment:
    hadoop_namenode_ip = Variable.get('hadoop_namenode_ip')
    hadoop_jobtracker_ip = Variable.get('hadoop_jobtracker_ip')
    webhdfs_url = Variable.get('webhdfs_url', 'http://webhdfs.api.wa.bl.uk/')
    webhdfs_access_user = Variable.get('webhdfs_user', 'access')
    push_gateway = Variable.get('metrics_push_gateway')

    # Define the common parameters for running Docker tasks:
    hadoop_docker_image = 'ukwa/docker-hadoop:hadoop-0.20'
    ukwa_task_image = 'ukwa/ukwa-manage:latest'
    w3act_task_image = 'ukwa/python-w3act:latest'
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
            'volumes': ['%s:/storage' % self.storage_path ],
            'auto_remove': False, # True is a bit aggressive and stops Airflow grabbing logs.
            'do_xcom_push': False, # This is not currently working with DockerOperators so defaulting to off for now.
        }   
