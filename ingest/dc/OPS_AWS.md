# Setting up a AWS Cloud server for the Domain Crawl

When running the Domain Crawl on AWS, we need to:

Set nofile limit to 102400 and nproc to unlimited.
/etc/sysconfig/docker instead. Updated to OPTIONS="--default-ulimit nofile=51200:102400"

Log in as ec2-user and admin via sudo.

Drives

/opt/data/cdx gp2 SSD with io1 3000 IOPS (maybe up to 6000 later if it's the bottleneck).
/var/lib/docker? gp2 256gb volume, mounted at /var/lib/docker/
/heritrix/state grows in 5TB chunks (better performance)
/ukwa volume with setup on it?

/heritrix/scratch 500G, as listed
/heritrix/kafka 1TB, scaling to 4T later if needed.
/heritrix/output 5TB, scaling to 10T later if needed.
/opt/data/cdx 500GB, scaling to 1T later if needed.

As of September 29:

Filesystem Type Size Used Avail Use% Mounted on 
/dev/nvme0n1p1 ext4 89G 5.8G 83G 7% / 
/dev/nvme2n1p1 ext4 493G 1.4G 466G 1% /heritrix/scratch 
/dev/nvme5n1p1 ext4 496G 8.3G 462G 2% /opt/data/cdx 
/dev/nvme7n1p1 ext4 4.0T 378G 3.4T 10% /heritrix/kafka 
/dev/nvme8n1p1 ext4 9.9T 3.2T 6.2T 35% /heritrix/output 
/dev/nvme3n1p1 ext4 494G 602M 468G 1% /ukwa 
/dev/mapper/state-lv_state xfs 10T 941G 9.1T 10% 
/heritrix/state /dev/nvme1n1p1 ext4 251G 61M 239G 1% /var/lib/docker

Looking at the gp2 graph on his page: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebs-volume-types.html - it looks like the gp2 IOPS tops out at 5TB, so using 5TB chunks would maximise speed. 4TB is pretty darn close though.

Set up the domain name properly, i.e. BL points crawler07.bl.uk to cloud IP address, and it's registered with AWS so reverse lookups work.

Allow access to specific ports via the dedicated gatway server.

Custom TCP TCP 9000 194.66.232.85/32 kafka-ui
Custom TCP TCP 9191 194.66.232.85/32 prometheus
Custom TCP TCP 9094 194.66.232.85/32 kafka
SSH TCP 22 194.66.232.85/32 -
Custom TCP TCP 8443 194.66.232.85/32 -
Custom TCP TCP 9090 194.66.232.85/32 cdx
Custom TCP TCP 8484 194.66.232.85/32 h3-jmx

node_exporter

Federate metrics into Prometheus

Check surts and exclusions. 
Check GeoIP DB (GeoLite2-City.mmdb) is installed and up to date.

move-to-S3

JE cleaner threads
je.cleaner.threads to 16 (from the default of 1) - note large numbers went very badly causing memory exhaustion
Bloom filter
MAX_RETRIES=4

docker service update dc_crawl_cdxserver --log-driver json-file --log-opt max-size=1g

t3.2xlarge (32GB, 8vcpus, 5Gbe) 
m5.4xlarge (64GB, 16vcpus, 10Gbe)
m5.8xlarge with 32 vcpus and 128GB up to 10Gbe

