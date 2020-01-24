The Access Stack
================

This stack contains the components used for general, public access to our web archives. i.e.

https://www.webarchive.org.uk/

See the comments in [the stack definition](./docker-compose.yml) for details.


Deployment Procedures
--------------------=

Where possible, deployment setup is handled in the launch script (e.g. [./dev/deploy-access-dev.sh](./dev/deploy-access-dev.sh)). However, some setup cannot be done this way.

### Shine Database

Shine requires a PostgreSQL database, so additional setup is required using the scripts in [./scripts/postgres](./scripts/postgres).

If starting from a new deployment, and having deployed the stack, you first need to stop Shine itself from running, as otherwise it will attempt to start up and will insert and empty database into PostgreSQL and this will interfere with the restore process. So, use

    $ docker service rm website_shine

Now you can run `create-db.sh` to create the database itself, and you can use `list-db.sh` to check the database is there. Then, run `create-user.sh` to run the `setup_user.sql` script and set up a suitable user with access to the database.  

To do a restore, use `download-shine-db-dump.sh` to grab a database dump from HDFS, but you'll need to edit the file to select the backup with a given date. Now, running `restore-shine-db-from-dump.sh` should populate the database.

Re-deploy the whole service stack, and Shine will restart using the restored database.

### Setting up api endpoints

Once running, the entire system should be exposed properly via the API gateway.  e.g. accessing the dev system:

- For the actual website, we want `website.dapi.wa.bl.uk` to point to `dev-swarm-members:80`.  
- For the Topics & Themes Solr instance we should route `solr-collections.dapi.wa.bl.uk` to `dev-swarm-members:9020`.

### Setting up X.webarchive.org.uk

The website is designed to be run behind a boundary web proxy that handles SSL etc.  To make use of this stack of services, the server that provides e.g. dev.webarchive.org.uk will need to be configured to point to the right API endpoint.

Having set this up, if we visit e.g. `dev.webarchive.org.uk` the traffic should show up under `website.dapi.wa.bl.uk` and so forth.

## Testing

TBA