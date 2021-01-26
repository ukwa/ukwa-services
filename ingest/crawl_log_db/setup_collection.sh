set -e

SOLR_URL=http://localhost:8913/solr
COLLECTION=crawl_log_fc_1
ALIAS=crawl_log_fc

echo "Create collection..."
curl "${SOLR_URL}/admin/collections?action=CREATE&name=${COLLECTION}&numShards=1&replicationFactor=1"


echo "Add fields..."
curl -X POST -H 'Content-type:application/json' --data-binary @schema_fields.json http://localhost:8913/solr/${COLLECTION}/schema

echo "Create alias 'crawl_log_fc'..."
curl "${SOLR_URL}/admin/collections?action=CREATEALIAS&name=${ALIAS}&collections=${COLLECTION}"

