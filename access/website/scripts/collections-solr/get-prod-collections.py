import requests
import json

# Get a copy of the collections Solr index
r = reqeusts.get("http://192.168.45.25:9020/solr/collections/select?indent=on&q=*:*&wt=json&rows=10000000")
j = json.loads(r.text)
docs = j['response']['docs']
with open('collections.json','w') as f:
    json.dump(docs, f)

for doc in docs:
    requests.post("http://localhost:9020/solr/collections/update?wt=json", 
        headers={"Content-Type":"application/json"}, 
        data='{"add":{ "doc": %s,"boost":1.0,"overwrite":true, "commitWithin": 1000 }}' % json.dumps(doc))
