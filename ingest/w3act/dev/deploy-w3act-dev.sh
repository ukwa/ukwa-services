#!/bin/sh

# Pull in sensitive environment variables:
source /mnt/nfs/config/gitlab/ukwa-services-env/w3act/dev/w3act.env

# Pull in context variables:
source w3act.env

# Launch the common configuration with these environment variable:
docker stack deploy -c ../docker-compose.yml w3act
