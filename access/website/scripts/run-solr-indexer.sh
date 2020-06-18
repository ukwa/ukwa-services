#!/usr/bin/env bash

# Fail on errors:
set -e

# Common vars - TRACKDB_URL, TASK_IMG, SOLR_ZKS, SHARED all required:
export DIR=$(dirname "$0")
source ${DIR}/task.env.sh
if [[ -z ${TRACKDB_URL} || -z ${TASK_IMG} || -z ${SOLR_ZKS} ]]; then
	echo "ERROR: Common vars undefined"
	exit 1
fi
if ! [[ -d ${SHARED} ]]; then
	echo "ERROR: Shared directory missing [${SHARED}]"
	exit 1
fi
if ! [[ -e ${SHARED}/warc-npld.conf && -e ${SHARED}/annotations.json && -e ${SHARED}/allows.txt ]]; then
	echo "ERROR: Required shared files missing"
	exit 1
fi

# Specific vars:
while getopts "s:y:c:h" flag; do
	case "${flag}" in
	's')	STREAM=${OPTARG} ;;
	'y')	YEAR=${OPTARG} ;;
	'c')	SOLR_COLLECTION=${OPTARG} ;;
	'h')	echo "Script $0 options - all required"
		echo "  -s Stream name - either 'frequent', 'domain' or 'webrecorder'"
		echo "  -y Year"
		echo "  -c Solr collection name"
		echo 
		exit 1 ;;
	esac
done

# Test specific arguments:
if ! [[ ${STREAM} == 'frequent' || ${STREAM} == 'domain' || ${STREAM} == 'webrecorder' ]]; then
	echo "ERROR: Stream name must be either 'frequent', 'domain' or 'webrecorder' - got [${STREAM}]"
	exit 1
fi
if ! [[ ${YEAR} =~ ^[[:digit:]]+$ ]]; then
	echo "ERROR: Year value must be numeric - got [${YEAR}]"
	exit 1
fi
case "${SOLR_COLLECTION}" in
fc2019)	;;
*)		echo "ERROR: Solr collection argument [${SOLR_COLLECTION}] not recognised"
		exit 1 ;;
esac


# Prepare lock file for file descriptor:
LOCKFILE="/var/tmp/`basename $0`.lock"
touch $LOCKFILE
unset lockfd

(
    # Check lock and exit if locked:
    flock -n ${lockfd}|| { echo "ERROR: $(basename $0) is already running!"; exit 1; }

    echo "Solr indexing WARCs from ${TRACKDB_URL} for ${STREAM} ${YEAR} and using ${TASK_IMG}, into ${SOLR_ZKS}/${SOLR_COLLECTION}..."
#    docker run -i -v ${SHARED}:/shared ${TASK_IMG} windex solr-index \
#        --trackdb-url ${TRACKDB_URL} \
#        --stream ${STREAM} \
#        --year ${YEAR} \
#        --solr-collection ${SOLR_COLLECTION} \
#        --zks ${SOLR_ZKS} \
#        --batch-size 1000 \
#        /shared/warc-npld.conf \
#        /shared/annotations.json \
#        /shared/allows.txt
) {lockfd}< $LOCKFILE


# Remove lock file
rm -f ${LOCKFILE}
