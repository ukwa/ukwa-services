#!/bin/bash

export URL=$1

echo Submitting: $URL

docker run -ti --net=host ukwa/crawl-streams submit -k crawler05.n45.bl.uk:9094 -F -L now fc.tocrawl.npld $URL
