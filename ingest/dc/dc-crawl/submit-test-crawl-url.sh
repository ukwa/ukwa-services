#!/bin/sh
docker run ukwa/crawl-streams submit --seed -k ${HOSTNAME}:9094 dc.tocrawl http://data.webarchive.org.uk/crawl-test-site/
