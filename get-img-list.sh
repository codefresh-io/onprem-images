#!/bin/bash

while [[ $1 =~ ^(--(repo|version|show-digests|gcr-sa)) ]]
    do
        key=$1
        value=$2
        case $key in
            --repo)
                REPO_CHANNEL="$value"
                shift
            ;;
            --version)
                ONPREM_VERSION="--version $value"
                shift
            ;;
            --show-digests)
                SHOW_DIGESTS="true"
            ;;
            --gcr-sa)
                GCR_SA_FILE="$value"
            ;;
        esac
        shift
    done

set -eou pipefail

REPO_CHANNEL=${REPO_CHANNEL:-"prod"}
CHART=codefresh-onprem-${REPO_CHANNEL}/codefresh
ONPREM_CHART_NAME=codefresh
RUNNER_CHART=cf-runtime/cf-runtime
ONPREM_VERSION=${ONPREM_VERSION:-""}
SHOW_DIGESTS=${SHOW_DIGESTS:-"false"}
SKOPEO_IMAGE="quay.io/codefresh/skopeo"
SKOPEO_CONTAINER="cf-skopeo"
NEW_LINE=$'\n'

HELM_VALS="--set global.seedJobs=true --set global.certsJobs=true --set cf-oidc-provider.enabled=true"
RUNNER_HELM_VALS="--set appProxy.enabled=true --set monitor.enabled=true"

ALL_VALUES_TEMPLATE=$(cat <<-END
{{ .Values | toYaml }}
END
)

function outputValues() {
    echo $ALL_VALUES_TEMPLATE > $LOCAL_CHART_PATH/$ONPREM_CHART_NAME/templates/all-values.yaml
    helm template --show-only templates/all-values.yaml $LOCAL_CHART_PATH/$ONPREM_CHART_NAME > $LOCAL_CHART_PATH/output-values.yaml
    rm $LOCAL_CHART_PATH/$ONPREM_CHART_NAME/templates/all-values.yaml
}

function getHelmReleaseImages() {
    helm template $LOCAL_CHART_PATH/$ONPREM_CHART_NAME ${HELM_VALS} --disable-openapi-validation | grep -E 'image:' | awk -F ': ' '{print $2}' | tr -d '"' | tr -d ',' | cut -f1 -d"@" | sort -u
}

function getRuntimeImages() {

    RUNTIME_IMAGES=(
        ENGINE_IMAGE
        DIND_IMAGE
        CONTAINER_LOGGER_IMAGE
        DOCKER_PUSHER_IMAGE
        DOCKER_TAG_PUSHER_IMAGE
        DOCKER_PULLER_IMAGE
        DOCKER_BUILDER_IMAGE
        GIT_CLONE_IMAGE
        COMPOSE_IMAGE
        KUBE_DEPLOY
        FS_OPS_IMAGE
        TEMPLATE_ENGINE
        PIPELINE_DEBUGGER_IMAGE
    )

    cat $LOCAL_CHART_PATH/output-values.yaml | grep -E "$(printf '%s|' "${RUNTIME_IMAGES[@]}" | sed 's/|$//')" | tr -d '"' | tr -d ',' | awk -F ": " '{print $2}' | sort -u
}

# function getRunnerImages() {
#     helm template ${RUNNER_LOCAL_CHART_PATH}/* ${RUNNER_HELM_VALS} --disable-openapi-validation | grep 'image:' | awk -F 'image: ' '{print $2}' | tr -d '"' | cut -f1 -d"@" | sort -u
# }

function getImages() {
    outputValues
    getHelmReleaseImages
    getRuntimeImages
}

function getDigest() {
   local manifest
   local digest

   digest=$(docker exec $SKOPEO_CONTAINER skopeo inspect docker://$1 --format {{.Digest}} 2>&1)
   if [[ "$?" == "1" ]]; then
        echo "Error: $digest"
        return
   fi

   echo $digest
}

function printImage() {
    if [[ "$SHOW_DIGESTS" == "true" ]]; then
        local digest=$(getDigest $1)
        local space_width=$(( 80 - "$(echo $1 | wc -c)"  ))

        local spacing=$(awk "BEGIN{for(c=0;c<${space_width};c++) printf \" \"}")
        echo "$1@$digest"
    else
        echo "$1"
    fi
}

function initSkopeo() {

   docker run --rm -d \
         --name ${SKOPEO_CONTAINER} \
         --entrypoint sh \
         -w /skopeo \
         ${SKOPEO_IMAGE} \
         -c 'sleep 1000'

   local gcr_pass=$(cat ${GCR_SA_FILE})
   docker exec $SKOPEO_CONTAINER skopeo login -u _json_key -p "$gcr_pass" gcr.io
}

function stopSkopeo() {
   docker stop ${SKOPEO_CONTAINER} &> /dev/null
}

function printImages() {
    if [[ "$SHOW_DIGESTS" == "true" ]]; then
        trap stopSkopeo EXIT

        initSkopeo 1> /dev/null
    fi

    set +e
    local tmpfile=$(mktemp)
    for i in $IMAGES; do
        printImage $i >> ${tmpfile} &
    done

    wait

    cat ${tmpfile} | sort
}

LOCAL_CHART_PATH=$(mktemp -d)
if [[ "$REPO_CHANNEL" == "dev" ]]; then
    helm pull oci://quay.io/codefresh/dev/codefresh ${ONPREM_VERSION} -d ${LOCAL_CHART_PATH} --untar &> /dev/null
elif [[ "$REPO_CHANNEL" == "prod" ]]; then
    helm pull oci://quay.io/codefresh/codefresh ${ONPREM_VERSION} -d ${LOCAL_CHART_PATH} --untar &> /dev/null
fi

IMAGES=$(getImages | sort -u)

# RUNNER_LOCAL_CHART_PATH=$(mktemp -d)
# helm repo add cf-runtime https://chartmuseum.codefresh.io/cf-runtime &>/dev/null
# helm fetch ${RUNNER_CHART} -d ${RUNNER_LOCAL_CHART_PATH}
# IMAGES+=$NEW_LINE$(getRunnerImages | sort -u)

printImages