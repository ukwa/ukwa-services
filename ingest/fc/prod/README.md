## Initial setup

Set up a data volume of a reasonable size:

    $ mkdir /mnt/data/fc

And a tmp/scratch volume of a reasonable speed:

    $ mkdir /mnt/data/fc/tmp		# If data volume fast enough
    $ mkdir /mnt/data/fc-tmp		# Separate, fast volume if not

Ensure we are in a suitable Swarm:

    $ docker swarm init --advertise-addr 192.168.45.12
    $ docker node ls

Get the deployment config:

    $ git clone https://github.com/ukwa/ukwa-services.git
    $ cd ukwa-services/ingest/fc/prod

Check the crawler-specific config; the naming convention should be "env-(prod|beta|dev)-<server name>.sh:

    $ vim env-prod-crawler07.sh


## Kafka setup

Deploy Kafka services and check they are running:

    $ ./deploy-fc-kafka.sh <config.sh>
    $ docker service ls

Create the topics:

    $ ./kafka-create-topics.sh

It may be necessary to force a restart of the UI so it's up definitely presenting up-to-date information:

    $ docker service update --force fc_ui_kafka_kafka-ui

The topics should now show up at e.g. http://crawler07.bl.uk:9000/


## Heritrix setup

Once this is in place, deploy the services and check they are running:

    $ ./deploy-fc-crawl.sh <config.sh>
    $ docker service ls

The services should now be visible:

* The NPLD crawl engine: https://crawler07.bl.uk:8443/engine/job/frequent
* The by-permission crawl engine: https://crawler07.bl.uk:9443/engine/job/frequent 
* The embedded Prometheus service: http://crawler07.bl.uk:9191/

The crawlers to be used - NPLD, BYPM, both - should now be logged into, built, and launched (from the latest checkpoint if appropriate).
The embedded Prometheus service can be viewed directly but it intended to be hooked into the main monitoring service.

## Testing

The `submit-test-url.sh` script can be used to lauch a test crawl, but NOTE that by default all setups are pointing at the PRODUCTION frequent crawl database. This means the crawl request will likely be rejected as already-crawled-recently. This shows it's working correctly!



## Shutdown

    $ docker stack rm fc_crawl
    $ docker stack rm fc_kafka

Note that, after running these the FC networks will still exist. This may cause problems is the above services are restarted. Stopping and starting docker - __if suitable__ - should resolve this.

All important data is persisted in the defined storage volumes, so full starts/stops are safe.
