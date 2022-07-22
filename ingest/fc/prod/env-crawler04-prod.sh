export CRAWL_HOST_LAN_IP=192.168.45.12
export CRAWL_HOST_WAN_IP=194.66.232.93
export WB_HOST=crawler04.bl.uk
export H3_UID=$(id -u)

export STORAGE_PATH=/mnt/gluster/fc
#export STORAGE_PATH=/mnt/lr10/fc
export TMP_STORAGE_PATH=/mnt/lr10/fc-tmp

# CrawlDB FC (OutbackCDX)
# n.b. DNS name would need BL nameservers:
# cdx2
export CDXSERVER_ENDPOINT=http://192.168.45.8:8081/fc
# cdx1
#export CDXSERVER_ENDPOINT=http://192.168.45.7:8081/fc
# Oddly slow via API service...
#export CDXSERVER_ENDPOINT=http://crawldb-fc.api.wa.bl.uk/fc

export HERITRIX_VERSION=2.9.0


