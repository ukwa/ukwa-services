#!/bin/sh

docker run --net access_website_default -v $PWD/setup_user.sql:/tmp/setup_user.sql postgres:9.6.2 psql -h shinedb -v -U postgres -d shine -f /tmp/setup_user.sql

