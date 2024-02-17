#!/bin/sh
docker stack deploy -c ../fc-kafka-ui/docker-compose.yml fc_ui_kafka

wait
sleep 10
docker service ls
