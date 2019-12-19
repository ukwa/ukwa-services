#!/bin/sh

# Pull in sensitive environment variables:
source /mnt/nfs/config/gitlab/ukwa-services-env/w3act/dev/w3act.env

# Set up the dev.webarchive.org.uk hostname - unfortunately this needs a different nginx config for pywb
export SERVER_NAME=192.168.45.91:9000
export SERVER_SCHEME=http


# Make DEV visually distinct (any CSS colour name will work)
export APPLICATION_NAVBAR_COLOR=purple

# Run dev against the test PII service:
export PII_URL=http://piiirc.ad.bl.uk/pii/vdc

# Set up the persistent data locations:
export DATA_FOLDER=/mnt/nfs/data/w3act
export W3ACT_PSQL_DIR=$DATA_FOLDER/postgresql
export W3ACT_DUMPS_DIR=$DATA_FOLDER/postgresql-dumps
export DDHAPT_SIPS_SUBMITTED_DIR=$DATA_FOLDER/dls-sips-submitted

# Set up DDHAPT submission folders, which are not real CIFS shares on DEV:
#export DDHAPT_EBOOKS_SUBMISSION_DIR=/mnt/cifs/ebooksirc
export DDHAPT_EBOOKS_SUBMISSION_DIR=$DATA_FOLDER/dls/ebooksirc
export DDHAPT_EJOURNALS_SUBMISSION_DIR=$DATA_FOLDER/dls/ejournalsirc

# Declare a DEV Swarm hostname, which we can use to connect to JMX to poke around inside W3ACT.
export JMX_HOSTNAME=dev1.n45.wa.bl.uk

# Launch the common configuration with these environment variable:
docker stack deploy -c ../docker-compose.yml w3act
