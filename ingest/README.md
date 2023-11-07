The Ingest Stacks <!-- omit in toc -->
=================

This section covers the service stacks that are used for curation and for crawling.

- [`w3act`](./w3act/) - where curators define what should be crawled, and describe what has been crawled.
- [`fc`](./fc/) - the Frequent Crawler, which crawls sites as instructed in `w3act`.
- [`dc`](./dc/) - the Domain Crawler, which us used to crawl all UK sites, once per year.

The [`crawl_log_db`](./crawl_log_db/) service is not in use, but contains a useful example of how a Solr service and it's associated schema can be set up using the Solr API rather than maintaining XML configuration files.
