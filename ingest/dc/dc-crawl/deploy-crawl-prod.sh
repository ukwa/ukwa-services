source ../prod.env

export CURRENT_UID=$(id -u):$(id -g)

echo "Will run as ${CURRENT_UID},,,"

sudo mkdir -p /heritrix/output/prometheus/config
sudo mkdir -p /heritrix/output/prometheus/data
sudo chown -R ec2-user /heritrix/output

cp prometheus/config/* /heritrix/output/prometheus/config

mkdir -p ./shared

#mkdir -p /heritrix/state/clamav

docker stack deploy -c docker-compose.yml dc_crawl
