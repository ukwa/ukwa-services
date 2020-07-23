Intranet
========

The Intranet service stack provides a set of internal interfaces for diagnosis and reporting. There are a set of static web pages provided by the `ukwa-reports` service, and these provide a 'gateway' to other systems.

Static Non-Sensitive Content
----------------------------

All normal reports should be built via `ukwa-reports` as static pages, with regular reports (e.g. monthly, daily) being published as separate posts. This means we can present them easily as if they were blog posts.  These pages should generally be built using Jupyter notebooks, invoked as Luigi tasks, under the `ukwa-manage` project. These tasks may generate Markdown or HTML (the latter likely using the notebook output itself) and should commit the results to the `ukwa-reports` git repository as 'page bundles', and push them to GitHub.

If appropriate, in-browser JavaScript visualisations may be created on e.g. glitch.com and imported into `ukwa-reports` as a git submodule.

When any updates are made to `ukwa-reports`, the latest container image will be deployed automatically by [Ouroboros](https://github.com/pyouroboros/ouroboros).


Dynamic or Sensitive Content
----------------------------

Any interactive or sensitive reports should be implemented as Jupyter notebooks, and hosted via the [ukwa-notebook-apps](https://github.com/ukwa/ukwa-notebook-apps) service that uses [Voila](https://github.com/voila-dashboards/voila).

Some things are difficult to implement as notebooks, so get deployed as individual services:

- A [crawl log viewer](https://github.com/ukwa/crawl-log-viewer) for accessing the crawl logs stored in Kafka so we can diagnose crawler problems.
- A [faceted browser](https://github.com/ukwa/ukwa-backstage) for exploring our records.
- An [API service](https://github.com/ukwa/ukwa-access-api) (and associated subcomponents), for integration with other systems. Among other things, the API provides the system for retrieving or generating screenshots of archived pages.  It is a copy of the service intended to act as the public API, but being internal-facing, has greater access to content.
