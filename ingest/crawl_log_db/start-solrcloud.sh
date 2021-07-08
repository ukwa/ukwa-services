export CURRENT_UID=$(id -u):$(id -g)

echo $CURRENT_UID

mkdir -p cores

docker stack deploy -c docker-compose.dev.yml crawl_db_solr

