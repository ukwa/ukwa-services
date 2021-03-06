The Access Stack <!-- omit in toc -->
================

- [Introduction](#introduction)
  - [Integration Points](#integration-points)
- [The Access Data Stack](#the-access-data-stack)
  - [Deployment](#deployment)
  - [Components](#components)
    - [W3ACT Exports](#w3act-exports)
    - [Crawl Log Analyser](#crawl-log-analyser)
  - [Cron Tasks](#cron-tasks)
- [The Website Stack](#the-website-stack)
  - [Deployment](#deployment-1)
    - [NGINX Proxies](#nginx-proxies)
  - [Components](#components-1)
    - [Shine Database](#shine-database)
      - [Creating the Shine database](#creating-the-shine-database)
      - [Restoring the Shine database from a backup](#restoring-the-shine-database-from-a-backup)
      - [Creating a backup of the Shine database](#creating-a-backup-of-the-shine-database)
  - [Cron Jobs](#cron-jobs)
- [The Website Regression Test Stack](#the-website-regression-test-stack)
  - [Cron Jobs](#cron-jobs-1)
- [The Reading Room Wayback Stack](#the-reading-room-wayback-stack)
- [Monitoring](#monitoring)

# Introduction

This folder contains the components used for access to our web archives. It's made up of a number of separate stacks, with the first, 'Access Data', providing support for the others.

## Integration Points

These services can be deployed in different contexts (dev/beta/prod/etc.) but in all cases are designed to run (read-only!) against:

- The WebHDFS API.
- The OutbackCDX API.
- The Solr full-text search API(s).
- The Prometheus Push Gateway metrics API.

These are defined in the stack launch scripts, and can be changed as needed, based on deployment context if necessary.

The web site part is designed to be run behind an edge server than handles the SSL/non-SSL transition and proxies the requests downstream. More details are provided in the relevant Deployment section.

# The Access Data Stack

The other access stacks depend on a number of data sources and the `access_data` stack handles those. The [access_data stack definition](./data/docker-compose.yml) describes data volumes as well as services that the other stacks can refer to.

**NOTE** that this means that the stacks should be deployed consistently under the same names, as the `access_website` stack will not be able to find the networks associated with the `access_data` stack if the stack has been deployed under a different name.

## Deployment

The stack is deployed using:

    cd data
    ./deploy-access-data.sh dev

The deployment shell script sets up the right environment variables for each context (dev/beta/prod) before launching the services. This sets the `STORAGE_PATH` location where service data should be held, and this needs to be updated depending on what file system the Swarm nodes in a given deployment context share.

**NOTE** that after deployment, the Solr collection data is pulled into the service, which takes ~10 minutes to appear.

## Components

### W3ACT Exports

The `w3act_export` service downloads the regular W3ACT database dump from HDFS (`/9_processing/w3act/w3act-db-csv.zip`) and uses it to generate the data sources the rest of the stack needs.  The service runs once when the stack is deployed or when it is updated. Regular updates can be orchestrated by using cron to run:

    docker service update --force access_data_w3act_export

The outputs of the `w3act_export` service are placed on a volume called `access_data_w3act_export`. If all goes well, this should include:

- The `allows.aclj` and `block.aclj` files needed by the [pywb access control system](https://github.com/ukwa/ukwa-pywb/blob/master/docs/access_controls.md#access-control-system).  The `allows.aclj` file is generated from the data in W3ACT, based on the license status. The `blocks.aclj` file is managed in GitLab, and is downloaded from there.
- The `allows.txt` and `annotations.json` files needed for full-text Solr indexing.
 
The service also populates the secondary Solr collection used to generate the _Topics & Themes_ pages of the UKWA website.  The Solr instance and schema is managed as a Docker container in this stack.

TODO: On completing these tasks, the service sends metrics to Prometheus for monitoring (TBA).

### Crawl Log Analyser

The `analyse` service connects to the Kafka crawl log of the frequent crawler, and aggregates statistics on recent crawling activity. This is summarised into a regularly-updated JSON file that the UKWA Access API part of the website stack makes available for users. This is used by the https://ukwa-vis.glitch.me/ live crawler glitch experiment.

## Cron Tasks

As mentioned above, a cron task should be set up to run the W3ACT Export. This cron task should run hourly.

# The Website Stack

The [access_website stack](./website/docker-compose.yml) runs the services that actually provide the end-user website for https://www.webarchive.org.uk/ or https://beta.webarchive.org.uk/ or https://dev.webarchive.org.uk.

## Deployment

The stack is deployed using:

    cd website/
    ./deploy-access-website.sh dev

As with the data stack, this script must be setup for the variations across deployment contexts. For example, DEV version is password protected and it configured to pick this up from our internal repository. 

**NOTE** that this website stack generates and caches images of archived web pages, and hence will require a reasonable amount of storage for this cache (see below for details).

### NGINX Proxies

The website is designed to be run behind a boundary web proxy that handles SSL etc.  To make use of this stack of services, the server that provides e.g. `dev.webarchive.org.uk` will need to be configured to point to the right API endpoint, which by convention is `website.dapi.wa.bl.uk`.

The set of current proxies and historical redirects associated with the website are now contained in the [internal nginx.conf](./config/nginx.conf). This sets up a service on port 80 where all the site components can be accessed. Once running, the entire system should be exposed properly via the API gateway. For example, for accessing the dev system we want `website.dapi.wa.bl.uk` to point to `dev-swarm-members:80`.

Because most of the complexity of the NGINX setup is in the internal NGINX, the proxy setup at the edge is much simpler. e.g. for DEV:

```
    location / {
        # Used to tell downstream services what external host/port/etc. is:
        proxy_set_header        Host                    $host;
        proxy_set_header        X-Forwarded-Proto       $scheme;
        proxy_set_header        X-Forwarded-Host        $host;
        proxy_set_header        X-Forwarded-Port        $server_port;
        proxy_set_header        X-Forwarded-For         $remote_addr;
        # Used for rate-limiting Mementos lookups:
        proxy_set_header        X-Real-IP               $remote_addr;
        proxy_pass              http://website.dapi.wa.bl.uk/;
    }
```

(See the `dev_443.conf` setup for details.)

Having set this chain up, if we visit e.g. `dev.webarchive.org.uk` the traffic should show up on the API server as well as the Docker container.

**NOTE** that changes to the internal NGINX configuration are only picked up when it starts, so necessary to run:

    docker service update --force access_website_nginx

After which NGINX should restart and pick up any configuration changes and re-check whether it can connect to any proxied services inside the stack.

## Components

Behind the NGINX, we have a set of modular components:

- The [ukwa-ui](https://github.com/ukwa/ukwa-ui) service that provides the main user interface.
- The [ukwa-pywb](https://github.com/ukwa/ukwa-pywb) service that provides access to archive web pages
- The [mementos](https://github.com/ukwa/mementoweb-webclient) service that allows users to look up URLs via Memento.
- The [shine](https://github.com/ukwa/shine) and shinedb services that provide our older prototype researcher interface.
- The [ukwa-access-api](https://github.com/ukwa/ukwa-access-api) and related services (pywb-nobanner, webrender-api, Cantaloupe) that provide API services.
  - The API services include a caching image server ([Cantaloupe](https://cantaloupe-project.github.io/)) that takes rendered versions of archived websites and exposes them via the standard [IIIF Image API](https://iiif.io/api/image/2.1/). This will need substantial disk space (~1TB).

### Shine Database

Shine requires a PostgreSQL database, so additional setup is required using the scripts in [./scripts/postgres](./scripts/postgres).

#### Stop the Shine service

When modifying the database, and having deployed the stack, you first need to stop Shine itself from running, as otherwise it will attempt to start up and will insert and empty database into PostgreSQL and this will interfere with the restore process. So, use

    $ docker service scale access_website_shine=0

This will drop the Shine service but leave all the rest of the stack running. 

#### Creating the Shine database

* `create-db.sh`
* `create-user.sh`
* `list-db.sh`

Within `scripts/postgres/`, you can run `create-db.sh` to create the database itself. Then, run `create-user.sh` to run the `setup_user.sql` script and set up a suitable user with access to the database. Use `list-db.sh` to check the database is there at this pont.

#### Restoring the Shine database from a backup

* Edit `download-shine-db-dump.sh` to use the most recent date version from HDFS
* `download-shine-db-dump.sh`
* `restore-shine-db-from-dump.sh`

To do a restore, you need to grab a database dump from HDFS. Currently, the backups are dated and are in the HDFS `/2_backups/access/access_shinedb/` folder, so you'll need to edit the file to use the appropriate date, then run `download-shine-db-dump.sh` to actually get the database dump. Now, running `restore-shine-db-from-dump.sh` should populate the database.

#### Restart the Shine service

Once you have created and restored the database as needed, re-scale the service and Shine will restart using the restored database.

    $ docker service scale access_website_shine=1

#### Creating a backup of the Shine database

An additional helper script will download a dated dump file of the live database and push it to HDFS, `backup-shine-db-to-hdfs.sh`.

     ./backup-shine-db-to-hdfs.sh dev

This should be run daily.

## Cron Jobs

There should be a daily (early morning) backup of the Shine database.

# The Website Regression Test Stack

A series of tests for the website are held under the `tests` folder.  As well as checking service features and critical APIs, these test also cover features relating legal compliance.

The tests are defined as [Robot Framework](https://robotframework.org/) acceptance tests. In the [`tests/robot/tests`](./tests/robot/tests) we have a set of `.robot` files that define tests for each major web site feature (e.g. [Wayback](./tests/robot/tests/wayback.robot)). The tests are written in an [pseudo-natural-language tabular format](https://robotframework.org/robotframework/latest/RobotFrameworkUserGuide.html#test-case-syntax), relying heavily on [web testing automation keywords](https://robotframework.org/SeleniumLibrary/SeleniumLibrary.html) provided by the [Robot Framework Selenium Library](https://github.com/robotframework/SeleniumLibrary).

Here's an example of a simple test sequence...

```
Open Browser
    Open Browser To Home Page

Check Wayback EN Home Page
    [Tags]  wayback locale en
    Go To    %{HOST}/wayback/en
    Page Should Contain    UK Web Archive Access System
```

The first test (`Open Browser`) uses the `Open Browser To Home Page` keyword, which we've defined in the shared [`_resource.robot`](./tests/robot/tests/_resource.robot) file. This sets up the right test browser with the right configuration for the tests in this file (when developing tests, take care to ensure that `Open Browser` is _only_ called once per test file. It tends to hang if it's called multiple times). The next test (`Check Wayback EN Home Page`) loads the English-language Wayback homepage and checks the page contains a particular text string (n.b. matching is case-sensitive).

This provides a simple language for describing the expected behaviour of the site, and makes it easy to add further tests.  By putting the host name in an environment variable (referenced as `%{HOST}`), we can run the same test sequence across `HOST=https://www.webarchive.org.uk`, `HOST=https://beta.webarchive.org.uk` or even `HOST=https://username:password@dev.webarchive.org.uk`.

The deployment script can be run like this:

    cd website_tests
    ./deploy-website-tests.sh dev

The script handles setting up the `HOST` based on the deployment context.

The stack will spin up the necessary Selenium containers (with the [Selenium Hub](https://www.guru99.com/introduction-to-selenium-grid.html) exposed on port 4444 in case you want to take a look), and then run the tests.  The results will be visible in summary in the console, and in detail via the `results/report.html` report file.  If you hit errors, the system should automatically take screenshots so you can see what the browser looked like at the point the error occured.

The tests are run once on startup, and results are posted to Prometheus.  Following test runs can be orchestrated by using cron to run:

    docker service update --force access_website_tests_robot

These can be run each morning, and the metrics posted to Prometheus used to track compliance and raise alerts if needed.

## Cron Jobs

There should be a Daily (early morning) run of the website tests.


# The Reading Room Wayback Stack

The `rrwb` stack defines the necessary services for running our reading room access services via proxied connections rather than DLS VMs. This new approach is on hold at present.


# Monitoring

Having deployed all of the above, the cron jobs mentioned above should be in place.

The `ukwa-monitor` service should be used to check that these are running, and that the W3ACT database export file on HDFS is being updated.

...monitoring setup TBC...
