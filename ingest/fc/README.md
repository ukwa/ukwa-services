Frequent Crawler Production Setup
---------------------------------

The production crawler setup is split into multiple stacks.

- `fc-kafka` runs the Kafka service for frequent crawling.
- `fc-crawl` runs the crawls (requires `fc-kafka` to be running).
- `fc-wb` runs a (optional) Wayback access point to look at the crawl results.


    $ docker swarm init --advertise-addr 192.168.45.15

The crawler needs to be in public DNS, so lookups get back to us.

The crawler needs a few firewall ports opening up.



fc-kafka


    $ docker stack deploy -c docker-compose.yml fc_kafka

```
mkdir /mnt/gluster/fc/zookeeper
mkdir /mnt/gluster/fc/zookeeper/data
mkdir /mnt/gluster/fc/zookeeper/datalog
mkdir /mnt/gluster/fc/kafka
```


Here's the links for the user interfaces for the services running on crawler05.bl.uk


     docker run --network="host" ukwa/ukwa-manage submit -k ${CRAWL_HOST_INTERNAL_IP}:9094 -L now  -S fc.tocrawl.npld http://acid.matkelly.com/
    docker run --network="fc_kafka_default" ukwa/ukwa-manage submit -k kafka:9092 -F fc.tocrawl.npld http://acid.matkelly.com/


From another host, you can use 

    docker run ukwa/ukwa-manage submit -k crawler05.bl.uk:9094 -S fc.tocrawl.npld http://acid.matkelly.com/


- [Kafka UI](http://crawler05.bl.uk:9000/#/observe)

- [NPLD Heritrix Crawler](https://crawler05.bl.uk:8443/engine/job/frequent)
- [By-Permission Heritrix Crawler](https://crawler05.bl.uk:9443/engine/job/frequent)
- [Embedded Prometheus Instance](http://crawler05.bl.uk:9191/graph)
    - [e.g. heritrix3\_crawl\_job\_uris\_total](http://crawler05.bl.uk:9191/graph?g0.range_input=1h&g0.expr=heritrix3_crawl_job_uris_total&g0.tab=1)

See also [a Groovy script for checking the current sheet status from the Heritrix console](https://github.com/internetarchive/heritrix3/wiki/Heritrix3-Useful-Scripts#print-all-sheet-associations-and-all-sheet-properties)



