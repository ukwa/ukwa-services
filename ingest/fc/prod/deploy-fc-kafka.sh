#!/bin/sh
set -e
ENVFILE=$1
DEBUG=1


# read environment file
if [[ "${ENVFILE}" == "" ]]; then
	echo "ERROR: You must give an argument that specifies the deployment, e.g. crawler06 uses prod-env-crawler06.sh."
	exit 1
fi
if ! [[ -f ${ENVFILE} ]]; then
	echo "ERROR: argument [${ENVFILE}] environment file missing"
	exit 1
fi
source ./${ENVFILE}


# check STORAGE_PATH exists, create any missing sub-directories
if !  [[ -d ${STORAGE_PATH} ]]; then
	echo "ERROR: STORAGE_PATH [${STORAGE_PATH}] defined in [${ENVFILE}] missing"
	exit 1
fi
for _d in ${TMP_STORAGE_PATH} ${ZK_DATA_PATH} ${ZK_DATALOG_PATH} ${KAFKA_PATH}; do
	if [[ "${_d}" == "" ]]; then
		echo "ERROR: No directory defined"
		exit 1
	fi
	if ! [[ -d ${_d} ]]; then
		[[ ${DEBUG} ]] && echo -e "DEBUG]\t making dir [${_d}]"
		mkdir -p ${_d} || {
			echo "ERROR: failed to make directory [${_d}]"
			exit 1
		}
	fi
done


# start FC kafka stack
docker stack deploy -c ../fc-kafka/docker-compose.yml fc_kafka

wait
sleep 10
docker service ls
