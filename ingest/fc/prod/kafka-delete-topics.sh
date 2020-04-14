docker run --net=fc_kafka_default wurstmeister/kafka:2.12-2.1.0 kafka-topics.sh --zookeeper zookeeper:2181 --delete --topic fc.crawled
docker run --net=fc_kafka_default wurstmeister/kafka:2.12-2.1.0 kafka-topics.sh --zookeeper zookeeper:2181 --delete --topic fc.tocrawl.bypm
docker run --net=fc_kafka_default wurstmeister/kafka:2.12-2.1.0 kafka-topics.sh --zookeeper zookeeper:2181 --delete --topic fc.tocrawl.npld

