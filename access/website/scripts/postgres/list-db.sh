 docker run --net access_default -v $PWD/setup_user.sql:/tmp/setup_user.sql postgres:9.6.2 psql -h shinedb -U shine -d shine  --list
