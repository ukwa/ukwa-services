# Crawl Operations

The current crawl engine relies on Heritrix3 state management to keep track of crawl state, and this was not designed to cope under un-supervised system restarts. i.e. rather than being stateless, or delegating state management to something that ensures the live state is preserved immediately, we need to manage ensuring the runtime state is recorded on disk. This is why crawler operations are more complex than other areas.

## Starting Crawls

As stated above, before going any further, we need to ensure that Kafka has completed starting up and is ready for producers and consumers to connect.

- Build.
- Select Checkpoint. If expected checkpoints are not present, this means something went wrong while writing them. This should be reported to try to determine and address the root cause, but there's not much to be done other than select the most recent valid checkpoint.
- Launch.
- 

## Stopping Crawls

If possible, we wish to preserve the current state of the crawl, so we try to cleanly shut down while making a checkpoint to restart from.

Note that for our frequent crawls, we run two Heritrix services, one for NPLD content and one for by-permission crawling. When performing a full stop of the frequent crawls, both services need to be dealt with cleanly. When running on crawler06, this means:

- https://crawler06.bl.uk:8443/ is NPLD crawling.
- https://crawler06.bl.uk:9443/ is By-Permission crawling.

### Pause the crawl job(s)

For all Heritrixes in the Docker Stack: log into the Heritrix3 control UI, and pause any job(s) on the crawler that are in the `RUNNING` state. This can take a while (say up to two hours) as each worker thread tries to finish it's work neatly. Sometimes pausing never completes because of some bug, in which case we proceed anyway and accept some inaccuracies in the crawl state. If it works, all `RUNNING` jobs will now be in the state `PAUSED`.

### Checkpoint the job(s)

Via the UI, request a checkpoint. If there's not been one for a while, this can be quite slow (tens of minutes). If it works, a banner should flash up with the checkpoint ID, which should be noted so the crawl can be resumed from the right checkpoint. If the checkpointing fails, the logs will need to be checked for errors.

TBA debug notes.

    SEVERE: org.archive.crawler.framework.CheckpointService checkpointFailed  Checkpoint failed [Wed May 19 12:47:13 GMT 2021]
    java.io.IOException: Unable to move /heritrix/output/frequent-npld/20210424211346/logs/runtime-errors.log to /heritrix/output/frequent-npld/20210424211346/logs/runtime-erro
    rs.log.cp00025-20210519124709

    touch /mnt/gluster/fc/heritrix/output/frequent-npld/20210424211346/logs/runtime-errors.log

    docker logs --tail 100 fc_crawl_npld-heritrix-worker.1.h21137sr8l31niwsx3m3o7jri

    Checkpoint not made -- perhaps no progress since last? (see logs)

    INFO: org.archive.crawler.framework.CheckpointService requestCrawlCheckpoint all finishCheckpoint() completed in 0ms [Wed May 19 12:47:13 GMT 2021]
    INFO: org.archive.crawler.framework.CheckpointService requestCrawlCheckpoint completed checkpoint cp00025-20210519124709 in 3964ms [Wed May 19 12:47:13 GMT 2021]
    INFO: org.archive.crawler.framework.CheckpointService requestCrawlCheckpoint no progress since last checkpoint; ignoring [Wed May 19 12:50:13 GMT 2021]
    no progress since last checkpoint; ignoring

### Shutdown

At this point, all activity should have stopped, so it should not make much difference how exactly the service is halted.  To attempt to keep things as clean as possible, first terminate and then teardown the job(s) via the Heritrix UI.

You can now shut down the services...
