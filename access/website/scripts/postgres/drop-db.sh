#!/bin/sh
docker run --net access_website_default postgres:9.6.2 dropdb -h shinedb -U postgres shine
