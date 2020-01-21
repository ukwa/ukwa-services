#!/bin/sh
docker run -ti ukwa/crawl-streams crawlstreams -k 192.168.45.15:9094 -r -q fc.tocrawl.npld 
