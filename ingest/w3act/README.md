W3ACT
=====

This stack deploys our curatorial service W3ACT and the sub-components it depends upon:

- W3ACT
- W3ACT's PostgreSQL DB
- QA Wayback (which uses an NGINX instance to make sure it's setup right)
- PDF-to-HTML convertor (for document harvester functionality)

These services are passive, in that they only consume UKWA APIs for playback, and data feeds are generated from them. They don't initiate the crawling processes or other regular tasks.

Deployment
==========

The services are deployed using the scripts provided for each deployment context (see `dev`/`beta`/`prod` folders).  The scripts should be reviewed to make sure the configuration is correct, particularly the parts that specify the persistent storage locations and connections to external services.

As well as being able to run the services, the database needs to be set up correctly, and a couple of management tasks need to be in place...

## Migrating the database an existing service

When moving to a new deployment, we need to populate the database, using the scripts in the `scripts/postgres` folder. And old service should be shut down and a database backup should be taken. The correct command is of the form:

    pg_dump -U w3act -d w3act -h database-host -p 5432 --format=c --file=w3act_dump.sql

although the details will depend on the deployment details.

Alternatively, if timed appropriately, a backup from HDFS can be used, as shown in the [download-db-dump.sh](scripts/postgres/download-db-dump.sh) script.

Before populating the new service, we need to make sure that the database is running, but not W3ACT itself, as in some cases components like W3ACT will attempt to set up the database on start up. To make this simpler, we used `docker-compose` to spin up the database alone, rather than running the whole stack.

So, before running the main stack, place the W3ACT dump into the `scripts/postgres` folder (as `w3act_dump.sql`) and use the [restore-db-from-dump.sh](scripts/postgres/restore-db-from-dump.sh) to populate the database.

These scripts need to have the `W3ACT_PSQL_PASSWORD`, `W3ACT_PSQL_DIR` and `W3ACT_DUMPS_DIR` PostgreSQL environment variables set up, or else they will complain:

    The W3ACT_PSQL_PASSWORD, W3ACT_PSQL_DIR and W3ACT_DUMPS_DIR environment variables should be set!

The necessary values come from `ukwa-services-env` (for the password) and the `dev/beta/prod` deployment scripts (for the file locations).

To test it, you can run

    ./start.sh

To start the database, then

    ./connect.sh

_NOTE_ that if database changes are needed when updating versions, this is a good moment to implement them. See, for example `2020-02-reset-collection-areas.sh`.

which should drop you in the `psql` console where you can inspect the database.  When done, exit and then run:

    docker-compose down

to shut down the temporary PostgreSQL service.

## Integration with BL services

PII/eBooks etc. TBA

## Launching the stack

Given the database already exists, or has been populated as above, you should now be able to run the deployment script, e.g. `beta/deploy-w3act-beta.sh` for https://beta.webarchive.org.uk/act

The final step for launching the services is to ensure that the public name (e.g. `beta.webarchive.org.uk`) is pointing to the right Swarm endpoint.

The container version and banner color (once logged in) should be set appropriately and consistently with what's defined in this repository.

## The database backup task

Every day, the W3ACT database should be backed-up to HDFS, and the service deployment cannot be considered complete unless this is in place. See [`ukwa-services/management/tasks`](../../management/tasks/) for details.

## The service validation task

_In the future, we will have a suite of Robot Framework acceptance tests that will run daily (overnight) and report whether the services are running as expected._

## Monitoring

The monitoring framework should:

- Check that W3ACT is up.

TBC:

- Check results of database backup task?
- Check results of service validation task?


