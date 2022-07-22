#!/bin/bash

export URL=$1

echo Submitting: $URL

docker run -ti --net=host ukwa/crawl-streams submit -k localhost:9094 -F -L now fc.tocrawl.npld $URL
