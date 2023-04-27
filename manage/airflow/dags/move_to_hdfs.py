"""
## move_to_hdfs.py

Tasks for copying and/or moving content to HDFS
"""
import logging
import json
import sys
import datetime

from subprocess import check_output

from airflow import DAG
from airflow.decorators import dag, task
from airflow.operators.python import get_current_context
from airflow.operators.docker_operator import DockerOperator
from airflow.utils.dates import days_ago

from docker.types import Mount

from _common_ import Config

# Pick up shared configuration:
c = Config()

# These args will get passed on to each operator/task:
default_args = c.get_default_args()

with DAG(
    'copy_to_hdfs_crawler08',
    default_args=default_args,
    description='Copy WARCs/crawl logs from Crawler08/DC to Hadoop 3 HDFS',
    schedule_interval='@daily',
    start_date=datetime.datetime(2023, 4, 11),
    max_active_runs=1,
    catchup=True,
    tags=['ingest'],
    params= {
        # Source server:
        'source': 'crawler08.n45.bl.uk',
        # Talk to remote Docker to run the upload from there:
        'docker_url': 'ssh://heritrix@crawler08.n45.bl.uk',
        # No trailing slash here, noting that symlinked (sub)paths won't work:
        'host_dir': '/opt/data/dc',
        # User to run containers as on remote host (usually have to use UID):
        'host_user': 1001,
    },
) as dag:
    dag.doc_md = f"""
### Copy WARCs and crawl logs from {dag.params['source']} to Hadoop 3 HDFS

This task performs some work to tidy up the WARCs and logs from the crawler.

* Uses the rclone command to upload data to HDFS.
    * Requires rclone >= 1.58.0 as [that is the first version with HDFS file move support](https://rclone.org/changelog/#v1-58-0-2022-03-18).
* Selects WARCs and logs with file names reflecting the execution date, so uses backfill to ensure all data is transferred.
    * TODO Any 'orphaned' crawl.log files will not get picked up at present.
* Uses a copy/check/move process. The check step compares the files against HDFS and calculates the content hashes using rclone's `hasher` module.
* The '--no-traverse' command avoids the system listing the HDFS remote contents ahead of time, which is quicker in our case.
* The default '--transfers 4' already saturates the 1Gbps/125MBps outgoing connection.
* The default '--checkers 8' also saturated the incoming connection.
* The '--use-json-log' flag isn't that helpful in this context, so not using it at present.
* TODO Switch to --suffix EXEC_DATE_STAMP imstead of --immutable?
* TODO The '--delete-empty-src-dirs' deleted prometheus stuff and said it deleted the whole folder which was very alarming.

Configuration:

* Runs rclone remotely on { dag.params['source'] } as user { dag.params['host_user'] } via DOCKER_HOST={ dag.params['docker_url'] }.
* The tasks are configured to look for completed WARCs and log files under `{dag.params['host_dir']}/heritrix/output`.
* The push gateway is configured to be `{c.push_gateway}`. 

How to check it's working:

* The Task Instance logs in Airflow will show details of the data being copied.
* The source and target folder can be inspected to determine what's changed.
* TODO Currently, no metrics are pushed to Prometheus.

Tool container versions:

 * Rclone Image: `{c.rclone_image}`
      
2023/04/26 15:09:53 INFO  : prometheus/data/wal/checkpoint.00000253: Removing directory
2023/04/26 15:09:53 INFO  : prometheus/data/wal: Removing directory
2023/04/26 15:09:53 INFO  : prometheus/data/chunks_head: Removing directory
2023/04/26 15:09:53 INFO  : prometheus/data/01GYZ18BCQCV0VQZAGQ2MFCQHS/chunks: Removing directory
2023/04/26 15:09:53 INFO  : prometheus/data/01GYZ18BCQCV0VQZAGQ2MFCQHS: Removing directory
2023/04/26 15:09:53 INFO  : prometheus/data/01GYYTCM4QRY6H0JC0D5X63XFX/chunks: Removing directory
2023/04/26 15:09:53 INFO  : prometheus/data/01GYYTCM4QRY6H0JC0D5X63XFX: Removing directory
2023/04/26 15:09:53 INFO  : prometheus/data/01GYYKGWZHHHYXXVV0EQASWN63/chunks: Removing directory
2023/04/26 15:09:53 INFO  : prometheus/data/01GYYKGWZHHHYXXVV0EQASWN63: Removing directory
2023/04/26 15:09:53 INFO  : prometheus/data/01GYYKGWWPEV8HA9GSS2GNG1N7/chunks: Removing directory
2023/04/26 15:09:53 INFO  : prometheus/data/01GYYKGWWPEV8HA9GSS2GNG1N7: Removing directory
2023/04/26 15:09:53 INFO  : prometheus/data/01GYYCN5MQG2KYB24TCPF9YRN2/chunks: Removing directory
2023/04/26 15:09:53 INFO  : prometheus/data/01GYYCN5MQG2KYB24TCPF9YRN2: Removing directory
2023/04/26 15:09:53 INFO  : prometheus/data/01GYXYXQ9VPMFAHABQTA4S8AWS/chunks: Removing directory
2023/04/26 15:09:53 INFO  : prometheus/data/01GYXYXQ9VPMFAHABQTA4S8AWS: Removing directory
2023/04/26 15:09:53 INFO  : prometheus/data/01GYW146256GW5YK3GXXYGZTQ9/chunks: Removing directory
2023/04/26 15:09:53 INFO  : prometheus/data/01GYW146256GW5YK3GXXYGZTQ9: Removing directory
2023/04/26 15:09:53 INFO  : prometheus/data/01GYT3AMW0HK711KA8AK8111ZX/chunks: Removing directory
2023/04/26 15:09:53 INFO  : prometheus/data/01GYT3AMW0HK711KA8AK8111ZX: Removing directory
2023/04/26 15:09:53 INFO  : prometheus/data/01GYM9Y14EFYHVNMKKYANV8XWY/chunks: Removing directory
2023/04/26 15:09:53 INFO  : prometheus/data/01GYM9Y14EFYHVNMKKYANV8XWY: Removing directory
2023/04/26 15:09:53 INFO  : prometheus/data/01GYEGJ3MFZ0XD5WHT2R1YJT51/chunks: Removing directory
2023/04/26 15:09:53 INFO  : prometheus/data/01GYEGJ3MFZ0XD5WHT2R1YJT51: Removing directory
2023/04/26 15:09:53 INFO  : prometheus/data/01GXX4C7RFDDG48ND8FSES9SYW/chunks: Removing directory
2023/04/26 15:09:53 INFO  : prometheus/data/01GXX4C7RFDDG48ND8FSES9SYW: Removing directory
2023/04/26 15:09:53 INFO  : prometheus/data: Removing directory
2023/04/26 15:09:53 INFO  : prometheus/config: Removing directory
2023/04/26 15:09:53 INFO  : prometheus: Removing directory
2023/04/26 15:09:53 INFO  : dc2023/20230417122646/warcs: Removing directory
2023/04/26 15:09:53 INFO  : dc2023/20230417122646/viral: Removing directory
2023/04/26 15:09:53 INFO  : dc2023/20230417122646/logs: Removing directory
2023/04/26 15:09:53 INFO  : dc2023/20230417122646: Removing directory
2023/04/26 15:09:53 INFO  : dc2023/20230411150902/warcs: Removing directory
2023/04/26 15:09:53 INFO  : dc2023/20230411150902/viral: Removing directory
2023/04/26 15:09:53 INFO  : dc2023/20230411150902/logs: Removing directory
2023/04/26 15:09:53 INFO  : dc2023/20230411150902: Removing directory
2023/04/26 15:09:53 INFO  : dc2023/20230411145333/logs: Removing directory
2023/04/26 15:09:53 INFO  : dc2023/20230411145333: Removing directory
2023/04/26 15:09:53 INFO  : dc2023: Removing directory


""" 
    # Setup config common to all operations.
    shared_mounts = [
        Mount( 
            # Specify heritrix sub-folder as that's where the permissions are set right:
            source=f"{dag.params['host_dir']}/heritrix/output", 
            target=f"{dag.params['host_dir']}/heritrix/output", 
            type='bind'
        ),
        Mount(
            # Allow config to be persisted: 
            source="/home/heritrix/.config", 
            target="/config",
            type='bind'
        ),
        Mount(
            # Allow cache to be persisted: 
            source="/home/heritrix/.cache", 
            target="/.cache",
            type='bind'
        ),
    ]
    shared_env = {
        # Configure rclone using env vars: H3:
        'RCLONE_CONFIG_H3_TYPE': 'hdfs',
        #'RCLONE_CONFIG_H3_NAMENODE': 'h3nn.wa.bl.uk:54310', # crawlers only have external DNS
        'RCLONE_CONFIG_H3_NAMENODE': '192.168.45.181:54310',
        'RCLONE_CONFIG_H3_USERNAME': 'ingest',
        # Hasher:
        'RCLONE_CONFIG_H3-HASHER_TYPE': 'hasher',
        'RCLONE_CONFIG_H3-HASHER_REMOTE': 'h3:',
    }
    # Define the critical common rclone parameters here for easy re-use:
    shared_cmd =' --include "*{{ ds_nodash }}*.warc.gz"'\
                ' --include "crawl.log.cp*{{ ds_nodash }}*"' \
                ' --no-traverse'\
                ' --immutable'\
                ' --transfers 4'\
                ' --checkers 8'\
                ' -vv'

    # Copy the content up:
    copy_to_hdfs = DockerOperator(
        task_id='copy-to-hdfs',
        # No point using --checksum here as the HDFS remote does not support checksums:
        command=f'copy {shared_cmd} {{{{ params.host_dir }}}}/heritrix/output h3:/heritrix/output',
        docker_url=dag.params['docker_url'],
        image=c.rclone_image,
        user=dag.params['host_user'],
        mounts=shared_mounts,
        environment=shared_env,
        tty=True, # <-- So we see logging
        do_xcom_push=False,
        mount_tmp_dir=False, # Because remote
    )

    # Run checksum comparison against HDFS, using --download to make the h3-hasher remote calculate checksums and store them:
    compare_to_hdfs = DockerOperator(
        task_id='compare-to-hdfs',
        command=f'check --one-way --download {shared_cmd} {{{{ params.host_dir }}}}/heritrix/output h3-hasher:/heritrix/output',
        docker_url=dag.params['docker_url'],
        image=c.rclone_image,
        user=dag.params['host_user'],
        mounts=shared_mounts,
        environment=shared_env,
        tty=True, # <-- So we see logging
        do_xcom_push=False,
        mount_tmp_dir=False, # Because remote
    )

    # Move to HDFS, verifying the (rclone-cached) local checksums against the (rclone-hasher-cached) remote checksums: 
    move_to_hdfs = DockerOperator(
        task_id='move-to-hdfs',
        command=f'move --checksum {shared_cmd} {{{{ params.host_dir }}}}/heritrix/output h3-hasher:/heritrix/output',
        docker_url=dag.params['docker_url'],
        image=c.rclone_image,
        user=dag.params['host_user'],
        mounts=shared_mounts,
        environment=shared_env,
        tty=True, # <-- So we see logging
        do_xcom_push=False,
        mount_tmp_dir=False, # Because remote
    )

    # And define the sequence:
    copy_to_hdfs >> compare_to_hdfs >> move_to_hdfs

