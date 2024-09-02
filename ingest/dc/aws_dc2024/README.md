Domain Crawl 2024
=================

This directory contains the settings and deployment scripts for the DC2024 operation on AWS.

Before running the deploy script:
- Copy a past .env file and edit the values for this server.
- Ensure that the new .env file name includes this server's name so that it can be easily identified.
- Ensure that the STORAGE_PATH directory in the .env file exists and is owned by this user (not root). If it doesn't, the server probably isn't ready for the domain crawl deployment.

When ready, run the deploy script with the new .env file as the argument. E.g.,:
* `./deploy_aws_dc_services.sh aws_dc2024_crawler08-prod.env`

