"""
## run_tests.py

Run tests against our systems to check all is well.
"""
import logging
import json
import sys
import os

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

# Pick up the output path:
OUTPUT_PATH = os.path.join(os.environ['W3ACT_STORAGE'], 'static/' )

# Need a proxy to talk to our websites on their public IPs/names:
EXTERNAL_WEB_PROXY = os.environ['EXTERNAL_WEB_PROXY']

# Define the workflow:
with DAG(
    'run_tests',
    default_args=default_args,
    description='Runs tests against our systems',
    schedule_interval='@daily',
    start_date=days_ago(1),
    max_active_runs=1,
    catchup=False,
    tags=['manage'],
) as dag:
    dag.doc_md = f"""
### Run Tests

This task runs service-level regression tests against our services.

* 

Configuration:

* Test reports will be written to `{OUTPUT_PATH}`.
* The push gateway is configured to be `{c.push_gateway}`.

How to check it's working:

* The test reports should be available via the W3ACT site, e.g. for production: <https://www.webarchive.org.uk/act/static/>

Tool container versions:

 * UKWA Robot Framework Test Image: `{c.rf_image}`

""" 

    run_tests_on_prod = DockerOperator(
        task_id='run-tests-on-prod',
        image=c.rf_image,
        command=f'--skiponfailure a11y --splitlog --loglevel FAIL --outputdir {OUTPUT_PATH}/test-reports/prod /tests',
        environment={
          "HOST": "https://www.webarchive.org.uk",
          "HOST_NO_AUTH": "https://www.webarchive.org.uk",
          "W3ACT_USERNAME": c.w3act_web_conn.login,
          "W3ACT_PASSWORD": c.w3act_web_conn.password,
          # URL to use when testing playback/APIs etc.
          "TEST_URL": "http://portico.bl.uk",
          "HTTP_PROXY": EXTERNAL_WEB_PROXY,
          "HTTPS_PROXY": EXTERNAL_WEB_PROXY,
          'PUSH_GATEWAY': c.push_gateway,
          "PROMETHEUS_JOB_NAME": "service_tests_prod",
        },
        mounts= [
            Mount( source=OUTPUT_PATH, target=OUTPUT_PATH, type='bind' )
        ],
        tty=True, # <-- So we see logging
        do_xcom_push=False,
    )
