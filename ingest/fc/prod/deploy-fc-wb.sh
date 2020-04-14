source ./prod-env.sh
docker stack deploy -c ../fc-wb/docker-compose.yml fc_wb
