#!/bin/sh

source /etc/sysconfig/w3act

scp root@act.wa.bl.uk:/backup/postgres_db/w3act.pgdump-20170202030101 w3act.pgdump
cp w3act.pgdump /zfspool/beta/postgresql/

docker-compose -f docker-compose.yml -f docker-compose.beta.yml up -d postgres

echo "Importing data..."
docker-compose exec postgres pg_restore -d w3act -U w3act -O /var/lib/postgresql/data/w3act.pgdump
echo "First upgrade to 2.0.x needs a TRUNCATE watched_target CASCADE; !!!"

echo "Shutting down..."
docker-compose -f docker-compose.yml -f docker-compose.beta.yml down postgres

