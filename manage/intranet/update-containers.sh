#!/bin/sh
docker service update --image ukwa/crawl-log-viewer intranet_crawl-log-viewer
# Force NGINX updates due to dependency on external file for config:
docker service update --force --image ukwa/ukwa-intranet:latest intranet_web
