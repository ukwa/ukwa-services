export CRAWL_HOST_LAN_IP=192.168.45.34
export CRAWL_HOST_WAN_IP=194.66.232.88
export WB_HOST=crawler06.bl.uk
export H3_UID=$(id -u)

export STORAGE_PATH=/mnt/gluster/fc
export TMP_STORAGE_PATH=/mnt/localraid6/fc/tmp
export CDX_STORAGE_PATH=/mnt/localraid6/fc/cdx

# CrawlDB FC (OutbackCDX)
# n.b. DNS name would need BL nameservers:
# cdx1
#export CDXSERVER_ENDPOINT=http://192.168.45.7:8081/fc
# cdx2
#export CDXSERVER_ENDPOINT=http://192.168.45.8:8081/fc
# cdx3
#export CDXSERVER_ENDPOINT=http://192.168.45.19:8081/fc
# Oddly slow via API service...
#export CDXSERVER_ENDPOINT=http://crawldb-fc.api.wa.bl.uk/fc
# Just keep things neat:
export CDXSERVER_ENDPOINT=http://crawler-cdx:8081/fc

export HERITRIX_VERSION=2.9.0

