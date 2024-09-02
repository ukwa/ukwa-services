#!/bin/sh
set -e
ENVFILE=$1
DEBUG=


# functions ----------------
function test_env_file {
	# read environment file
	if [[ "${ENVFILE}" == "" ]]; then
		echo "ERROR: You must give an argument that specifies the deployment, e.g. aws_dc2024_crawler08-prod.env"
		exit 1
	fi
	if ! [[ -f ${ENVFILE} ]]; then
		echo "ERROR: argument [${ENVFILE}] environment file missing"
		exit 1
	fi
	source ./${ENVFILE}
}

function test_storage_path {
	# check STORAGE_PATH exists
	if !  [[ -d ${STORAGE_PATH} ]]; then
		echo "ERROR: STORAGE_PATH [${STORAGE_PATH}] defined in [${ENVFILE}] missing"
		exit 1
	fi
}

function make_directory {
	local _d=$1
        if [[ "${_d}" == "" ]]; then
                echo "ERROR: No directory defined - probably not set in ${ENVFILE}"
                exit 1
        fi
        if ! [[ -d ${_d} ]]; then
                echo -e "Making dir\t ${_d}"
                mkdir -p ${_d} || {
                        echo "ERROR: failed to make directory [${_d}]"
                        exit 1
                }
	else
		echo -e "${_d}\t already exists"
        fi
}


# script -------------------
test_env_file
test_storage_path

for _d in \
	${TMP_STORAGE_PATH} ${ZK_DATA_PATH} ${ZK_DATALOG_PATH} ${KAFKA_PATH} \
	${HERITRIX_OUTPUT_PATH} ${SURTS_NPLD_PATH} ${NPLD_STATE_PATH} \
	${CDX_STORAGE_PATH} ${PROMETHEUS_DATA_PATH} ${WARCPROX_PATH} \
	; do make_directory ${_d}
done
tree -d ${STORAGE_PATH}

# start FC kafka stack
#docker stack deploy -c ../fc-kafka/docker-compose.yml fc_kafka

wait
#sleep 10
docker service ls

