#!/bin/sh
set -e
ENVFILE=$1
DEBUG=


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
for _d in ${HERITRIX_OUTPUT_PATH} ${HERITRIX_WREN_PATH} ${SURTS_NPLD_PATH} ${SURTS_BYPM_PATH} ${NPLD_STATE_PATH} ${BYPM_STATE_PATH} ${CDX_STORAGE_PATH} ${TMP_WEBRENDER_PATH} ${PROMETHEUS_DATA_PATH} ${WARCPROX_PATH}; do
	[[ ${DEBUG} ]] && echo -e "DEBUG]\t _d:\t [${_d}]"
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

# start FC crawler stack
docker stack deploy -c ../fc-crawl/docker-compose.yml fc_crawl
