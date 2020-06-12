Tasks
=====

The following tasks should be running regularly. 

We use bash flock to ensure only one copy of a script runs at once. We use TrackDB to keep track of jobs which need to run at a given interval, to avoid re-running them unnecessarily.

We update TrackDB with tasks completed. Verification that all important tasks are running by submitting Task Event data to Solr, and exporting that to Prometheus, with appropriate alerts set up.

Task scripts are kept with the service stack they support, but linked from here.

Scripts usually expect two environment variables to be set.

- `DEPLOY_ENV` which is a file path pointing to a file that declares the environment variables that define the DEV/BETA/PROD environment. See e.g. [dev.env.sh](./dev.env.sh).
- The BETA/PROD environments should be stored in GitLab (`ukwa-services-env`).
- These scripts may `source` in secrets from another file. If so, that file should be stored in GitLab (`ukwa-services-env`).

## Ingest

- Update crawl job specifications, based on W3ACT DB (daily)
    - _script to be added_
- Launch crawls, based on crawl job specifications (hourly)
    - _script to be added_
- Move WARCs and crawl logs to HDFS (hourly)
    - _currently not handled here_
- Get latest data from third-party sources: 
    - Nominet (monthly)
        - _Currently a Luigi task: [NominetDomainListToHDFS]()_
        - _script to be added_
- Back-up W3ACT PostgreSQL database to HDFS (daily)
    - As CSV [`./w3act-csv-to-hdfs.sh`](./ingest/w3act/scripts/w3act-csv-to-hdfs.sh)
    - As `pgdump`, _script to be added, currently Luigi: BackupProductionW3ACTPostgres_
- Analyse Crawl Logs, Run Document Harvester (hourly):
    - _script to be added_
- _GenerateW3ACTTitleExport_

## Management

- Update TrackDB from HDFS:
  - See [`update-trackdb-from-hdfs.sh`](./manage/trackdb/scripts/update-trackdb-from-hdfs.sh) 
  - Update with whole-of-HDFS file listing (daily):
    - `update-trackdb-from-hdfs.sh /`
  - _TBA_ Update TrackDB with partial file listing (hourly)
    - `update-trackdb-from-hdfs.sh /heritrix/output/frequent-npld`
    - `update-trackdb-from-hdfs.sh /heritrix/output/frequent-bypm`
- _TBA_ Recently Crawled data export (currently a Kafka client demon).
- _TBA_ Reports (GenerateHDFSReports, dead seeds, etc.)
- _TBA_ Metrics (generate metrics from TrackDB and push to the Prometheus push gateway)
- _TBA_ Back up TrackDB to HDFS.
- _TBC_ Copy HDFS file listing to HDFS? _CopyFileListToHDFS_

## Access

### Indexes

- Update CDX Index with latest WARCs on HDFS, based on TrackDB (hourly)
  - See [run-cdx-indexer.sh](./access/website/scripts/run-cdx-indexer.sh)
- Update `allows.txt` and `annotations.json` used for Solr indexing and access, based on W3ACT (at least daily)
  - See [update-acl.sh](./access/websites/scripts/w3act/update-acl.sh)
- Update Solr Index with latest WARCs on HDFS, based on TrackDB (hourly)
  - See [run-solr-indexer.sh](./access/website/scripts/run-solr-indexer.sh)

### Website

- Update `allows.aclj` in pywb, based on W3ACT (at least daily):
  - See [update-acl.sh](./access/websites/scripts/w3act/update-acl.sh)
- Update the Collection Solr, based on W3ACT (at least daily)
  - _script to be added, currently Luigi: PopulateCollectionsSolr_
- Run the [test suite](#testing) (daily after the above updates?) and raise an alert if the website is misbehaving
  - _script to be refined so it is tracked in TrackDB_
- Back-up the Shine PostgreSQL database (daily)
  - _script to be added, currently Luigi: BackupProductionShinePostgres_

