workspace "DC on AWS" "Deployment details for UKWA domain crawl on the AWS cloud" {
    model {
    
        staff = person "Staff" "" ""
        
        ukweb = softwaresystem "Websites" "" ""
        
        dcKafka = softwaresystem "DC Kafka Stack" "Manages crawl seed URLs and logs" "Docker Stack" {
            kafka = container "Kafka" "" ""
            kafkaUi = container "Kafka UI" "http://crawler07.bl.uk:9000/" "" {
                url "http://crawler07.bl.uk:9000/"
            }
            kafkaZk = container "Zookeeper" "" ""
        }
        kafka -> kafkaZk "Zookeeper Coordination" "" ""
        kafka -> kafkaUi "Kafka Status" "" ""
        
        dcCrawl = softwaresystem "DC Crawler Stack" "Crawls UK web sites and downloads URIs" "Docker Stack" {
            crawler = container "Heritrix3" "Web Crawler - https://crawler07.bl.uk:8443/" "Java Spring" {
                url "https://crawler07.bl.uk:8443/"
            }
            clams = container "ClamAV" "Scan crawled content for viruses" ""
            ocdx = container "OutbackCDX" "Record crawled URLs and outcome - http://crawler07.bl.uk:9090/" "Java" {
                url "http://crawler07.bl.uk:9090/"
            }
            prom = container "Prometheus" "Record metrics for monitoring and alerts - http://crawler07.bl.uk:9191/" "" {
                url "http://crawler07.bl.uk:9191/"
            }
        }
        crawler -> ukweb "Download UK web pages." "HTTP(S)"
        crawler -> kafka "URLs crawled." "Kafka"
        kafka -> crawler "URLs to crawl." "Kafka"
        crawler -> clams "Scan content for viruses." ""
        prom -> crawler "Collect crawler metrics" ""
        prom -> staff "Collect federated metrics" ""
        
        output = softwaresystem "EBS Output Volume" "Storage of WARCs, logs, etc." "Amazon Web Services - Elastic Block Store EBS Volume"
        crawler -> output "Output WARCs and crawl logs." ""
        
        moveToS3 = softwaresystem "move-to-s3.py" "Upload WARCs and logs to S3" "Cron, Python"

        s3b = softwaresystem "Amazon S3 Bucket" "Long-term storage of crawl results" "Amazon Web Services - Simple Storage Service S3 Bucket"
        
        output -> moveToS3 "Find WARCs and logs"
        moveToS3 -> s3b "Move WARCs and logs to S3"
        
        staff -> crawler "Manage Crawls" "HTTPS"
        staff -> kafkaUi "Check Kafka" "HTTPS"

        deploymentEnvironment "Live" {
            deploymentNode "Public Internet" "" "" "" {
                websites = softwareSystemInstance ukweb
            }
            deploymentNode "Amazon Web Services" "" "" "Amazon Web Services - Cloud" {
                deploymentNode "EU-West-2" "" "" "Amazon Web Services - Region" {
                
                    deploymentNode "Static IP" "" "Registered as crawler07.bl.uk" "Amazon Web Services - EC2 Elastic IP Address" {

                        node = deploymentNode "Amazon EC2" "" "" "Amazon Web Services - EC2" {
                        
                            swarm = deploymentNode "Docker Swarm" "" "" "" {
                                dcc = softwareSystemInstance dcCrawl
                                dck = softwareSystemInstance dcKafka
                            }
                                
                            softwareSystemInstance output
                    
                            softwareSystemInstance moveToS3
                    
                        }
                    }
                    
                    softwareSystemInstance s3b
                    
                }
                
            }

            deploymentNode "BL Access Server" "" "" "BSP" {
                staffAccess = infrastructureNode "BL Staff" "" "Boston Spa"
            }
            
            staffAccess -> node "Connects to" "HTTP(S), SSH"
            
        }
    }
         
    views {
        systemlandscape "SystemLandscape" {
            include *
            autoLayout
        }
        
        deployment * "Live" "AmazonWebServicesDeployment" {
            include *
            autolayout lr
        }
        
        container dcCrawl "CrawlerContainers" {
            include *
            autoLayout
        }
        
        container dcKafka "KafkaContainers" {
            include *
            autoLayout
        }
        
        styles {
            element "Element" {
                shape roundedbox
                background #ffffff
            }
            element "Database" {
                shape cylinder
            }
            element "Infrastructure Node" {
                shape roundedbox
            }
        }

        themes https://static.structurizr.com/themes/amazon-web-services-2020.04.30/theme.json
    }
}

