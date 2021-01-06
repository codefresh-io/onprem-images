#!/bin/bash

set -eu

REPO_CHANNEL=${REPO_CHANNEL:-$1}
CHART=codefresh-onprem-${REPO_CHANNEL}/codefresh
ONPREM_VERSION=${ONPREM_VERSION:-$2}

HELM_VALS="--set global.seedJobs=true --set global.certsJobs=true"

function getHelmReleaseImages() {
    helm template ${LOCAL_CHART_PATH}/* --version ${ONPREM_VERSION} ${HELM_VALS} | grep 'image:' | awk -F 'image: ' '{print $2}' | tr -d '"' | sort -u
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
        TEMPLATE_ENGINE
        PIPELINE_DEBUGGER_IMAGE
    )

    for k in ${RUNTIME_IMAGES[@]}; do
        helm template ${LOCAL_CHART_PATH}/* --version ${ONPREM_VERSION} ${HELM_VALS} | grep "$k" | tr -d '"' | tr -d ',' | awk -F "$k: " '{print $2}' | sort -u
    done
    
    helm template ${LOCAL_CHART_PATH}/* --version ${ONPREM_VERSION} ${HELM_VALS} | grep 'engine:' | tr -d '"' | tr -d ',' | awk -F 'image: ' '{print $2}'| sort -u # engine image
    helm template ${LOCAL_CHART_PATH}/* --version ${ONPREM_VERSION} ${HELM_VALS} | grep '"dindImage"'  | tr -d '"' | tr -d ',' | awk -F ' ' '{print $2}' | sort -u # dind image
}

function getOtherImages() {
    
    OTHER_IMAGES=(
        quay.io/codefresh/cf-runtime-cleaner:1.2.0
        quay.io/codefresh/agent:stable
        gcr.io/codefresh-enterprise/codefresh/cf-k8s-monitor:4.6.3
        quay.io/codefresh/kube-helm:3.0.3
        quay.io/codefresh/hermes-store-backup:0.2.0
    )

    for i in ${OTHER_IMAGES[@]}; do
        echo $i
    done
}

function getImages() {
    getHelmReleaseImages
    getRuntimeImages
    getOtherImages
}

LOCAL_CHART_PATH=$(mktemp -d)
helm repo add codefresh-onprem-${REPO_CHANNEL} http://charts.codefresh.io/${REPO_CHANNEL} &>/dev/null
helm fetch ${CHART} --version ${ONPREM_VERSION} -d ${LOCAL_CHART_PATH}

getImages | sort -u