The Access Stacks <!-- omit in toc -->
=================

<!-- use the VS Code extension 'Markdown All In One' to keep this table up to date -->

- [Introduction](#introduction)
- [The Website Regression Test Stack](#the-website-regression-test-stack)
- [The Reading Room Wayback Stack](#the-reading-room-wayback-stack)

# Introduction

The [access_website stack](./website/) runs the services that actually provide the end-user website for https://www.webarchive.org.uk/ or https://beta.webarchive.org.uk/ or https://dev.webarchive.org.uk.

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


# The Reading Room Wayback Stack

The `rrwb` stack defines the necessary services for running our reading room access services via proxied connections rather than DLS VMs. This new approach is on hold at present.

