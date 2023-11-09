The Ingest Stacks <!-- omit in toc -->
=================

- [Introduction](#introduction)
- [Operations](#operations)
  - [Crawler Service Operations](#crawler-service-operations)
    - [Launching the Services](#launching-the-services)
    - [Waiting for Kafka](#waiting-for-kafka)
    - [Shutdown](#shutdown)
  - [Crawl Operations](#crawl-operations)
    - [Starting Crawls](#starting-crawls)
    - [Stopping Crawls](#stopping-crawls)
    - [Pause the crawl job(s)](#pause-the-crawl-jobs)
    - [Checkpoint the job(s)](#checkpoint-the-jobs)
    - [Shutdown](#shutdown-1)
- [Workflows](#workflows)
  - [How the Frequent Crawler works](#how-the-frequent-crawler-works)
  - [How the Document Harvester works](#how-the-document-harvester-works)
    - [Known Failure Modes](#known-failure-modes)
    - [Debugging Approach](#debugging-approach)


Introduction
------------

This section covers the service stacks that are used for curation and for crawling.

- [`w3act`](./w3act/) - where curators define what should be crawled, and describe what has been crawled.
- [`fc`](./fc/) - the Frequent Crawler, which crawls sites as instructed in `w3act`.
- [`dc`](./dc/) - the Domain Crawler, which us used to crawl all UK sites, once per year.

The [`crawl_log_db`](./crawl_log_db/) service is not in use, but contains a useful example of how a Solr service and it's associated schema can be set up using the Solr API rather than maintaining XML configuration files.

- [ ] TBA move-to-S3?

Operations
----------

This section covers some common operations when interacting with the Ingest services. In particular, the operations for the Frequent Crawler (FC) and the Domain Crawler (DC) are very similar, so these are documented here.

### Crawler Service Operations

Both the FC and the DC use the same software and same set of service stacks, just with different configuration via various environment variables.

Both services have:

* A Kafka stack, as Kafka used to launch crawls and capture a copy of the crawl log.  This should always be started first, as Heritrix doesn't not always cope when Kafka is not up and running. Note that the service being ready can take a lot longer than the Docker service takes to start up, depending on how large the topic logs are.  
* A Kafka UI stack. This is optional, but useful for checking Kafka is actually ready for use, and for inspecting the contents of the Kafka topics.
* A Worker stack, which contains one or two Heritrix instances, and supporting services like ClamAV.
* A Wayback stack, which is optional, and can be used to look at what has been crawled (as long as the WARCs are still held locally). 


#### Launching the Services


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


### Crawl Operations

The current crawl engine relies on Heritrix3 state management to keep track of crawl state, and this was not designed to cope under un-supervised system restarts. i.e. rather than being stateless, or delegating state management to something that ensures the live state is preserved immediately, we need to manage ensuring the runtime state is recorded on disk. This is why crawler operations are more complex than other areas.

#### Starting Crawls

As stated above, before going any further, we need to ensure that Kafka has completed starting up and is ready for producers and consumers to connect.

- Build.
- Select Checkpoint. If expected checkpoints are not present, this means something went wrong while writing them. This should be reported to try to determine and address the root cause, but there's not much to be done other than select the most recent valid checkpoint.
- Launch.
- 

#### Stopping Crawls

If possible, we wish to preserve the current state of the crawl, so we try to cleanly shut down while making a checkpoint to restart from.

Note that for our frequent crawls, we run two Heritrix services, one for NPLD content and one for by-permission crawling. When performing a full stop of the frequent crawls, both services need to be dealt with cleanly. When running on crawler06, this means:

- https://crawler06.bl.uk:8443/ is NPLD crawling.
- https://crawler06.bl.uk:9443/ is By-Permission crawling.

#### Pause the crawl job(s)

For all Heritrixes in the Docker Stack: log into the Heritrix3 control UI, and pause any job(s) on the crawler that are in the `RUNNING` state. This can take a while (say up to two hours) as each worker thread tries to finish it's work neatly. Sometimes pausing never completes because of some bug, in which case we proceed anyway and accept some inaccuracies in the crawl state. If it works, all `RUNNING` jobs will now be in the state `PAUSED`.

#### Checkpoint the job(s)

Via the UI, request a checkpoint. If there's not been one for a while, this can be quite slow (tens of minutes). If it works, a banner should flash up with the checkpoint ID, which should be noted so the crawl can be resumed from the right checkpoint. If the checkpointing fails, the logs will need to be checked for errors, as unless a new checkpoint is succefully completed, it will likely not be valid.

As an example, under some circumstances the log rotation does not work correctly. This means non-timestamped log files may be missing, which means when the next checkpoint runs, there are errors like:

    $ docker logs --tail 100 fc_crawl_npld-heritrix-worker.1.h21137sr8l31niwsx3m3o7jri
    ....
    SEVERE: org.archive.crawler.framework.CheckpointService checkpointFailed  Checkpoint failed [Wed May 19 12:47:13 GMT 2021]
    java.io.IOException: Unable to move /heritrix/output/frequent-npld/20210424211346/logs/runtime-errors.log to /heritrix/output/frequent-npld/20210424211346/logs/runtime-erro
    rs.log.cp00025-20210519124709

These errors can be avoided by adding empty files in the right place, e.g.

    touch /mnt/gluster/fc/heritrix/output/frequent-npld/20210424211346/logs/runtime-errors.log

But immediately re-attempting to checkpoint a paused crawl will usually fail with:

    Checkpoint not made -- perhaps no progress since last? (see logs)

This is because the system will not attempt a new checkpoint if the crawl state has not changed. Therefore, to force a new checkpoint, it is necessary to briefly un-pause the crawl so some progress is made, then re-pause and re-checkpoint.


#### Shutdown

At this point, all activity should have stopped, so it should not make much difference how exactly the service is halted.  To attempt to keep things as clean as possible, first terminate and then teardown the job(s) via the Heritrix UI.

You can now shut down the services...


Workflows
---------

The Ingest services work together in quite complicated ways, so this section attempts to describe some of the core workflows.  This should help determine what's happened if anything goes wrong.

### How the Frequent Crawler works



### How the Document Harvester works

1.  Curators mark Targets as being Watched in W3ACT.
2.  The [`w3act_export` workflow](http://airflow.api.wa.bl.uk/dags/w3act_export/grid) running on Airflow exports the data from W3ACT into files that contain this information.
3.  The usual move-to-hdfs scripts move WARCs and logs onto the Hadoop store.
4.  The TrackDB file tracking database gets updated so recent WARCs and crawl logs are known to the system. (See the `update_trackdb_*` tasks on [http://airflow.api.wa.bl.uk](http://airflow.api.wa.bl.uk/home)/).
5.  The usual web archiving workflow indexes WARCs into the CDX service so items become available.
6.  The Document Harvester [`ddhapt_log_analyse` workflow](http://airflow.api.wa.bl.uk/dags/ddhapt_log_analyse/grid) runs Hadoop jobs that take the W3ACT export data and use it to find potential documents in the crawl log.
    1.  This currently means PDF files on Watched Targets.
    2.  For each, a record is pushed to a dedicate PostgreSQL Document Database (a part of the W3ACT stack), with a status of _NEW_.
7.  The Document Harvester [ddhapt\_process\_docs workflow](http://airflow.api.wa.bl.uk/dags/ddhapt_process_docs/grid) gets the most recent _NEW_ documents from the Document Database and attempts to enrich the metadata and post them to W3ACT.
    1.  Currently, the metadata enrichment process talks to the live web rather than the web archive.
    2.  In general, PDFs are associated with the website they are found from (the landing page), linked to the Target.
    3.  For GOV.UK, we rely on the PDFs having a rel=up HTTP header that unambigiously links a PDF to it's landing page.
    4.  The enriched metadata is then used to push a request to W3ACT. This metadata includes an access URL that points to the UKWA website on the public web ([see here for details](https://github.com/ukwa/ukwa-services/blob/aa95df6854382e6b6e84edc697dcb4da2804ef9c/access/website/config/nginx.conf#L154-L155)).
    5.  W3ACT checks the file in question can be accessed via Wayback and calculates the checksum of the payload, or throws an error if it's not ready yet.
    6.  If the submission works, the record is updated in the Document Database so it's no longer _NEW_.
    7.  If it fails, it will be re-run in the future, so once it's available in Wayback it should turn up in W3ACT.
8.  Curators review the Documents found for the Targets they own, and update the metadata as needed.
9.  Curators then submit the Documents, which creats a XML SIP file that is passed to a DLS ingest process.
10.  The DLS ingest process passes the metadata to MER and to Aleph.
11.  The MER version is not used further.
12.  The Aleph version then becomes the master metadata record, and is passed to Primo and LDLs via the Metadata Aggregator.
13.  Links in e.g. Primo point to the access URLs included with the records, meaning users can find and access the documents.

#### Known Failure Modes

The Document Harvester has been fairly reliable in recent years, but some known failure modes may help resolve issues.

*   Under certain circumstances, Heritrix has been known to stop rotating crawl logs properly. If this happens, crawl log files may stop appearing or get lost. Fixing this may require creating an empty crawl.log file in the right place so a checkpoint can rotate the files correctly, or in the worst cases, a full crawler restart. If this happens, crawl logs will stop arriving on HDFS.
*   If there is a problem with the file tracking database getting updated to slowly, then the Document Harvester Airflow workflows may run but see nothing to process. This can be determined by checking the logs via Airflow, and checking that the expected number of crawl log files for that day were found. Clearing the job so Airflow re-runs it will resolve any gaps.
*   If there is a problem with W3ACT (either directly, or with how it talks to the curators Wayback instance), then jobs may fail to upload processed Documents to W3ACT. This can be spotted by checking the logs via Airflow, but note that any Documents that have not yet been CDX indexed are expected to be logged as errors at this point, so it can be difficult to tell things apart. It may be necessary to inspect the W3ACT container logs to determine if there's a problem with W3ACT itself.

#### Debugging Approach

Problems will generally be raised by Jennie Grimshaw, who is usually able and happy to supply some example Document URLs that should have been spotted. This is very useful in that it provides some test URLs to run checks with, e.g.

*   Check the URLs actually work and use `curl -v` to see if the `Link: rel=up` header is present (for GOV.UK) which helps find the landing page URL.
*   Check the crawl-time CDX index (currently at [http://crawler06.bl.uk:8081/fc](http://crawler06.bl.uk:8081/fc)) to check if the URLs have been crawler at all.
*   Check the access time CDX index (currently at [http://cdx.api.wa.bl.uk/data-heritrix](http://cdx.api.wa.bl.uk/data-heritrix)) to check if the items have been indexed correctly.
*   Check the Curator Wayback service ([https://www.webarchive.org.uk/act/wayback/archive/](https://www.webarchive.org.uk/act/wayback/archive/)) to see if the URLs are accessible.
*   Query the PostgreSQL Document Database to see if the URL was found by the crawl log processor and what the status of it is.

Overall, the strategy is to work out where the problem has occurred in the chain of events outlined in the first section, and then modify and/or re-run the workflows as needed.
