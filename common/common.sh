#!/bin/bash

# Copyright 2016 The swarmrnetes Authors All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

cd "$(dirname "${BASH_SOURCE}")"
#source ../common/utils.sh
#source ./docker-bootstrap.sh

common::setup_var(){

  # Require root
  if [[ "$(id -u)" != "0" ]]; then
    utils::log::fatal "Please run as root"
  fi

  for tool in curl ip docker jq ; do
    if [[ ! -f $(which ${tool} 2>&1) ]]; then
      utils::log::status "The binary ${tool} is required. Install it..."
      yum install -y ${tool}
    fi
  done

  # Make sure docker daemon is running
  if [[ $(docker ps 2>&1 1>/dev/null; echo $?) != 0 ]]; then
    utils::log::fatal "Docker is not running on this machine!"
  fi


  IPAM_SUBNET_IMG=${IPAM_SUBNET_IMG:-uniseraph/ipam-subnet:0.1}
  CURRENT_PLATFORM=$(utils::host_platform)
  ARCH=${ARCH:-${CURRENT_PLATFORM##*/}}
  utils::log::status "ARCH is set to: ${ARCH}"

  SWARM_IMG=${SWARM_IMG:-"swarm:1.2.5"}
  utils::log::status "SWARM_IMG is set to: ${SWARM_IMG}"
  ETCD_VERSION=${ETCD_VERSION:-"3.0.4"}
  utils::log::status "ETCD_VERSION is set to: ${ETCD_VERSION}"
  ZK_VERSION=${ZK_VERSION:-3.4.9}
  utils::log::status "ZK_VERSION is set to: ${ZK_VERSION}"

  ALIYUNCLI_IMG=${ALIYUNCLI_IMG:-"uniseraph/aliyuncli"}


  MTU=${MTU:-"1472"}
  utils::log::status "MTU is set to: ${MTU}"


  DEFAULT_IP_ADDRESS=$( ifconfig eth0 | grep inet | awk '{{print $2}}' )
  IP_ADDRESS=${IP_ADDRESS:-${DEFAULT_IP_ADDRESS}}
  utils::log::status "IP_ADDRESS is set to: ${IP_ADDRESS}"

  TIMEOUT_FOR_SERVICES=${TIMEOUT_FOR_SERVICES:-20}

  BOOTSTRAP_DOCKER_SOCK="unix:///var/run/docker-bootstrap.sock"
  BOOTSTRAP_DOCKER_PARAM="-H ${BOOTSTRAP_DOCKER_SOCK}"


}


common::start_zookeeper() {

  utils::log::status "Launching zookeeper..."

  docker ${BOOTSTRAP_DOCKER_PARAM} run -d \
    --name swarm_zk_$(utils::small_sha) \
    --restart=always \
    --net=host  \
    -v /var/lib/zookeeper/data:/data \
    -v /var/lib/zookeeper/datalog:/datalog \
    zookeeper:${ZK_VERSION} 

 # utils::log::status "waiting 10 seconds for zk starting..."
 # sleep 10

}


# Start etcd on the master node
common::start_etcd() {

  utils::log::status "Launching etcd..."

  # TODO: Remove the 4001 port as it is deprecated
  docker ${BOOTSTRAP_DOCKER_PARAM} run -d \
    --name swarm_etcd_$(utils::small_sha) \
    --restart=always \
    --net=host \
    -v /var/lib/swarm/etcd:/var/etcd \
    gcr.io/google_containers/etcd-${ARCH}:${ETCD_VERSION} \
    /usr/local/bin/etcd \
      --listen-client-urls=http://${MASTER_IP}:2379,http://localhost:2379 \
      --advertise-client-urls=http://${MASTR_IP}:2379 \
      --listen-peer-urls=http://0.0.0.0:2380 \
      --data-dir=/var/etcd/data

  # Wait for etcd to come up
  local SECONDS=0
  while [[ $(curl -fsSL http://localhost:2379/health 2>&1 1>/dev/null; echo $?) != 0 ]]; do
    ((SECONDS++))
    if [[ ${SECONDS} == ${TIMEOUT_FOR_SERVICES} ]]; then
      utils::log::fatal "etcd failed to start. Exiting..."
    fi
    sleep 1
  done

  sleep 2
}

# Start flannel in docker bootstrap, both for master and worker
common::start_flannel() {

  utils::log::status "Launching flannel..."

  # Set flannel net config (when running on master)
  if [[ "${MASTER_IP}" == "localhost" ]]; then
    curl -sSL http://localhost:2379/v2/keys/coreos.com/network/config -XPUT \
      -d value="{ \"Network\": \"${FLANNEL_NETWORK}\", \"Backend\": {\"Type\": \"${FLANNEL_BACKEND}\"}}"
  fi

  # Make sure that a subnet file doesn't already exist
  rm -f ${FLANNEL_SUBNET_DIR}/subnet.env

  docker ${BOOTSTRAP_DOCKER_PARAM} run -d \
    --name swarm_flannel_$(utils::small_sha) \
    --restart=${RESTART_POLICY} \
    --net=host \
    --privileged \
    -v /dev/net:/dev/net \
    -v ${FLANNEL_SUBNET_DIR}:${FLANNEL_SUBNET_DIR} \
    quay.io/coreos/flannel:${FLANNEL_VERSION}-${ARCH} \
    /opt/bin/flanneld \
      --etcd-endpoints=http://${MASTER_IP}:2379 \
      --ip-masq="${FLANNEL_IPMASQ}" \
      --iface="${IP_ADDRESS}"

  # Wait for the flannel subnet.env file to be created instead of a timeout. This is faster and more reliable
  local SECONDS=0
  while [[ ! -f ${FLANNEL_SUBNET_DIR}/subnet.env ]]; do
    ((SECONDS++))
    if [[ ${SECONDS} == ${TIMEOUT_FOR_SERVICES} ]]; then
      utils::log::fatal "flannel failed to start. Exiting..."
    fi
    sleep 1
  done

  source ${FLANNEL_SUBNET_DIR}/subnet.env

  utils::log::status "FLANNEL_SUBNET is set to: ${FLANNEL_SUBNET}"
  utils::log::status "FLANNEL_MTU is set to: ${FLANNEL_MTU}"
}


# Turndown the local cluster
common::turndown(){

  # Check if docker bootstrap is running
  DOCKER_BOOTSTRAP_PID=$(ps aux | grep ${BOOTSTRAP_DOCKER_SOCK} | grep -v "grep" | awk '{print $2}')
  if [[ ! -z ${DOCKER_BOOTSTRAP_PID} ]]; then

    utils::log::status "Killing docker bootstrap..."

    # Kill the bootstrap docker daemon and it's containers
    docker -H ${BOOTSTRAP_DOCKER_SOCK} rm -f $(docker -H ${BOOTSTRAP_DOCKER_SOCK} ps -q) >/dev/null 2>/dev/null
    kill ${DOCKER_BOOTSTRAP_PID}
  fi

  utils::log::status "Killing all swarm containers..."

  if [[ $(docker ps | grep "swarm" | awk '{print $1}' | wc -l) != 0 ]]; then
    docker rm -f $(docker ps | grep "swarm" | awk '{print $1}')
  fi

  utils::delete_bridge docker0
}



common::get_subnet_bip(){
  S_IP=$1
  C_IP=$2


  LINE=$(docker -H ${BOOTSTRAP_DOCKER_SOCK} run -ti  --rm \
      --net=host \
      ${IPAM_SUBNET_IMG} \
      ipam-subnet   \
      --etcd-endpoints=http://${S_IP}:2379 \
      --etcd-prefix=/coreos.com/network \
      --local-ip=${C_IP} |
      tail -n1 | tr -d '\r')
  SUBNET=$(echo ${LINE} | awk '{{print $1}}')
  BIP=$(echo ${LINE} | awk '{{print $2}}'  )

  utils::log::status "SUBNET=${SUBNET}"
  utils::log::status "BIP=${BIP}"
}


common::register_aliyuncli_config(){


  #    curl -sSL http://${MASTER_IP}:2379/v2/keys/coreos.com/network/config -XPUT \
   #         -d value="{ \"Network\": \"${NETWORK}\", \"Backend\": {\"Type\": \"vxlan\"}}"


AccessKey=$(docker -H ${BOOTSTRAP_DOCKER_SOCK}  run  -ti --rm -v /etc/swarm/aliyuncli:/root/.aliyuncli  \
  ${ALIYUNCLI_IMG} \
  aliyuncli configure get aliyun_access_key_id | \
  awk '{{print $3}}' |
  tr -d '\r')

AccessSecret=$(docker -H ${BOOTSTRAP_DOCKER_SOCK}  run -ti --rm -v /etc/swarm/aliyuncli:/root/.aliyuncli  \
  ${ALIYUNCLI_IMG} \
  aliyuncli configure get aliyun_access_key_secret | \
  awk '{{print $3}}' |
  tr -d '\r')

Region=$(docker -H ${BOOTSTRAP_DOCKER_SOCK}   run -ti --rm -v /etc/swarm/aliyuncli:/root/.aliyuncli  \
  ${ALIYUNCLI_IMG} \
  aliyuncli configure get region | \
  awk '{{print $3}}' |
  tr -d '\r')

Output=$(docker -H ${BOOTSTRAP_DOCKER_SOCK}  run -ti --rm -v /etc/swarm/aliyuncli:/root/.aliyuncli  \
  ${ALIYUNCLI_IMG} \
  aliyuncli configure get output | \
  awk '{{print $3}}' |
  tr -d '\r' )

curl -sSL http://${MASTER_IP}:2379/v2/keys/cores.com/aliyuncli/config -XPUT \
      -d value="{ \"AccessKey\": \"${AccessKey}\" , \"AccessSecret\" : \"${AccessSecret}\" , \"Region\":\"${Region}\" ,  \"Output\":\"${Output}\" }"
}


common::start_cadvisor() {

  docker run \
  --volume=/:/rootfs:ro \
  --volume=/var/run:/var/run:rw \
  --volume=/sys:/sys:ro \
  --volume=/var/lib/docker/:/var/lib/docker:ro \
  -p 18080:8080 \
  -d \
  --name=cadvisor \
  google/cadvisor:latest

}
