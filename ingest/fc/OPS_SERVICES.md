Service Operations
==================

move-to-S3

## Docker Stacks

### Launching the Services


    docker system prune -f

#### Waiting for Kafka

    docker service logs --tail 100 -f fc_kafka_kafka

Depending on the 

    ...Loading producer state from snapshot files...
    
Check in UI too. Restart if not showing up.

    docker service update --force fc_kafka_ui
    
    
Check surts and exclusions. 
Check GeoIP DB (GeoLite2-City.mmdb) is installed and up to date.

JE cleaner threads
je.cleaner.threads to 16 (from the default of 1) - note large numbers went very badly causing memory exhaustion
Bloom filter
MAX_RETRIES=4



#### Shutdown

At this point, all activity should have stopped, so it should not make much difference how exactly the service is halted.  To attempt to keep things as clean as possible, first terminate and then teardown the job(s) via the Heritrix UI.

Then remote the crawl stack:

    docker stack rm fc_crawl
    
If this is not responsive, it may be necessary to restart Docker itself. This means all the services get restarted with the current deployment configuration.

    service docker restart
    
Even this can be quite slow sometimes, so be patient.
