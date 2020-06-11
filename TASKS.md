Tasks
=====

The following tasks should be running regularly. 

We use bash flock to ensure only one copy of a script runs at once. We use TrackDB to keep track of jobs which need to run at a given interval, to avoid re-running them unnecessarily.

We update TrackDB with tasks completed. Verification that all important tasks are running by submitting Task Event data to Solr, and exporting that to Prometheus, with appropriate alerts set up.

Task scripts are kept with the service stack they support, but linked from here.

Scripts usually expect two environment variables to be set.

- `DEPLOY_ENV_VARS` which is a file path pointing to a file that declares the environment variables that define the DEV/BETA/PROD environment. See e.g. [dev.env.sh](./dev.env.sh).
- `SECRET_ENV_VARS` which is a file path pointing to a file that declares environment variables that have secret values.

## Ingest

- Update crawl job specifications, based on W3ACT data (daily)
- Launch crawls, based on crawl job specifications (hourly)
- Move WARCs and crawl logs to HDFS (hourly)
- Get latest data from third-party sources: 
    - Nominet (monthly)
        - _Currently a Luigi task: []()_
- Back-up W3ACT PostgreSQL database to HDFS (daily)
    - As CSV [`./w3act-csv-to-hdfs.sh`](./ingest/w3act/scripts/w3act-csv-to-hdfs.sh)

## Management

- Update TrackDB with whole-of-HDFS file listing (daily):
    - `<./hadoop-lsr.sh> /`
- _TBA_ Update TrackDB with partial file listing (hourly)
    - `<./hadoop-lsr.sh> /heritrix/output/frequent-npld`
    - _TBA_ `<./hadoop-lsr.sh> /heritrix/output/frequent-bypm`
- _TBA_ Recently Crawled data export (currently a Kafka client demon).
- _TBA_ Reports (dead seeds, etc.)
- _TBA_ Back up TrackDB to HDFS.

## Access

### Indexes

- Update CDX Index with latest WARCs on HDFS (hourly)
- Update `allows.aclj` and `annotations.json` used for Solr indexing and access (at least daily)
- Update Solr Index with latest WARCs on HDFS (hourly)
- Analyse crawl logs, extract documents (hourly)

### Website

- Update `allows.aclj` in pywb (at least daily)
- Update the Collection Solr (at least daily)
- Run the [test suite](#testing) (daily after the above updates?) and raise an alert if the website is misbehaving
- Back-up the Shine PostgreSQL database (daily)

