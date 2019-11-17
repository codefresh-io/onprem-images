#!/bin/bash
#

DIR=$(dirname $BASH_SOURCE)
CONTAINER_NAME=cfcr-registry
#DOCKER_IMAGE=nginx
#DOCKER_IMAGE=openresty/openresty
DOCKER_IMAGE=registry:2

CONTAINER_STATUS=$(docker inspect -f '{{.State.Status}}' ${CONTAINER_NAME} 2>/dev/null)
if [[ $? == 0 ]]; then
   echo "Container ${CONTAINER_NAME} is already ${CONTAINER_STATUS}   
"
  if [[ -n "${FORCE}" ]]; then
    echo "Removing container ${CONTAINER_NAME} ..."
    docker rm -fv ${CONTAINER_NAME}
  else
    # read -r -p "Do you want to recreate it? [y/N] " response
    # if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]
    # then
          echo "Removing container ${CONTAINER_NAME} ..."
          docker rm -fv ${CONTAINER_NAME}
  #   else
  #       echo "Exiting..."
  #       exit 0
	# fi
  fi
fi

docker run --network host -d --name ${CONTAINER_NAME} --restart unless-stopped \
  -v $(realpath ${DIR}/config.yml):/etc/docker/registry/config.yml:ro \
  -v $(realpath "${DIR}/ssl/"):/etc/docker/registry/ssl/:ro \
  -v $(realpath ${DIR}/htpasswd):/etc/docker/htpasswd:ro \
  -v /var/lib/registry:/var/lib/registry:rw \
  ${DOCKER_IMAGE}