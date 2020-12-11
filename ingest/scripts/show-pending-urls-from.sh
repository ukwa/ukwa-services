#!/bin/sh

URL=$1

echo Checking pending URLs starting from: $URL

docker run --net=host -ti ukwa/hapy h3cc -H crawler05.n45.bl.uk -u admin -p ${CRAWLER_PWD} -q $URL -l 1000 pending-urls-from
