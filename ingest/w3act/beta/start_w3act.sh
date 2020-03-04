#!/bin/sh

# Determine deploment platform - dev, beta, prod - from server hostname
DEPLOY_PLATFORM=$(hostname -s | grep -oP '^[a-z]+')

# Source deployment platform envars
if [[ -f ~/gitlab/ukwa-services-env/w3act/${DEPLOY_PLATFORM}/w3act.env ]]; then
        source ~/gitlab/ukwa-services-env/w3act/${DEPLOY_PLATFORM}/w3act.env
else
        echo "Deployment platform ${DEPLOY_PLATFOM} w3act envars file missing"
        exit 1
fi


export PYWB_NGINX_CONF=$PWD/pywb-nginx.conf

# Deploy
docker stack deploy -c ../docker-compose.yml ife_beta
