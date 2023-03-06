#!/bin/sh
docker run --net=host ukwa/crawl-streams submit --seed -k ${HOSTNAME}:9094 dc.tocrawl http://data.webarchive.org.uk/crawl-test-site/
