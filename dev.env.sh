# Define which container image to use:
export TASK_IMG="ukwa/ukwa-manage:latest"

# Specify IP addresses of the NameNode and JobTracker:
export NN_IP=192.168.1.103
export JT_IP=192.168.1.104

# Specify which TrackDB to use:
export TRACKDB_URL="http://trackdb.dapi.wa.bl.uk/solr/tracking"
#export TRACKDB_URL="http://192.168.45.21:8983/solr/tracking"

# Specify which Solr cluster to use:
export SOLR_ZKS="dev-zk1:2182,dev-zk2:2182,dev-zk3:2182"

# Specify which CDX service and collection to use:
export CDX_SERVICE="http://cdx.dapi.wa.bl.uk" 
export CDX_COLLECTION="test-collection"
