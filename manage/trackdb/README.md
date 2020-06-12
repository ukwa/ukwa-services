TrackDB
=======


## Migrating data between TrackDB instances

As there is some quite useful status data in a live TrackDB instance, we might want to migrate it from older to newer instances.

First, ensure no TrackDB updates are running.

Then, we can download the contents of the TrackDB that we want to keep. e.g. this grabs all the data to do with WARCs.

     docker run -ti ukwa/ukwa-manage trackdb -i http://192.168.45.21:8983/solr/tracking warcs list -l 100000000 > tdb-warcs.jsonl

The number of lines in the output file should correspond to the number of entries in the TrackDB with `kind_s:"warcs"`.

This can then be imported into a new TrackDB instance:

    cat tdb-warcs.jsonl |  docker run -i ukwa/ukwa-manage trackdb -t http://trackdb.dapi.wa.bl.uk/solr/tracking warcs import -
