#!/bin/bash
SKIP_WARNING=${SKIP_WARNING:-"0"}
DOCKER_LABEL=${DOCKER_LABEL:-"role=disposable"}

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

SERVICES=$(docker service ls --filter=label=${DOCKER_LABEL} | tail -n +2)

if [ -z "${SERVICES}" ]; then
	echo "No services with label: ${DOCKER_LABEL} - nothing to do."
	exit 1
fi

if [[ "${SKIP_WARNING}" == "0" ]]; then
	delim
	echo "| Running this script will kill off 1 docker image with label: ${DOCKER_LABEL}"
	echo "| You have 5 seconds to change your mind and CTRL+C out of this."
	delim
	echo -e "${color_white}${SERVICES}${color_reset}"
	delim
	sleep 5
	echo
fi


# For example:
# mmqe8ua6xcdp  gotwitter   replicated  5/5       titpetric/gotwitter:latest
# zlca3i0z6hln  gotwitter2  replicated  1/1       titpetric/gotwitter:latest

while read -r SERVICE; do

	service=($SERVICE)
	service_id=${service[0]}
	service_name=${service[1]}
	service_mode=${service[2]}
	service_state=(${service[3]/\// })

	echo -n "${service_id} ${service_name}: "

	# don't kill services less than full replica set
	if [[ "${service_state[0]}" != "${service_state[1]}" ]]; then
		echo -e "service is degraded ${service[3]} - ${color_yellow}skipping${color_reset}"
		continue
	fi

	# don't kill services with only one container
	if [[ "${service_state[1]}" == "1" ]]; then
		echo -e "service has only one running container - ${color_yellow}skipping${color_reset}"
		continue
	fi

	# find a running container on the current node
	NODE=$(uname -n)
	echo $NODE
	CONTAINER=$(docker service ps ${service_id} -f node=${NODE} -f 'desired-state=running' --no-trunc | tail -n +2 | head -n 1 | awk '{print $2 "." $1}')

	if [ -z "${CONTAINER}" ]; then
		echo -e "no containers running on current host - ${color_yellow}skipping${color_reset}"
		continue
	fi

	# use docker rm -f (force remove) - container should disappear not just exit gracefully.
	echo -e "${color_green}removing a container${color_reset}"
	echo -e -n "${color_white}> "
	docker rm -f $CONTAINER
	echo -e "${color_reset}"

done <<< "$SERVICES"

# print out some final state

echo
delim
echo "Final service status:"
docker service ls