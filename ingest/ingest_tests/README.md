Ingest Tests
============

This is a system that is intended to be used to run tests on production systems and post the results to Prometheus. It is also designed to be run against near-production versions by changing the `TEST_HOST` environment variable, so that it can be used to verify that a new version of a service passes the tests ahead of deployment to production.

Most of the depenendencies are handled by `ukwa/robot-framework` docker image on which this relies. This ensure the additional libraries to run web browsers and talks to Prometheus are in place.  Specifically, the container includes [RequestsLibrary](https://marketsquare.github.io/robotframework-requests/doc/RequestsLibrary.html) for testing APIs, and the [robotframework-browser](https://robotframework-browser.org/) library (based on [Playwright](https://playwright.dev/)) and  [SeleniumLibrary](http://robotframework.org/SeleniumLibrary/) for browser-driven tests. The Playwright-based library is a bit simpler to deploy than the Selenium-based on, so tests should be switched over to the former where possible.

The `deploy-ingest-tests.sh` shows how the script can be run as a Docker Service.  However, when developing tests, it can be easier to set up the necessary environment variables and run the tests using Docker Compose. e.g.

Set up the environment variables for running tests against the DEV service:

    source /mnt/nfs/config/gitlab/ukwa-services-env/dev.env

And now run the tests:

    docker-compose run robot

Which runs the tests and reports to the console, rather than running them as a background service (as `deploy-ingest-tests.sh` would).

Using Docker avoids having to install dependencies. If using Docker is not an option, you could set up a Python virtual environent and install `robotframework-requests` and `robotframework-browser`, the run the tests like this:

    robot --outputdir /results /tests

Once the tests have run, the results of the tests will be in the `results` folder. This is very detailed, and the system will capture screenshots when things go wrong, so this can all be very useful for determining the cause of test failure.

