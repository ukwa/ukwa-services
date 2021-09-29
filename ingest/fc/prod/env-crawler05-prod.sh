export CRAWL_HOST_LAN_IP=192.168.45.15
export CRAWL_HOST_WAN_IP=194.66.232.83
export H3_UID=$(id -u)

export STORAGE_PATH=/mnt/gluster/fc

export TMP_STORAGE_PATH=/mnt/local/fc-prod-tmp
# CrawlDB FC (OutbackCDX)
# Oddly slow...
#export CDXSERVER_ENDPOINT=http://crawldb-fc.api.wa.bl.uk/fc
export CDXSERVER_ENDPOINT=http://192.168.45.8:8081/fc

export HERITRIX_VERSION=?

