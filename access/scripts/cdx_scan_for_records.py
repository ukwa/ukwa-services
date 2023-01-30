
# 
# This script is intended to drop records that have known playback problems.
# A redirect to the web archive was installed under the given prefixes on 2022-06-10, so this query will 
# match all subsequent captures, to be dropped.
#
# Requires https://github.com/ukwa/ukwa-api-client
#

from ukwa_api_client.cdx import cdx_scan

prefixes = [
    "www.bl.uk/onlinegallery/onlineex/firemaps",
    "www.bl.uk/onlinegallery/onlineex/unvbrit",
    "www.bl.uk/onlinegallery/onlineex/maps",
    "www.bl.uk/onlinegallery/onlineex/kinggeorge",
    "www.bl.uk/onlinegallery/onlineex/ordsurvdraw",
    "www.bl.uk/onlinegallery/onlineex/topdrawings",
    "www.bl.uk/onlinegallery/onlineex/kensturn",
    "www.bl.uk/onlinegallery/onlineex/deptford",
    "www.bl.uk/onlinegallery/features/londoninmaps",
]

from_ts = "20220610000000"

for prefix in prefixes:
    for cdx in cdx_scan(url = prefix, limit=1000000, from_ts=from_ts):
        print(cdx)
