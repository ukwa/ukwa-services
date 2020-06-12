TrackDB
=======

## Updating TrackDB with information from HDFS

To update TrackDB, we need to generate a file listing from HDFS and then import it. The [update-trackdb-from-hdfs.sh](./scripts/update-trackdb-from-hdfs.sh) script can update TrackDB based on a complete file listing:

    update-trackdb-from-hdfs.sh http://trackdb.dapi.wa.bl.uk/solr/tracking /

Or on just a subset of the files:

    update-trackdb-from-hdfs.sh http://trackdb.dapi.wa.bl.uk/solr/tracking /heritrix/output/frequent-npld

Which is much quicker and allows us to keep track of new items as they come in.

Note that the HDFS listing process needs the the `NAMENODE_IP` environment variable to be set.  See `~/gitlab/ukwa-services-env/hadoop.env` for an example.

## Migrating data between TrackDB instances

As there is some quite useful status data in a live TrackDB instance, we might want to migrate it from older to newer instances.

First, ensure no TrackDB updates are running.

Then, we can download the contents of the TrackDB that we want to keep. e.g. this grabs all the data to do with WARCs.

     docker run -i ukwa/ukwa-manage trackdb list -t http://192.168.45.21:8983/solr/tracking -l 100000000 warcs > tdb-warcs.jsonl

The number of lines in the output file should correspond to the number of entries in the TrackDB with `kind_s:"warcs"`.

This can then be imported into a new TrackDB instance:

    cat tdb-warcs.jsonl |  docker run -i ukwa/ukwa-manage trackdb import -t http://trackdb.dapi.wa.bl.uk/solr/tracking warcs -
