import requests
import json

# Get a copy of the collections Solr index
r = requests.get("http://192.168.45.25:9020/solr/collections/select?indent=on&q=*:*&wt=json&rows=10000000")
j = json.loads(r.text)
docs = j['response']['docs']
with open('collections.json','w') as f:
    json.dump(docs, f)

