#### Common directories
# kafka
export STORAGE_PATH=/mnt/data/fc
export TMP_STORAGE_PATH=${STORAGE_PATH}/tmp
export ZK_DATA_PATH=${STORAGE_PATH}/zookeeper/data
export ZK_DATALOG_PATH=${STORAGE_PATH}/zookeeper/datalog
export KAFKA_PATH=${STORAGE_PATH}/kafka

# + crawler
export HERITRIX_OUTPUT_PATH=${STORAGE_PATH}/heritrix/output
export HERITRIX_WREN_PATH=${STORAGE_PATH}/heritrix/wren
export SURTS_NPLD_PATH=${STORAGE_PATH}/surts/npld
export SURTS_BYPM_PATH=${STORAGE_PATH}/surts/bypm
export NPLD_STATE_PATH=${TMP_STORAGE_PATH}/heritrix/npld/state
export BYPM_STATE_PATH=${TMP_STORAGE_PATH}/heritrix/bypm/state
export CDX_STORAGE_PATH=${STORAGE_PATH}/cdx
export TMP_WEBRENDER_PATH=/tmp/webrender
export PROMETHEUS_DATA_PATH=${STORAGE_PATH}/prometheus-data
export WARCPROX_PATH=${STORAGE_PATH}/warcprox

# crawler details
export CRAWL_HOST_LAN_IP=172.31.43.254
export CRAWL_HOST_WAN_IP=18.130.205.6
#export H3_UID=$(id -u)
export H3_UID=0
export HERITRIX_VERSION=2.9.4.1
export CDXSERVER_ENDPOINT=http://crawler-cdx:8081/fc

# pywb
export WB_HOST=crawler07.bl.uk
