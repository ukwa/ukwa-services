source ../prod.env
docker stack deploy -c docker-compose.yml dc_wb
