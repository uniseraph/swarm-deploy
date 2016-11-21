#!/bin/bash

#source ./utils.sh



swarm::start_agent() {
  utils::log::status "Launching swarm agent ..."

  DIS_URL=$1
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

  DOCKER_LISTEN_URL=$(ifconfig eth0 | grep inet | awk '{{print $2}}'):2376
  SWARM_LISTEN_URL=$(ifconfig eth0 | grep inet | awk '{{print $2}}'):2375

  utils::log::status "Launching swarm master at ${SWARM_LISTEN_URL} ..."
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
    ${SWARM_IMG} \
    manage \
    --host=${SWARM_LISTEN_URL} \
    ${DIS_URL}
    #${ETCD_URL}
}



shipyard::start_shipyard() {
     docker run \
    -ti \
    -d \
    --restart=always \
    --name shipyard-rethinkdb \
    rethinkdb


 SWARM_LISTEN_URL=$(ifconfig eth0 | grep inet | awk '{{print $2}}'):2375


 docker run \
    -ti \
    -d \
    --restart=always \
    --name shipyard-controller \
    --link shipyard-rethinkdb:rethinkdb \
    -p 8080:8080 \
    shipyard/shipyard:latest \
    server \
    -d tcp://${SWARM_LISTEN_URL}
}
