#!bin/sh
docker run --network=host ukwa/ukwa-manage h3cc -H crawler05.bl.uk -P 8443 -u admin -p bl_uk -j frequent job-info-json
