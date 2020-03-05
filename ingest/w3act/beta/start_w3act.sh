#!/bin/sh

# Source deployment platform secrets
if [[ -f ~/gitlab/ukwa-services-env/w3act/beta/w3act.env ]]; then
        source ~/gitlab/ukwa-services-env/w3act/beta/w3act.env
else
        echo "Beta deployment platform w3act secrets file missing"
        exit 1
fi

# Source deployment platform envars
if [[ -f ./w3act.env ]]; then
	source ./w3act.env
else
	echo "Beta deployment platform w3act envars file missing"
	exit 1
fi


# Deploy
docker stack deploy -c ../docker-compose.yml ife_beta
