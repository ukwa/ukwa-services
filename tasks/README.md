Tasks
=====

W3ACT Export:

- Get W3ACT Export lock.
- Check TrackDB task record is out-of date.
- Dump CSV
- Post-process CSV.
- Create Wayback ACL, annotations files, etc.
- Store the results, updating files in a fixed location.
- Record task as up-to-date in TrackDB.

CDX index some WARCs

- Get WARC CDX indexer lock.
- Get WARCs to process from TrackDB.
- Index them
- If it worked, record them as indexed in TrackDB.

Then:

- Get WARC index verification lock.
- Get WARCs to process from TrackDB.
- Check they are indexed.
- If it worked, record them verified in TrackDB.
- If it appears to have failed, knock them back to the un-indexed state.

Similarly,

- Get WARC Solr indexer lock.
- Get WARCs to process from TrackDB.
- Index them
- If it worked, record them as indexed in TrackDB.

HDFS Listing:

- Get HDFS lister lock.
- Check TrackDB task record is out-of-date.
- List all/some of HDFS.
- Post-process to annotate/classify.
- Store the results, updating the files in a fixed location.
- Update file-level TrackDB (Or as separate task)
- Record task as up-to-date in TrackDB.

Other Tasks:

- DB backup.
- Nominet download.
- Recently Crawled data export (currently a Kafka client demon).
- Reports (dead seeds, etc.)
