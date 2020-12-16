#!/bin/sh
docker run --net=host -ti ukwa/hapy h3cc -H crawler05.n45.bl.uk -u admin -p ${CRAWLER_PWD} show-all-sheets
