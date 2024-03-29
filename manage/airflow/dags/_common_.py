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
    w3act_static_web_root = os.path.join(os.environ['W3ACT_STORAGE'], 'static/' )

    # Define the connection parameters, e.g. you might want to change within a given deployment:
    # FIXME Do we need the webhdfs here?
    wh_conn = Connection.get_connection_from_secrets("hadoop_020_webhdfs")
    webhdfs_access_url = f"http://{wh_conn.host}:{wh_conn.port}"
    webhdfs_access_user = wh_conn.login
    pg_conn = Connection.get_connection_from_secrets("metrics_push_gateway")
    push_gateway = f"{pg_conn.host}:{pg_conn.port}"
    w3act_web_conn = Connection.get_connection_from_secrets("access_w3act_web")
    ddhapt_w3act_web_conn = Connection.get_connection_from_secrets("ddhapt_w3act_web")
    ddhapt_df_db = Connection.get_connection_from_secrets("ddhapt_documents_found_db")

    # Pick up some variables
    hadoop_job_warc_batch_size = Variable.get('hadoop_job_warc_batch_size')

    # Define the common parameters for running Docker tasks:
    w3act_task_image = 'ukwa/python-w3act:2.1.5'
    ukwa_task_image = 'ukwa/ukwa-manage:2.4.2'
    ukwa_reports_image = 'ukwa/ukwa-reports:1.0.0'
    hadoop_docker_image = 'ukwa/docker-hadoop:2.1.2'
    postgres_image = 'postgres:9.6.2'
    rclone_image = 'rclone/rclone:1.62'
    crawlstreams_image = 'ukwa/crawl-streams:1.0.1'
    rf_image = 'ukwa/robot-framework:1.2.0'
    stat_pusher_image = 'ukwa/monitor-stat-pusher:latest'

    # Get a copy of the default arguments:
    def get_default_args(self):
        return {
            # Shared configuration for all tasks:
            'owner': 'airflow',
            'retries': 3,
            # Shared configuration for all Docker tasks:
            'extra_hosts': {
                'namenode': '192.168.1.103',
                'jobtracker': '192.168.1.104',
                # Note that H3 config uses proper domain names like h3rm.wa.bl.uk
            },
            'mounts': [
                Mount( source=self.storage_path, target='/storage', type='bind' ),
                Mount( source=self.w3act_static_web_root, target=self.w3act_static_web_root, type='bind' ),
                 ],
            'email_on_failure': True,
            'email': [
                    Variable.get('alert_email_address')
                ],
            'auto_remove': False, # True is a bit aggressive and stops Airflow grabbing container logs.
            'do_xcom_push': False, # This is not currently working with DockerOperators so defaulting to off for now.
            'mount_tmp_dir': False, # Not supported by docker-in-docker tasks
        }   


    def get_trackdb_url(self):
        # Connection to TrackDB to use:
        trackdb = Connection.get_connection_from_secrets("trackdb")
        trackdb_url = trackdb.get_uri().replace('%2F','/')
        return trackdb_url

    def get_access_cdx_url(self):
        return Connection.get_connection_from_secrets("access_cdx").get_uri()

