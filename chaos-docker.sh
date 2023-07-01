#!/bin/bash
SKIP_WARNING=${SKIP_WARNING:-"0"}
DOCKER_LABEL=${DOCKER_LABEL:-"role:disposable"}
DOCKER_ARGS=${@:-"rm -f"}

function delim {
    echo "----------------------------------------------------------------------------"
}

if [ -z "${DOCKER_LABEL}" ]; then
	echo 'DOCKER_LABEL not provided (empty). Usage: DOCKER_LABEL="role=disposable" ./chaos.sh'
	exit 1
fi

color_yellow="\e[93m"
color_white="\e[97m"
color_green="\e[92m"
color_reset="\e[0m"

SERVICES=$(docker ps --filter "label=${DOCKER_LABEL}" --format '{{.ID}}')
SERVICES_COUNT=$(echo "$SERVICES" | wc -l)

if [ "${SERVICS_COUNT}" == "1" ]; then
	echo -e "service has only one running container - ${color_yellow}skipping${color_reset}"
	exit 1
fi

if [ -z "${SERVICES}" ]; then
	echo "No services with label: ${DOCKER_LABEL} - nothing to do."
	exit 1
fi

if [ "${SKIP_WARNING}" != "1" ]; then
	delim
	echo "| Running this script will kill off 1 docker image with label: ${DOCKER_LABEL}"
	echo "| You have 5 seconds to change your mind and CTRL+C out of this."
	delim
	echo -e "${color_white}${SERVICES}${color_reset}"
	delim
	sleep 5
	echo
fi

container=$(echo "$SERVICES" | shuf | head -n 1)

echo "Stopping container $container"
set -ex
docker $DOCKER_ARGS $container
