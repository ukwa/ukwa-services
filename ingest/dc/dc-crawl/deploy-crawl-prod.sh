source ../prod.env

export HERITRIX_VERSION=2.7.3

mkdir -p /heritrix/output/prometheus/config
cp prometheus/config/* /heritrix/output/prometheus/config
mkdir -p /heritrix/output/prometheus/data

mkdir ./shared

docker stack deploy -c docker-compose.yml dc_crawl
