source ./prod-env.sh

mkdir -p ${STORAGE_PATH}/zookeeper/data
mkdir -p ${STORAGE_PATH}/zookeeper/datalog
mkdir -p ${STORAGE_PATH}/kafka

docker stack deploy -c ../fc-kafka/docker-compose.yml fc_kafka
