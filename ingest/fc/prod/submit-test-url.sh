#!/bin/sh
docker run --network="fc_kafka_default" ukwa/crawl-streams:1.0.1 submit -k kafka:9092 -S -L now -F fc.tocrawl.npld http://acid.matkelly.com/
