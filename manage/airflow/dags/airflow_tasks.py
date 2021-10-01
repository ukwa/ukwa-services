"""
## airflow_tasks.py

Tasks managing Airflow itself.
"""
import json
from subprocess import check_output

from airflow.decorators import dag, task
from airflow.operators.python import get_current_context
from airflow.utils.dates import days_ago

from _common_ import Config

# Pick up shared configuration:
c = Config()

# These args will get passed on to each operator/task:
default_args = c.get_default_args()

# Override the user, so this runs as the Airflow user:
default_args['user'] = 'airflow'

@dag(
    default_args=default_args, 
    schedule_interval=None,
    start_date=days_ago(1),
    max_active_runs=1,
    catchup=False,
    tags=['manage', 'airflow']
)
def x_airflow_pause_all_dags():
    """
### Pause All DAGs

When triggered and unpaused, this workflow will pause all other DAGs.
It is intended to be used to cleanly shut everything down in an emergency.

After use, this DAG should be paused and the other DAGs should 
be unpaused manually as appropriate for the situation..
    """

    @task()
    def pause_all_dags():
        """
        #### Pause Loop

        Get the list of DAGs and pause them one-by-one.
        """
        context = get_current_context()

        # Run command to list all
        dags_json = check_output('airflow dags list -o json', shell=True)
        dags = json.loads(dags_json)

        for d in dags:
            if d['dag_id'] != context['dag'].dag_id and not d['paused']:
                print('Requesting pause of DAG: %s' % d['dag_id'])
                check_output('airflow dags pause %s' % d['dag_id'], shell=True)

    pauser = pause_all_dags()

pause_all = x_airflow_pause_all_dags()