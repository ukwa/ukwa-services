#!/bin/sh
docker run --network="fc_kafka_default" ukwa/crawl-streams submit -k kafka:9092 -S -L now -F fc.tocrawl.bypm http://acid.matkelly.com/
