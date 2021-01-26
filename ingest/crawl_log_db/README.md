Crawl Log DB
============

The idea is to run a database of recent crawl log data, so we can see what's been going on. The log data could come from Kafka and/or the crawl log files and/or direct from Heritrix.

This database is implemented as a SolrCloud collection. Using SolrCloud mode means the service will support the SQL query mode.

For development, the scripts here can run a suitable SolrCloud server, setup the `crawl_log_fc` alias of a `crawl_log_fc_1` collection and add field definitions using Solr's Schema API. Using aliases means we can add and remove collections over time and so keep the size of the database manageable over time.

The clients should use `<CRAWL_TIMESTAMP>:<URL>` as the record ID and send all data [as updates](https://lucene.apache.org/solr/guide/6_6/updating-parts-of-documents.html). As the ID parameters are fixed by Heritrix, this means we can update the fields from multiple sources, or the same source multiple times, and the results will be stable and correct (i.e. consistent and idempotent). _This is the TrackDB way._

