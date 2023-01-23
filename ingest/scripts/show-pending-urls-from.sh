#!/bin/sh

URL=$1

echo Checking pending URLs starting from: $URL

echo Need a password set, ${CRAWLER_PWD}

docker run --net=host -ti ukwa/hapy h3cc -H localhost -u admin -p ${CRAWLER_PWD} -q $URL -l 100 pending-urls-from
