#!/bin/sh
docker service update --image ukwa/crawl-log-viewer intranet_crawl-log-viewer
docker service update --force intranet_web
