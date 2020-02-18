#!/bin/sh

# Common setup:
source ./common.env

#start postgres
$DOCKER_COMMAND down
$DOCKER_COMMAND up -d postgres
