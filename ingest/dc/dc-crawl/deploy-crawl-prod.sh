source ../prod.env

export CURRENT_UID=$(id -u):$(id -g)

echo "Will run as ${CURRENT_UID},,,"

mkdir -p /heritrix/output/prometheus/config
cp prometheus/config/* /heritrix/output/prometheus/config
mkdir -p /heritrix/output/prometheus/data

mkdir -p ./shared

#mkdir -p /heritrix/state/clamav

docker stack deploy -c docker-compose.yml dc_crawl
