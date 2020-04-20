#!/bin/sh
docker run -ti -v $PWD:/host --add-host=namenode:192.168.1.103 --add-host=jobtracker:192.168.1.104 ukwa/docker-hadoop:hadoop-0.20 $*
