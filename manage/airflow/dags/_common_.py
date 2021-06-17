"""
# _common_.py

This file holds values and variables that are shared across DAGs.
""" 
import os
from airflow.models import Variable, Connection

class Config():

    # Pick up definitions for the deployment context, and secrets:
    deployment_context = os.environ['DEPLOYMENT_CONTEXT']
    storage_path = os.environ['STORAGE_PATH']

    # Define the parameters that you might want to change within a given deployment:
    # TODO This can overload the metadata DB when there are a lot of parameters,
    # so may switch more to environment variables later on.

    # Which particular service(s) to talk to when working on access:
    access_trackdb_url = Variable.get('trackdb_url')
    access_hadoop_namenode_ip = Variable.get('hadoop_namenode_ip')
    access_hadoop_jobtracker_ip = Variable.get('hadoop_jobtracker_ip')
    access_webhdfs_url = Variable.get('webhdfs_url', 'http://webhdfs.api.wa.bl.uk/')
    access_webhdfs_user = Variable.get('webhdfs_user', 'access')
    push_gateway = Variable.get('metrics_push_gateway')

    # Define the common parameters for running Docker tasks:
    hadoop_docker_image = 'ukwa/docker-hadoop:hadoop-0.20'
    ukwa_task_image = 'ukwa/ukwa-manage:latest'
    w3act_task_image = 'ukwa/python-w3act:latest'
    postgres_image = 'postgres:9.6.2'

    # Get a copy of the default arguments:
    def get_default_args_for_access(self):
        return {
            # Shared configuration for all tasks:
            'owner': 'airflow',
            'retries': 3,
            # Shared configuration for all Docker tasks:
            'extra_hosts': {
                'namenode': self.access_hadoop_namenode_ip,
                'jobtracker': self.access_hadoop_jobtracker_ip
            },
            'volumes': ['%s:/storage' % self.storage_path ],
            'auto_remove': False # True is a bit aggressive and stops Airflow grabbing logs.
        }   
