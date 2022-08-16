#!/bin/sh

# read script environ argument
ENVIRON=$1
if ! [[ ${ENVIRON} =~ dev|beta|prod ]]; then
    echo "ERROR: Script $0 requires environment argument (dev|beta|prod)"
    exit
fi

# Set up environment variables
if [[ ${ENVIRON} == 'prod' ]]; then
    export UKWA_UI_IMAGE="ukwa/ukwa-ui:v1.4.3"
    export UKWA_NGINX_IMAGE="ukwa/ukwa-site:1.0.0"
    export PYWB_IMAGE="ukwa/ukwa-pywb:2.6.7.2"
    export API_IMAGE="ukwa/ukwa-access-api:latest"
    export SERVER_NAME=www.webarchive.org.uk
    export DEPLOYMENT_TAG=prod
    export STORAGE_PATH_WEBSITE=/mnt/nfs/prod1/access/data/website
    export CONFIG_PATH=/mnt/nfs/prod1/access/gitlab/ukwa-services-env/access/pywb
    # Location where the w3act_export Airflow task stores the ACLs:
    export PWYB_ACL_PATH=/mnt/nfs/prod1/airflow/data/airflow/wayback_acls/oukwa/acl
    source /mnt/nfs/prod1/access/gitlab/ukwa-services-env/prod.env

elif [[ ${ENVIRON} == 'beta' ]]; then
    export UKWA_UI_IMAGE="ukwa/ukwa-ui:v1.4.3"
    export UKWA_NGINX_IMAGE="ukwa/ukwa-site:1.0.0"
    export PYWB_IMAGE="ukwa/ukwa-pywb:2.6.7.2"
    export API_IMAGE="ukwa/ukwa-access-api:latest"
    export SERVER_NAME=beta.webarchive.org.uk
    export DEPLOYMENT_TAG=beta
    export STORAGE_PATH_WEBSITE=/mnt/gluster/beta/access/data/website
    export CONFIG_PATH=/home/access/gitlab/ukwa-services-env/access/pywb
    # Location where the w3act_export Airflow task stores the ACLs:
    export PWYB_ACL_PATH=/mnt/gluster/beta/airflow/data/airflow/wayback_acls/oukwa/acl
    source /home/access/gitlab/ukwa-services-env/beta.env
else
    # dev vars
    export UKWA_UI_IMAGE="ukwa/ukwa-ui:master"
    export UKWA_NGINX_IMAGE="ukwa/ukwa-site:master"
    export PYWB_IMAGE="ukwa/ukwa-pywb:2.6.7.2"
    export API_IMAGE="ukwa/ukwa-access-api:fastapi"
    export SERVER_NAME=dev.webarchive.org.uk
    export DEPLOYMENT_TAG=dev
    export STORAGE_PATH_WEBSITE=/mnt/nfs/data/website
    export CONFIG_PATH=/mnt/nfs/config/gitlab/ukwa-services-env/access/pywb
    # Location where the w3act_export Airflow task stores the ACLs:
    export PWYB_ACL_PATH=/mnt/nfs/data/airflow/wayback_acls/oukwa/acl
    source /mnt/nfs/config/gitlab/ukwa-services-env/dev.env
fi

# Common configuration
export CDX_SERVER="http://cdx.api.wa.bl.uk/data-heritrix"
export UKWA_INDEX="${CDX_SERVER}?url={url}&closest={closest}&sort=closest&filter=!statuscode:429&filter=!mimetype:warc/revisit"
export UKWA_ARCHIVE="webhdfs://hdfs.api.wa.bl.uk"
export USE_HTTPS=true
export SOLR_FULL_TEXT_SEARCH_PATH="http://solr.api.wa.bl.uk"
export SHINE_SOLR="http://solr-jisc.api.wa.bl.uk/solr/jisc"
export CURRENT_UID=$(id -u):$(id -g)
export PROXYHOST=http://194.66.232.92
export PROXYPORT=3127
# Crawler06 (n45 is not in DNS and we want to connect that way):
export KAFKA_BROKER="192.168.45.34:9094"

#export LOG_SERVER="udp://logs.wa.bl.uk:12201"
# Set up folders needed by different components
mkdir -p ${STORAGE_PATH_WEBSITE}/shine-postgres-data
mkdir -p ${STORAGE_PATH_WEBSITE}/cache
mkdir -p ${STORAGE_PATH_WEBSITE}/fc_analysis
mkdir -p ${STORAGE_PATH_WEBSITE}/collections_solr_cores
mkdir -p ${STORAGE_PATH_WEBSITE}/collections_solr_logs
mkdir -p ${STORAGE_PATH_WEBSITE}/iiif_cache
chmod a+w ${STORAGE_PATH_WEBSITE}/iiif_cache # IIIF server runs as specific container user

# Set up a tmp space for the web renderer that only gets deleted on reboot:
export WEB_RENDER_TMP=${STORAGE_PATH_WEBSITE}/webrender-tmp
mkdir -p ${WEB_RENDER_TMP}

# ensure data owned by user
#sudo chown -R ${CURRENT_UID} ${STORAGE_PATH_WEBSITE}

# Launch the common configuration with these environment variable:
# n.b. first config file sets PWD
docker stack deploy -c docker-compose.yml access_website
