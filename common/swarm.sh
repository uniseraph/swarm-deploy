#!/bin/bash



swarm::start_agent() {
  swarm::log::status "Launching swarm agent ..."

  DIS_URL=$1
  SWARM_IMG=$2
  DOCKER_LISTEN_URL=$(ifconfig eth0 | grep inet | awk '{{print $2}}'):2376
  SWARM_LISTEN_URL=$(ifconfig eth0 | grep inet | awk '{{print $2}}'):2375


  docker run -d \
    --net=host \
    --pid=host \
    --restart=always \
    ${SWARM_IMG} \
    join \
    --addr   ${DOCKER_LISTEN_URL} \
    ${DIS_URL}

}
# Start swarmlet first and then the master components as pods
swarm::start_master() {

  DIS_URL=$1
  SWARM_IMG=$2

  DOCKER_LISTEN_URL=$(ifconfig eth0 | grep inet | awk '{{print $2}}'):2376
  SWARM_LISTEN_URL=$(ifconfig eth0 | grep inet | awk '{{print $2}}'):2375

  swarm::log::status "Launching swarm master at ${SWARM_LISTEN_URL} ..."
  docker run -d \
    --net=host \
    --pid=host \
    --restart=always \
    ${SWARM_IMG} \
    join \
    --addr   ${DOCKER_LISTEN_URL}\
    ${DIS_URL}
    #    ${ETCD_URL}

  sleep 2

  docker run -d \
    --net=host \
    --pid=host \
    --restart=always \
    swarm:${SWARM_VERSION} \
    manage \
    --host=${SWARM_LISTEN_URL} \
    ${DIS_URL}
    #${ETCD_URL}
}
