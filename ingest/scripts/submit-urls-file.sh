#!/bin/bash

export FILE=$1

echo First few lines of file: $FILE
docker run -ti --net=host --volume $PWD:/host ukwa/crawl-streams head -3 /host/$FILE

echo "Submitting URLs from file (will not force recrawl): $FILE"
docker run -ti --net=host --volume $PWD:/host ukwa/crawl-streams submit -k localhost:9094 -F fc.tocrawl.npld /host/$FILE
#docker run -ti --net=host --volume $PWD:/host ukwa/crawl-streams submit -k localhost:9094 -F -L now fc.tocrawl.npld /host/$FILE

