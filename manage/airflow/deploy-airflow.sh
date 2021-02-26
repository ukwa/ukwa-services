export AIRFLOW_GID=992 # Run in the Docker group

docker stack deploy -c docker-compose.yaml airflow
