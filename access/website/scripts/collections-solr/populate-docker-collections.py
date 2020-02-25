import requests
import json

with open('collections.json') as f:
    docs = json.load(f)

for doc in docs:
    r = requests.post("http://localhost:9020/solr/collections/update?wt=json", 
        headers={"Content-Type":"application/json"}, 
        data='{"add":{ "doc": %s,"boost":1.0,"overwrite":true, "commitWithin": 1000 }}' % json.dumps(doc))
    print(r.status_code, r.text)
