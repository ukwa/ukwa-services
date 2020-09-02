source ../prod.env

export HERITRIX_VERSION=2.7.3

docker stack deploy -c docker-compose.yml dc_crawl
