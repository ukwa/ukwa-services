# ukwa-services <!-- omit in toc -->

- [Introduction](#introduction)
- [Structure](#structure)
- [Deployment Process](#deployment-process)

## Introduction

Deployment configuration for all UKWA services stacks.

These [Docker Stack](https://docs.docker.com/engine/reference/commandline/stack/) configurations and related scripts are used to launch and manage our main services.  No internal or sensitive data is kept here -- that is stored in internal `ukwa-services-env` repository and pulled in when needed.

See the [change log](./CHANGELOG.md) for information on how this setup has changed over time.

## Structure

Service stacks are grouped by broad service area, e.g. `access/website` is the service stack that provides the public website part of our access system.

Within each stack folder, we should have a single `docker-compose.yml` file which should be used for all deployment contexts (`dev`,`beta` and `prod`). Any necessary variations should be defined via environment variables.

These variables, any other context-specific configuration, should be held in `dev`,`beta` and `prod` subdirectories. For example, if `access/website/docker-compose.yml` is the main stack definition file, any addtional services needed only on `dev` might be declared in `access/website/dev/docker-compose.yml` and would be deployed separately.

## Deployment Process

First, individual components should be developed and tested on developers' own machines/VMs, using the [Docker Compose](https://docs.docker.com/compose/compose-file/) files within each tool's repository. e.g.

- [w3act](https://github.com/ukwa/w3act/blob/master/docker-compose.yml)
- [crawl-log-viewer](https://github.com/ukwa/crawl-log-viewer#local-development-setup)

These are are intended to be self-contained. i.e. if possible should not depend on external services, but use dummy ones populated with test data.

Once a new version of a component is close to completion, we will want to run then against internal APIs for integration testing and/or user acceptance testing, and that's what the files in this repository are for. A copy of this repository is available on the shared storage of the DEV Swarm, and that's where new builds of versions of containers should be tested.

Once we're happy with the set of Swarm stacks, we can tag the whole configuration set for release through BETA and then to PROD.

Whoever is performing the roll-out will then review the tagged `ukwa-services` configuration:

- check they understand what has been changed, which should be indicated in the [change log](./CHANGELOG.md)
- review setup, especially the prod/beta/dev-specific configurations, and check they are up to date and sensible
- check no sensitive data or secrets have crept into this repository (rather than `ukwa-services-env`)
- check all containers specify a tagged version to deploy
- check the right API endpoints are in us
- run any tests supplied for the component

