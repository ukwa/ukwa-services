
## Initial setup

Set up a data volume of a reasonable size:

    $ mkdir /mnt/lr10/fc

And a tmp/scratch volume of a reasonable speed:

    $ mkdir /mnt/lr10/fc-tmp

Ensure we are in a suitable Swarm:

    $ docker swarm init --advertise-addr 192.168.45.12
    $ docker node ls

Get the deployment config:

    $ git clone https://github.com/ukwa/ukwa-services.git
    $ cd ukwa-services/ingest/fc/prod

Check the crawler-specific config and link it in place:

    $ vim prod-env-crawler04.sh
    $ ln -s prod-env-crawler04.sh prod-env.sh

Note that all these configurations are 'live' and point to the production frequent-crawl database (the OutbackCDX collection that records what happened recently).

## Kafka setup

Deploy Kafka services and check they are running:

    $ sh deploy-fc-kafka.sh
    $ docker service ls

Create the topics:

    $ sh kafka-create-topics.sh

Force a restart of the UI so it's up definately presenting up-to-date information:

    $ docker service update --force fc_ui_kafka_kafka-ui

The topics should now show up at e.g. http://crawler04.bl.uk:9000/


## Heritrix setup

The dynamic container-based web rendering services uses a lot of temporary IP addresses, so a dedicated subnet is used:


    $ ./create-webrender-network.sh


Once this is in place, deploy the services and check they are running:

    $ sh deploy-fc-crawl.sh
    $ docker service ls

The services should now be visible:

* The NPLD crawl engine: https://crawler04.bl.uk:8443/engine/job/frequent
* The by-permission crawl engine: https://crawler04.bl.uk:9443/engine/job/frequent 
* The embedded Prometheus service: http://crawler04.bl.uk:9191/

The embedded Prometheus service can be viewed directly but it intended to be hooked into the main monitoring service.

## Testing

The `submit-test-url.sh` script can be used to lauch a test crawl, but NOTE that by default all setups are pointing at the PRODUCTION frequent crawl database. This means the crawl request will likely be rejected as already-crawled-recently. This shows it's working correctly!


## Integration

The integration points are:

* The crawl launch task needs to be configured to inject launch requests into the correct crawler.
* The monitoring service needs to be configured to pick up the metrics via Prometheus federation.
* The move-warcprox-warcs and move-to-hdfs tasks need to be set up so WARCs and logs are arranged and transported to HDFS.


## Shutdown

    $ docker stack rm fc_crawl
    $ docker stack rm fc_kafka

All important data is persisted in the defined storage volumes, so full starts/stops are safe.
