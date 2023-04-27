"""
### Airflow Cleanup

Since version 2.3.0, Airflow has built-in support for clearing out older job information, using the [`airflow db clean`](https://airflow.apache.org/docs/apache-airflow/stable/cli-and-env-variables-ref.html#clean) command.
This DAG runs `airflow db clean` every day. A variable called `airflow_db_cleanup__max_db_entry_age_in_days` can be set to determine how many days of data to keep. The default is 30 days.

For older versions of Airflow, see e.g. <https://github.com/teamclairvoyant/airflow-maintenance-dags/tree/master/db-cleanup>

"""
import airflow
from airflow.models import DAG, Variable
from airflow.operators.bash import BashOperator
import os
from datetime import timedelta

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

with DAG(
        DAG_ID,
        default_args=default_args,
        schedule_interval=SCHEDULE_INTERVAL,
        start_date=START_DATE,
        params={ 'max_days': DEFAULT_MAX_DB_ENTRY_AGE_IN_DAYS },
        tags=['airflow', 'maintenance'],
        catchup = False,
        doc_md = __doc__
    ) as dag:

    cleanup_task = BashOperator(
        task_id='run_airflow_db_clean',
        bash_command="airflow db clean -v --yes --skip-archive --clean-before-timestamp '{{ macros.ds_add(ds, -params.max_days) }}'",
    )
