

useradd -u 50000 -G docker airflow

./deploy-airflow.sh dev

DockerOperator work fine but must return 1 on errors to get picked up. Presumably stderr gets logged and stdout is for XCom and should return JSON.

### Setting up the required connections and variables

First, get the relevant connections and variables JSON files from the ukwa-services-env repository. Place them on the storage location shared with the Airflow Docker containers, so they can be seen at `/storage/

The, the importing setup works like this (using `dev` as an example):

```
./run-airflow-cmd.sh airflow variables import /storage/dev-variables.json
./run-airflow-cmd.sh airflow connections import /storage/dev-connections.json
```

Some of these connections use SSH, and refer to the required SSH keypairs from `gitlab/ukwa-services-env/airflow/ssh`. These should be copied to `${STORAGE_PATH}/ssh` to match the settings in the `connections.json` configuration file. This will allow jobs to run that rely on SSH connections to other services.

### Monitoring with Prometheus
http://dev1.n45.wa.bl.uk:5050/admin/metrics/


https://eugeneyan.com/writing/why-airflow-jobs-one-day-late/

- All commands should error properly, e.g. raise a non zero exit code, send logs to stderr etc.
- Use Docker, via DockerOperator, and use this to managed dependencies and limit the parts of the filesystem each task has access to.
- All DAGs use the doumentation feature to briefly describe what they do.
- [named SSH Connection](https://airflow.apache.org/docs/apache-airflow-providers-ssh/stable/connections/ssh.html)
- Sentry and error tracking
    - https://airflow.apache.org/docs/apache-airflow/stable/logging-monitoring/errors.html
    - https://docs.sentry.io/platforms/python/guides/flask/configuration/options/


Idea...

ssh root@gluster-fuse python3 -u - /mnt/gluster/fc < warcprox_warc_mv.py
