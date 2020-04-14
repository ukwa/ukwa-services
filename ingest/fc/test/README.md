

Manually:

    docker exec -ti fc_kafka.1.or4yheug6jlufoutd2vxpugg2 bash
    unset KAFKA_JMX_OPTS
    /opt/kafka/bin/kafka-topics.sh --create --zookeeper zookeeper:2181 --topic fc.candidates --partitions 32 --replication-factor 1 --if-not-exists
