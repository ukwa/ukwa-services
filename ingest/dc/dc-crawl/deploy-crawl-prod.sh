source ../prod.env
#export HERITRIX_VERSION=2.5.2
export HERITRIX_VERSION=2.7.2

docker stack deploy -c docker-compose.yml dc_crawl
