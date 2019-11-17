#!/usr/bin/env bash
#
usage() {
  echo "Usage:
  $0 <private-registry-addr> <release-name>
  
  Prerequisite: docker login to both source and destination registry
  "
}

DIR=$(dirname $0)

PRIVATE_REGISTRY_ADDR=$1
RELEASE_NAME=$2

if [[ -z "${PRIVATE_REGISTRY_ADDR}" || -z "${RELEASE_NAME}" ]]; then
  usage
  exit 1
fi

IMAGES_LIST=${DIR}/releases/images-list-${RELEASE_NAME}
if [[ ! -f "${IMAGES_LIST}" ]]; then
  usage
  echo "ERROR: cannot file images list in ${IMAGES_LIST} "
  exit 1
fi

JOURNAL_DIR=${JOURNAL_DIR:-$DIR/journal/$(date "+%Y-%m-%d_%H%M%S")}
mkdir -p $JOURNAL_DIR 
DONE_FILE=$JOURNAL_DIR/done
ERRORS_FILE=$JOURNAL_DIR/errors

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

DONE_COUNT=0
ERROR_COUNT=0
# there are 3 types of image names:
# 1. non-codefresh like "bitnami/mongo:123" - convert to "private-registry-addr/bitnami/mongo:123"
# 2. codefresh public images like "codefresh/engine:123" - convert to "private-registry-addr/codefresh/mongo:123"
# 3. codefresh private images like gcr.io/codefresh-enterprise/codefresh/cf-api:cf-onprem-v1.0.86 - will be convert to "private-registry-addr/codefresh/mongo:123
DELIMITER='codefresh/'
cat ${IMAGES_LIST} | while read line
do
  PULL_IMAGE=$line
  PUSH_IMAGE=$(echo $PULL_IMAGE | awk -F"${DELIMITER}" -vPRIVATE_REGISTRY_ADDR=${PRIVATE_REGISTRY_ADDR} \
      '{if($2 == ""){print PRIVATE_REGISTRY_ADDR"/"$1}  else {print PRIVATE_REGISTRY_ADDR"/codefresh/"$2}}')
  echo "$PULL_IMAGE    ->    $PUSH_NAME "

  PULL_COMMAND="$DOCKER pull $PULL_IMAGE"
  TAG_COMMAND="$DOCKER tag $PULL_IMAGE $PUSH_IMAGE"
  PUSH_COMMAND="$DOCKER push $PUSH_IMAGE"

  echo "---------- Migrate $PULL to $PUSH"
  eval $PULL_COMMAND && echo -e "Pull $PULL_IMAGE completed - $(date) !!!\n" && \
  eval $TAG_COMMAND && echo -e "Tag $PUSH_IMAGE completed - $(date) !!!\n" && \
  eval $PUSH_COMMAND && echo -e "Push $PUSH_IMAGE completed - $(date) !!!\n"

  if [[ $? == 0 ]]; then
    echo "$PUSH_IMAGE" >> $DONE_FILE
    (( DONE_COUNT++ ))
  else
    echo "ERROR - $PULL_IMAGE to $PUSH_IMAGE" >> $ERRORS_FILE
    (( ERROR_COUNT++ ))
  fi

done

echo "Completed at $(date) "
echo "Done $DONE_COUNT images - see $DONE_FILE "
if [[ ERROR_COUNT -gt 0 ]]; then
  echo "There are $ERROR_COUNT error - see $ERRORS_FILE "
fi

