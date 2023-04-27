"""
### Airflow Cleanup

This is an off-the-shelf task for managing cleanup of old tasks and logs within Airflow. It doesn't interact with anything else.

From: <https://github.com/teamclairvoyant/airflow-maintenance-dags/tree/master/db-cleanup>

A maintenance workflow that you can deploy into Airflow to periodically clean
out the DagRun, TaskInstance, Log, XCom, Job DB and SlaMiss entries to avoid
having too much data in your Airflow MetaStore.

    airflow trigger_dag --conf '[curly-braces]"maxDBEntryAgeInDays":30[curly-braces]' airflow-db-cleanup

    --conf options:
        maxDBEntryAgeInDays:<INT> - Optional

But now refactored to use https://airflow.apache.org/docs/apache-airflow/stable/cli-and-env-variables-ref.html#clean

"""
import airflow
from airflow import settings
from airflow.configuration import conf
from airflow.models import DAG, DagTag, DagModel, DagRun, Log, XCom, SlaMiss, TaskInstance, Variable
try:
    from airflow.jobs import BaseJob
except Exception as e:
    from airflow.jobs.base_job import BaseJob
from airflow.operators.python_operator import PythonOperator
from airflow.operators.bash import BashOperator
from datetime import datetime, timedelta
import dateutil.parser
import logging
import os
from sqlalchemy import func, and_
from sqlalchemy.exc import ProgrammingError
from sqlalchemy.orm import load_only

try:
    # airflow.utils.timezone is available from v1.10 onwards
    from airflow.utils import timezone
    now = timezone.utcnow
except ImportError:
    now = datetime.utcnow

# airflow-db-cleanup
DAG_ID = os.path.basename(__file__).replace(".pyc", "").replace(".py", "")
START_DATE = airflow.utils.dates.days_ago(1)
# How often to Run. @daily - Once a day at Midnight (UTC)
SCHEDULE_INTERVAL = "@daily"
# Who is listed as the owner of this DAG in the Airflow Web Server
DAG_OWNER_NAME = "airflow"
# List of email address to send email alerts to if this job fails
ALERT_EMAIL_ADDRESSES = [
	Variable.get('alert_email_address')
]
# Length to retain the log files if not already provided in the conf. If this
# is set to 30, the job will remove those files that arE 30 days old or older.

DEFAULT_MAX_DB_ENTRY_AGE_IN_DAYS = int(
    Variable.get("airflow_db_cleanup__max_db_entry_age_in_days", 30)
)
# Prints the database entries which will be getting deleted; set to False to avoid printing large lists and slowdown process
PRINT_DELETES = True
# Whether the job should delete the db entries or not. Included if you want to
# temporarily avoid deleting the db entries.
ENABLE_DELETE = True

default_args = {
    'owner': DAG_OWNER_NAME,
    'depends_on_past': False,
    'email': ALERT_EMAIL_ADDRESSES,
    'email_on_failure': True,
    'email_on_retry': False,
    'start_date': START_DATE,
    'retries': 1,
    'retry_delay': timedelta(minutes=1)
}

dag = DAG(
    DAG_ID,
    default_args=default_args,
    schedule_interval=SCHEDULE_INTERVAL,
    start_date=START_DATE,
    params={ 'max_days': DEFAULT_MAX_DB_ENTRY_AGE_IN_DAYS },
    tags=['airflow', 'manage'],
    catchup = False,
    doc_md = __doc__
)

bash_task = BashOperator(task_id='run_airflow_db_clean',
                         bash_command="airflow db clean -v --skip-archive --clean-before-timestamp '{{ macros.ds_add(ds, -params.max_days) }}'",
                         dag=dag)
