#!/bin/bash

export URL=$1

echo Submitting: $URL

docker run -ti --net=host ukwa/crawl-streams submit -k localhost:9094 -S -F -L now fc.tocrawl.npld $URL
#docker run -ti --network="fc_kafka_default" ukwa/crawl-streams submit -k kafka:9092 -R -S -F -t noLimit,recrawl-1day -L now fc.tocrawl.npld $URL

