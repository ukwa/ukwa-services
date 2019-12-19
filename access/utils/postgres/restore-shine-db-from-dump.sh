#!/bin/sh
echo "WARNING you must stop SHINE while doing this or it will insert it's own empty DB."
docker run --net access_default -v $PWD/shine_dump.sql:/tmp/shine_dump.sql postgres:9.6.2 pg_restore -h shinedb -v -U postgres -n public -d shine /tmp/shine_dump.sql
