#!/bin/sh

set -euxo pipefail

./run-airflow-cmd.sh airflow variables set trackdb_url http://trackdb.dapi.wa.bl.uk/solr/tracking
./run-airflow-cmd.sh airflow variables set hadoop_jobtracker_ip 192.168.1.104
./run-airflow-cmd.sh airflow variables set hadoop_namenode_ip 192.168.1.103
./run-airflow-cmd.sh airflow variables set access_w3act_host ingest
./run-airflow-cmd.sh airflow variables set access_w3act_port 5434
./run-airflow-cmd.sh airflow variables set metrics_push_gateway monitor-pushgateway.dapi.wa.bl.uk:80
./run-airflow-cmd.sh airflow connections add --conn-uri "postgres://w3act:${W3ACT_PSQL_PASSWORD}@ingest:5434/w3act" --conn-description "The PostgreSQL connection that is used to populate the access services." access_w3act
./run-airflow-cmd.sh airflow connections add --conn-uri "http://trackdb.dapi.wa.bl.uk/solr/tracking" --conn-description "The TrackDB Solr instance to update and use to drive indexing etc." trackdb
./run-airflow-cmd.sh airflow connections add --conn-uri "http://192.168.45.91:9021/solr/collections" --conn-description "The Collections Solr instance used to populate the Topics & Themes part of the website." access_collections_solr
