# Define which container image to use:
export TASK_IMG="anjackson/ukwa-manage:trackdb-lib"

# Specify IP addresses of the NameNode and JobTracker:
export NN_IP=192.168.1.103
export JT_IP=192.168.1.104

# Specify which TrackDB to use:
#export TRACKDB_URL="http://trackdb.dapi.wa.bl.uk/solr/tracking"
export TRACKDB_URL="http://192.168.45.21:8983/solr/tracking"
