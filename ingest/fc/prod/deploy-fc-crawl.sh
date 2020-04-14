source ./prod-env.sh
docker stack deploy -c ../fc-crawl/docker-compose.yml fc_crawl
