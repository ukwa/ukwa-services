#!/bin/sh
export CURRENT_UID=$(id -u):$(id -g)

source ../prod.env

sudo mkdir -p ${STORAGE_PATH}/zookeeper/data
sudo mkdir -p ${STORAGE_PATH}/zookeeper/datalog

sudo mkdir -p ${STORAGE_PATH}/kafka/kafka-logs-broker-1
sudo mkdir -p ${STORAGE_PATH}/prom-jmx

#sudo chown -R ec2-user ${STORAGE_PATH}
cp prom-jmx/* ${STORAGE_PATH}/prom-jmx

docker stack deploy -c docker-compose.yml dc_kafka

