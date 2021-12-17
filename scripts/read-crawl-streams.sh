#!/bin/sh
docker run -ti ukwa/crawl-streams crawlstreams -k crawler05.bl.uk:9094 -r -q fc.tocrawl.npld 
