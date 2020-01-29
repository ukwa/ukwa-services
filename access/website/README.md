The Access Stack <!-- omit in toc -->
================

- [Introduction](#introduction)
- [Deployment Procedures](#deployment-procedures)
  - [Shine Database](#shine-database)
  - [Setting up api endpoints](#setting-up-api-endpoints)
  - [Setting up X.webarchive.org.uk](#setting-up-xwebarchiveorguk)
- [Testing](#testing)

Introduction
------------

This stack contains the components used for general, public access to our web archives. i.e.

https://www.webarchive.org.uk/

See the comments in [the stack definition](./docker-compose.yml) for details.

Deployment Procedures
---------------------

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

A series of tests for the website are held under the `tests` folder.  These are defined as [Robot Framework](https://robotframework.org/) acceptance tests. In the [`tests/robot/tests`](./tests/robot/tests) we have a set of `.robot` files that define tests for each major web site feature (e.g. [Wayback](./tests/robot/tests/wayback.robot)). The tests are written in an pseudo-natural-language format, relying heavily on [web testing automation keywords](https://robotframework.org/SeleniumLibrary/SeleniumLibrary.html) provided by the [Robot Framework Selenium Library](https://github.com/robotframework/SeleniumLibrary).

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

To run the test suite, you need to use the supplied [Docker Compose](https://docs.docker.com/compose/) file to set up the [Selenium service](https://github.com/SeleniumHQ/docker-selenium#selenium-docker) and build and run the test system.  First, set the `HOST` environment variable. e.g.

    export HOST=https://www.webarchive.org.uk

Then build a Robot Framework container that includes the Selenium library:

    docker-compose build robot

Now to run the test suite, you can run:

    docker-compose run robot

The system will spin up the necessary Selenium containers (with the [Selenium Hub](https://www.guru99.com/introduction-to-selenium-grid.html) exposed on port 4444 in case you want to take a look), and then run the tests.  The results will be visible in summary in the console, and in detail via the `results/report.html` report file.  If you hit errors, the system should automatically take screenshots so you can see what the browser looked like at the point the error occured.

Sometimes, the Selenium system can get a bit confused and requests start to 'hang'. In this case shutting down all the containers before the next run:

    docker-compose down

