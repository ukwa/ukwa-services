source ../prod.env
#export HERITRIX_VERSION=2.5.2
export HERITRIX_VERSION=2.6.10

docker stack deploy -c docker-compose.yml dc_crawl
