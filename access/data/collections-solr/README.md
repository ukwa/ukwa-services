These scripts can download the collections from one Solr instance and import them into another.

You'll need the `requests` library installed.

Then
 

    python get-prod-collections.py > collections.json

Should download the contents. Then you can run:
    
    python populate-docker-collections.py

And that should submit the data to the Solr running on localhost:9020
