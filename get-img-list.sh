#!/bin/bash

set -e

if [[ -z "${LOCAL_CHART_PATH}" ]]; then
    REPO_CHANNEL=${REPO_CHANNEL:-$1}
    CHART=codefresh-onprem-${REPO_CHANNEL}/codefresh
    ONPREM_VERSION=${ONPREM_VERSION:-$2}
    if [[ -n "${ONPREM_VERSION}" ]]; then
      VERSION_PARAM="--version $ONPREM_VERSION"
    fi

    echo "Fetching http://charts.codefresh.io/${REPO_CHANNEL} ${VERSION_PARAM} to ${LOCAL_CHART_PATH}" >&2
    LOCAL_CHART_PATH=$(mktemp -d)
    helm repo add codefresh-onprem-${REPO_CHANNEL} http://charts.codefresh.io/${REPO_CHANNEL} &>/dev/null
    helm fetch ${CHART} ${VERSION_PARAM} -d ${LOCAL_CHART_PATH}
else
   echo "Using LOCAL_CHART_PATH = ${LOCAL_CHART_PATH}" >&2
fi

HELM_VALS="--set global.seedJobs=true --set global.certsJobs=true"

function getHelmReleaseImages() {
    helm template ${LOCAL_CHART_PATH} ${VERSION_PARAM} ${HELM_VALS} | grep 'image:' | awk -F 'image: ' '{print $2}' | tr -d '"' | sort -u
}

function getRuntimeImages() {

    RUNTIME_IMAGES=(
        CONTAINER_LOGGER_IMAGE
        DOCKER_PUSHER_IMAGE
        DOCKER_TAG_PUSHER_IMAGE
        DOCKER_PULLER_IMAGE
        DOCKER_BUILDER_IMAGE
        GIT_CLONE_IMAGE
        COMPOSE_IMAGE
        KUBE_DEPLOY
        FS_OPS_IMAGE
    )

    for k in ${RUNTIME_IMAGES[@]}; do
        helm template ${LOCAL_CHART_PATH} ${VERSION_PARAM} ${HELM_VALS} | grep "$k" | tr -d '"' | tr -d ',' | awk -F "$k: " '{print $2}' | sort -u
    done
    
    helm template ${LOCAL_CHART_PATH} ${VERSION_PARAM} ${HELM_VALS} | grep 'engine:' | tr -d '"' | tr -d ',' | awk -F 'image: ' '{print $2}'| sort -u # engine image
    helm template ${LOCAL_CHART_PATH} ${VERSION_PARAM} ${HELM_VALS} | grep 'dindImage'  | tr -d '"' | tr -d ',' | awk -F ' ' '{print $2}' | sort -u # dind image
}

# default images listed here:
# https://github.com/codefresh-io/engine/blob/d2f59647be8d4e76b6c195b2d5f71cbbf8ce0094/src/server/config/environment/kubernetes.js#L95-L107
function getDefaultEngineImages() {
    DEFAULT_ENGINE_IMAGES=(
        quay.io/codefresh/cf-docker-pusher:v5
        quay.io/codefresh/cf-docker-puller:v7
        quay.io/codefresh/cf-docker-tag-pusher:v2
        quay.io/codefresh/cf-docker-builder:v16
        quay.io/codefresh/cf-gc-builder:0.4.0
        quay.io/codefresh/cf-container-logger:1.4.2
        quay.io/codefresh/cf-git-cloner:10.0.1
        quay.io/codefresh/compose:latest
        quay.io/codefresh/cf-deploy-kubernetes:latest
        quay.io/codefresh/fs-ops:latest
        quay.io/codefresh/pikolo:latest
        quay.io/codefresh/cf-debugger:1.1.2
    )

    for i in ${DEFAULT_ENGINE_IMAGES[@]}; do
        echo $i
    done
}

function getOtherImages() {
    
    OTHER_IMAGES=(
        codefresh/pikolo:latest
        codefresh/cf-runtime-cleaner:latest
        codefresh/cli:latest
        codefresh/agent:stable
        gcr.io/codefresh-enterprise/codefresh/cf-k8s-monitor:4.6.3
        alpine:latest
        ubuntu:latest
        codefresh/kube-helm:3.0.3
        codefresh/hermes-store-backup:0.2.0
    )

    for i in ${OTHER_IMAGES[@]}; do
        echo $i
    done
}

function getImages() {
    getHelmReleaseImages
    getRuntimeImages
    getDefaultEngineImages
    getOtherImages
}


getImages | sort -u