   29  airflow variables set trackdb_url http://trackdb.dapi.wa.bl.uk/solr/tracking
   30  airflow variables set hadoop_namenode_ip 192.168.1.103
   31  airflow variables set hadoop_jobtracker_ip 192.168.1.104
   35  airflow variables set storage_path /mnt/nfs/data/airflow
   40  history | grep set
   41  history | grep set | grep variables
   42  history | grep set > dags/setup_dev_variables.sh
