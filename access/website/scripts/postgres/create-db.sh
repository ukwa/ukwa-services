#!/bin/sh
docker run --net access_website_default postgres:9.6.2 createdb -h shinedb -U postgres shine
