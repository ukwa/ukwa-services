W3ACT
=====
This stack deploys our curatorial service W3ACT and the sub-components it depends upon:

- W3ACT
- W3ACT's PostgreSQL DB
- QA Wayback (which uses an NGINX instance to make sure it's setup right)
- PDF-to-HTML convertor (for document harvester functionality)

These services are passive, in that they only consume UKWA APIs for playback, and data feeds are generated from them. They don't initiate the crawling processes or other regular tasks.

## Deployment
It is expected this general dev > beta > prod deployment approach will simplify and streamline the roll-out process for our services. Consequently, the regular deployment practice should be that of redeployment. That is, updating an existing service.

### Updating an existing service
This updating process should be mostly the same for all services, so the significant differences are highlighted below.

The services are deployed using the scripts provided for each deployment context (see `dev`/`beta`/`prod` folders).  The scripts should be reviewed to make sure the configuration is correct, particularly the parts that specify the persistent storage locations and connections to external services. Running these scripts should be all that is required to update an existing service.

The significant difference for the W3ACT stack from other code stacks is the Postgres database service. Any changes necessary for Postgres should be included via the W3ACT .sql scripts and thus should still be covered by the scripts mentioned immediately above. If the changes to Postgres are more impactful then the database processes defined in the 'Setting up a new service' section below should be followed.


### Setting up a new service
This section details the steps to set up this stack for the first time. The important detail in the W3ACT stack is the inclusion of the database, i.e., a service that holds information through the life of the stack. When updating an existing W3ACT stack, the deployment scripts should include any necessary changes to the database. However, when setting up the W3ACT stack for the first time, the database needs to be populated with data prior to the W3ACT service start-up, which logically means the database needs creating before it is populated with data. (If the W3ACT service has never been run before, this database population can be skipped - the W3ACT service will be used to enter the data.)

### Set the envars
Before starting the database or gathering the data, the following environment variables need to be set, inside gitlab 'ukwa-services-env' repo.
- W3ACT_PSQL_DIR
- W3ACT_PSQL_PASSWORD
- W3ACT_DUMPS_DIR

### Gather the database data
Assuming the W3ACT service has run before, the Postgres database data should exist somewhere, perhaps on a different host. This data needs to be copied to the deployment environment in preparation of the 'populating the database' step. 

First, create a backup of the existing Postgres database data on the existing host, e.g.,:
    pg_dump -U w3act -d w3act -h <postgres host> -p 5432 --format=c --file=w3act_dump.sql

Copy the output dump file to the deployment platform. At UKWA we regularly back up our Postgres database onto our Hadoop storage platform, so this can be downloaded via the script [download-db-dump.sh](scripts/postgres/download-db-dump.sh) (this needs amending to the correct date before executing).

ALSO RSYNC OPTION

### Start Postgres
Before populating the new service, we need to make sure that the database is running, but not W3ACT itself, as in some cases components like W3ACT will attempt to set up the database on start up. To make this simpler, we use `docker-compose` to spin up the database alone, rather than running the whole stack.

The scripts to manage the Postgres database processes are within scripts/postgres/\*.sh and these scripts source the *common.env* file to gather these envars. (*common.env* can be run on its own - it will complain if these envars are not set.)

With the *w3act_dump.sql* file located in this scripts/postgres/ directory - and the W3ACT_DUMPS_DIR envar set to the same directory - run [restore-db-from-dump.sh](scripts/postgres/restore-db-from-dump.sh) to start Postgres and populate the database.

_NOTE_ that if database changes are needed when updating versions, this is a good moment to implement them. See, for example `2020-02-reset-collection-areas.sh`.  This should drop you in the `psql` console where you can inspect the database.  When done, exit and then run:
    docker-compose down
to shut down the temporary PostgreSQL service.

To test that the Postgres data population has worked successfully, run:
    ./test_postgres.sh


## Integration with BL services
PII/eBooks etc. TBA

ebooks mount point
ejournals not in use
accessible PII
dls-sips-submitted

## Proxy chain

- www.webarchive.org.uk 
- act.api.wa.bl.uk
- prod1.n45.wa.bl.uk:9000

With HTTP 1.1. support and deployment location set at point of entrry.

```
        location /act {
                # Web Socket support:
                proxy_http_version 1.1;
                proxy_set_header Upgrade $http_upgrade;
                proxy_set_header Connection "Upgrade";
                proxy_set_header Host $host;

                # Let downstream services know how they are deployed:
                proxy_set_header        X-Forwarded-Proto       $scheme;
                proxy_set_header        X-Forwarded-Host        $host;
                proxy_set_header        X-Forwarded-Port        $server_port;
                proxy_set_header        X-Forwarded-For         $remote_addr;
                proxy_set_header        X-Real-IP               $remote_addr;

                proxy_pass             http://act.api.wa.bl.uk/act;
        }
```

```
                proxy_http_version 1.1;
                proxy_set_header Upgrade $http_upgrade;
                proxy_set_header Connection "Upgrade";
```

## Release

Tag this repo ingest-w3act-20210930 

## Downstream clients and exports

Luigi needed changes to tasks and configuration to cover:

- Backup to HDFS (where Luigi Access gets it from)
- Document Harvester


## The database backup task
Every day, the W3ACT database should be backed-up to HDFS, and the service deployment cannot be considered complete unless this is in place. See [`ukwa-services/manage/tasks`](../../manage/tasks/) for details.

Updated in `BackupProductionW3ACTPostgres`

## The service validation task
_In the future, we will have a suite of Robot Framework acceptance tests that will run daily (overnight) and report whether the services are running as expected._

Examples:
- Check results of database backup task?
- Check results of service validation task?


## Monitoring
The monitoring framework should:
- Check that W3ACT is up.
