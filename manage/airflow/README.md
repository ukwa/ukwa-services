

useradd -u 50000 -G docker airflow

./deploy-airflow.sh /home/anj/gitlab/ukwa-services-env/dev.env

DockerOperator work fine but must return 1 on errors to get picked up. Presumably stderr gets logged and stdout is for XCom and should return JSON.

http://dev1.n45.wa.bl.uk:5050/admin/metrics/


https://eugeneyan.com/writing/why-airflow-jobs-one-day-late/

- All commands should error properly, e.g. raise a non zero exit code, send logs to stderr etc.
- Use Docker, via DockerOperator, and use this to managed dependencies and limit the parts of the filesystem each task has access to.
- All DAGs use the doumentation feature to briefly describe what they do.
- [named SSH Connection](https://airflow.apache.org/docs/apache-airflow-providers-ssh/stable/connections/ssh.html)
- Sentry and error tracking
    - https://airflow.apache.org/docs/apache-airflow/stable/logging-monitoring/errors.html
    - https://docs.sentry.io/platforms/python/guides/flask/configuration/options/

