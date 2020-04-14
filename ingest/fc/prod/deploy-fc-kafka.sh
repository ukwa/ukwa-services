source ./prod-env.sh
docker stack deploy -c ../fc-kafka/docker-compose.yml fc_kafka
