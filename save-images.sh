#!/usr/bin/env bash
#
usage() {
  echo "Usage:
  $0 <private-registry-addr> <release-name>
  
  Prerequisite: docker login to both source and destination registry
  "
}

DIR=$(dirname $0)

SAVE_FILE=$1
RELEASE_NAME=$2

if [[ -z "${SAVE_FILE}" || -z "${RELEASE_NAME}" ]]; then
  usage
  exit 1
fi

IMAGES_LIST=${DIR}/releases/images-list-${RELEASE_NAME}
if [[ ! -f "${IMAGES_LIST}" ]]; then
  usage
  echo "ERROR: cannot file images list in ${IMAGES_LIST} "
  exit 1
fi


if [[ -n "${DRY_RUN}" ]]; then
  echo "DRY_RUN MODE"
  DOCKER="echo docker"
else
  DOCKER="docker"
fi

echo "Starting at $(date)"
echo "
IMAGES_LIST=$IMAGES_LIST
JOURNAL_DIR = $JOURNAL_DIR
DONE_DIR = $DONE_DIR
"


SAVE_LIST=""
while read line
do
  [[ -z $line ]] && continue
  PULL_IMAGE=$line
  SAVE_LIST+="$PULL_IMAGE "
done < $IMAGES_LIST

echo "Save List = $SAVE_LIST"
$DOCKER save -o $SAVE_FILE $SAVE_LIST 

echo "Completed at $(date) "

