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

# Source common.sh
source $(dirname "${BASH_SOURCE}")/common.sh

MASTER_IP=$(ifconfig eth0 | grep inet | awk '{{print $2}}')
ETCD_URL="etcd://${MASTER_IP}:2379"
NETWORK=${NETWORK:-192.168.0.0/16}
#IPAM_SUBNET_IMG=${IPAM_SUBNET_IMG:-uniseraph/ipam-subnet:0.1}

if [ ! -d "/etc/swarm/aliyuncli" ]; then
  # Control will enter here if $DIRECTORY doesn't exist.
  docker run -ti --rm -v /etc/swarm/aliyuncli:/root/.aliyuncli \
    uniseraph/aliyuncli aliyuncli configure
fi

swarm::multinode::main

swarm::multinode::turndown

swarm::bootstrap::bootstrap_daemon

swarm::multinode::start_etcd
#swarm::multinode::start_zookeeper

curl -sSL http://${MASTER_IP}:2379/v2/keys/coreos.com/network/config -XPUT \
      -d value="{ \"Network\": \"${NETWORK}\", \"Backend\": {\"Type\": \"vxlan\"}}"


AccessKey=$(docker -H ${BOOTSTRAP_DOCKER_SOCK} run  -ti --rm -v /etc/swarm/aliyuncli:/root/.aliyuncli  \
  uniseraph/aliyuncli \
  aliyuncli configure get aliyun_access_key_id | \
  awk '{{print $3}}' |
  tr -d '\r')

AccessSecret=$(docker -H ${BOOTSTRAP_DOCKER_SOCK} run -ti --rm -v /etc/swarm/aliyuncli:/root/.aliyuncli  \
  uniseraph/aliyuncli \
  aliyuncli configure get aliyun_access_key_secret | \
  awk '{{print $3}}' |
  tr -d '\r')

Region=$(docker -H ${BOOTSTRAP_DOCKER_SOCK} run -ti --rm -v /etc/swarm/aliyuncli:/root/.aliyuncli  \
  uniseraph/aliyuncli \
  aliyuncli configure get region | \
  awk '{{print $3}}' |
  tr -d '\r')

Output=$(docker -H ${BOOTSTRAP_DOCKER_SOCK} run -ti --rm -v /etc/swarm/aliyuncli:/root/.aliyuncli  \
  uniseraph/aliyuncli \
  aliyuncli configure get output | \
  awk '{{print $3}}' |
  tr -d '\r' )

curl -sSL http://${MASTER_IP}:2379/v2/keys/cores.com/aliyuncli/config -XPUT \
      -d value="{ \"AccessKey\": \"${AccessKey}\" , \"AccessSecret\" : \"${AccessSecret}\" , \"Region\":\"${Region}\" ,  \"Output\":\"${Output}\" }"



LINE=$(docker -H ${BOOTSTRAP_DOCKER_SOCK} run -ti  --rm \
      --net=host \
      ${IPAM_SUBNET_IMG} \
      ipam-subnet   \
      --etcd-endpoints=http://${MASTER_IP}:2379 \
      --etcd-prefix=/coreos.com/network \ 
      --local-ip=${MASTER_IP} |
      tail -n1 | tr -d '\r')
SUBNET=$(echo ${LINE} | awk '{{print $1}}')
BIP=$(echo ${LINE} | awk '{{print $2}}'  )




#swarm::multinode::start_flannel

swarm::bootstrap::restart_docker

#swarm::multinode::start_k8s_master

swarm::multinode::start_swarm_master


swarm::vpc::create_vroute_entry

