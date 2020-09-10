#!/bin/sh
export CURRENT_UID=$(id -u):$(id -g)
export STORAGE_PATH=/heritrix/kafka

mkdir -p ${STORAGE_PATH}/zookeeper/data
mkdir -p ${STORAGE_PATH}/zookeeper/datalog

mkdir -p ${STORAGE_PATH}/kafka/kafka-logs-broker-1
mkdir -p ${STORAGE_PATH}/prom-jmx
cp prom-jmx/* ${STORAGE_PATH}/prom-jmx

docker stack deploy -c docker-compose.yml dc_kafka

