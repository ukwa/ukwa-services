The Access Stack <!-- omit in toc -->
================

- [Introduction](#introduction)
  - [The Access Data Stack](#the-access-data-stack)
    - [W3ACT Exports](#w3act-exports)
    - [Crawl Log Analyser](#crawl-log-analyser)
  - [The Website Stack](#the-website-stack)
    - [NGINX Proxy](#nginx-proxy)
    - [Website Services](#website-services)
    - [Shine Database](#shine-database)
  - [The Website Regression Test Stack](#the-website-regression-test-stack)
  - [The Reading Room Wayback Stack](#the-reading-room-wayback-stack)

# Introduction

This folder contains the components used for access to our web archives. There are a number of separate service stacks outlined in the following sections.

## The Access Data Stack

The other access services depend on a number of data sources and the Access Data Stack handles those. The [access_data stack definition](./data/docker-compose.yml) describes data volumes as well as services that the other stacks can refer to.

The stack is deployed using:

    cd data
    ./deploy-access-data.sh dev

The shell script sets up the right environment variables for each context (dev/beta/prod) before launching the services.

### W3ACT Exports

The `w3act_export` service downloads the regular W3ACT database dump from HDFS (`/9_processing/w3act/w3act-db-csv.zip`) and uses it to generate the data sources the rest of the stack needs.  The service runs once when the stack is deployed or when it is updated. Regular updates can be orchestrated by using cron to run:

    docker service update --force access_data_w3act_export

The outputs of the `w3act_export` service are placed on a volume called `access_data_w3act_export`. If all goes well, this should include:

- The `allows.aclj` and `block.aclj` files needed by the [pywb access control system](https://github.com/ukwa/ukwa-pywb/blob/master/docs/access_controls.md#access-control-system).  The `allows.aclj` file is generated from the data in W3ACT, based on the license status. The `blocks.aclj` file is managed in GitLab, and is downloaded from there.
- The `allows.txt` and `annotations.json` files needed for full-text Solr indexing.
 
The service also populates the secondary Solr collection used to generate the _Topics & Themes_ pages of the UKWA website.  The Solr instance and schema is managed as a Docker container in this stack.

TODO: On completing these tasks, the service sends metrics to Prometheus for monitoring (TBA).

### Crawl Log Analyser

... TBA...

## The Website Stack

The [access_website stack](./website/docker-compose.yml) runs the services that actually provide the end-user website for https://www.webarchive.org.uk/ or https://beta.webarchive.org.uk/ or https://dev.webarchive.org.uk.

The stack is deployed using:

    ./deploy-access-website.sh dev

### NGINX Proxy

The website is designed to be run behind a boundary web proxy that handles SSL etc.  To make use of this stack of services, the server that provides e.g. `dev.webarchive.org.uk` will need to be configured to point to the right API endpoint, which by convention is `website.dapi.wa.bl.uk`.

The set of current proxies and historical redirects associated with the website are now contained in the [internal nginx.conf](./config/nginx.conf). This sets up a service on port 80 where all the site components can be accessed. Once running, the entire system should be exposed properly via the API gateway. For example, for accessing the dev system we want `website.dapi.wa.bl.uk` to point to `dev-swarm-members:80`.

Having set this chain up, if we visit e.g. `dev.webarchive.org.uk` the traffic should show up on the API server as well as the Docker container.

### Website Services

- The ukwa-ui service
- The ukwa-pywb service
- The mementos service
- The shine and shinedb services
- The api and related services (pywb-nobanner and webrender-api)

### Shine Database

Shine requires a PostgreSQL database, so additional setup is required using the scripts in [./scripts/postgres](./scripts/postgres).

If starting from a new deployment, and having deployed the stack, you first need to stop Shine itself from running, as otherwise it will attempt to start up and will insert and empty database into PostgreSQL and this will interfere with the restore process. So, use

    $ docker service rm website_shine

Now you can run `create-db.sh` to create the database itself, and you can use `list-db.sh` to check the database is there. Then, run `create-user.sh` to run the `setup_user.sql` script and set up a suitable user with access to the database.  

To do a restore, use `download-shine-db-dump.sh` to grab a database dump from HDFS, but you'll need to edit the file to select the backup with a given date. Now, running `restore-shine-db-from-dump.sh` should populate the database.

Re-deploy the whole service stack, and Shine will restart using the restored database.


## The Website Regression Test Stack

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

## The Reading Room Wayback Stack

The `rrwb` stack defines the necessary services for running our reading room access services via proxied connections rather than DLS VMs. This new approach is on hold at present.