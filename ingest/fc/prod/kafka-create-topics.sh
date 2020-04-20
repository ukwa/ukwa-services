export KAFKA_IMAGE=wurstmeister/kafka:2.12-2.1.0

docker run --net=fc_kafka_default ${KAFKA_IMAGE} kafka-topics.sh --zookeeper zookeeper:2181 --create --topic fc.crawled --replication-factor 1 --partitions 16 --config compression.type=snappy

docker run --net=fc_kafka_default ${KAFKA_IMAGE} kafka-topics.sh --zookeeper zookeeper:2181 --create --topic fc.tocrawl.bypm --replication-factor 1 --partitions 16 --config compression.type=snappy

docker run --net=fc_kafka_default ${KAFKA_IMAGE} kafka-topics.sh --zookeeper zookeeper:2181 --create --topic fc.inscope.bypm --replication-factor 1 --partitions 16 --config compression.type=snappy

docker run --net=fc_kafka_default ${KAFKA_IMAGE} kafka-topics.sh --zookeeper zookeeper:2181 --create --topic fc.tocrawl.npld --replication-factor 1 --partitions 16 --config compression.type=snappy

docker run --net=fc_kafka_default ${KAFKA_IMAGE} kafka-topics.sh --zookeeper zookeeper:2181 --create --topic fc.inscope.npld --replication-factor 1 --partitions 16 --config compression.type=snappy


