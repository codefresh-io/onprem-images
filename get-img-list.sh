#!/bin/bash

set -eu

REPO_CHANNEL=${REPO_CHANNEL:-test}
CHART=codefresh-onprem-${REPO_CHANNEL}/codefresh
ONPREM_VERSION=${ONPREM_VERSION:-1.0.104}

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
    )

    for k in ${RUNTIME_IMAGES[@]}; do
        helm template ${LOCAL_CHART_PATH}/* --version ${ONPREM_VERSION} ${HELM_VALS} | grep "$k" | tr -d '"' | tr -d ',' | awk -F "$k: " '{print $2}' | sort -u
    done

    helm template ${LOCAL_CHART_PATH}/* --version ${ONPREM_VERSION} ${HELM_VALS} | grep 'engine:' | tr -d '"' | awk -F 'image: ' '{print $2}' | tr -d ',' | sort -u
}

function getOtherImages() {
    
    OTHER_IMAGES=(
        codefresh/dind:18.09.5-v24
        codefresh/pikolo:latest
        codefresh/cf-deploy-kubernetes
        codefresh/cf-runtime-cleaner:latest
        codefresh/cli:latest
        codefresh/agent:stable
        gcr.io/codefresh-enterprise/codefresh/cf-k8s-monitor:4.6.3
        alpine:latest
        ubuntu:latest
        codefresh/kube-helm:3.0.3
        codefresh/cf-docker-builder:v16
        codefresh/cf-docker-puller:v7
        codefresh/cf-docker-pusher:v5
        codefresh/fs-ops:latest
        codefresh/cf-container-logger:0.0.36
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
helm fetch ${CHART} --version ${ONPREM_VERSION} -d ${LOCAL_CHART_PATH}

getImages | sort -u