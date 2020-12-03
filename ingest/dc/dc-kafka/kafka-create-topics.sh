IMAGE=wurstmeister/kafka:2.12-2.1.0

docker run --net=dc_kafka_default ${IMAGE} kafka-topics.sh --zookeeper zookeeper:2181 --create --topic dc.crawled --replication-factor 1 --partitions 16 --config compression.type=snappy

docker run --net=dc_kafka_default ${IMAGE} kafka-topics.sh --zookeeper zookeeper:2181 --create --topic dc.tocrawl --replication-factor 1 --partitions 16 --config compression.type=snappy

docker run --net=dc_kafka_default ${IMAGE} kafka-topics.sh --zookeeper zookeeper:2181 --create --topic dc.inscope --replication-factor 1 --partitions 16 --config compression.type=snappy


