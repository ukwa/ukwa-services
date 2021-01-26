export CURRENT_UID=$(id -u):$(id -g)

echo $CURRENT_UID

mkdir cores

docker-compose -f docker-compose.dev.yml up -d solrcloud

