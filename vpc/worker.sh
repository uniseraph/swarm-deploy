#!/bin/bash

# Copyright 2016 The Kubernetes Authors All rights reserved.
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


if [[ -z ${MASTER_IP} ]]; then
    echo "Please export MASTER_IP in your env"
    exit 1
fi

# Make sure MASTER_IP is properly set
if [[ -z ${ECTD_URL} ]]; then
    ETCD_URL=etcd://${MASTER_IP}:2379
fi

#if [[ -z ${BIP} ]]; then
#    echo "Please export BIP in your env"
#    exit 1
#fi

swarm::multinode::main

swarm::multinode::turndown


swarm::bootstrap::bootstrap_daemon

LINE=$(docker -H ${BOOTSTRAP_DOCKER_SOCK} run -ti  --rm \
      --net=host \
      ${IPAM_SUBNET_IMG} \
      ipam-subnet   \
      --etcd-endpoints=http://${MASTER_IP}:2379 \
      --etcd-prefix=/coreos.com/network  |
      tail -n1 | tr -d '\r')

echo "LINE=${LINE}"
SUBNET=$(echo ${LINE} | awk '{{print $1}}')
BIP=$(echo ${LINE} | awk '{{print $2}}'  )

swarm::bootstrap::restart_docker

#swarm::multinode::start_k8s_master

swarm::multinode::start_swarm_agent


if [ ! -d "/etc/swarm/aliyuncli" ]; then
  # Control will enter here if $DIRECTORY doesn't exist.

  ALIYUNCLI_CONFIG=$(curl -sSL http://${MASTER_IP}:2379/v2/keys/cores.com/aliyuncli/config   | jq .node.value   |  sed -e 's/^.//' | sed -e 's/.$//' | tr -d "\\")
  echo "${ALIYUNCLI_CONFIG}" > /tmp/aliyuncli_config
  AccessKey=$(cat /tmp/aliyuncli_config | jq .AccessKey | tr -d '"' )
  AccessSecret=$( echo ${ALIYUNCLI_CONFIG} | jq  .AccessSecret | tr -d '"')
  Region=$( echo ${ALIYUNCLI_CONFIG} | jq .Region | tr -d '"')
  Output=$( echo ${ALIYUNCLI_CONFIG} | jq .Output | tr -d '"')
  
  docker run -ti --rm -v /etc/swarm/aliyuncli:/root/.aliyuncli \
    uniseraph/aliyuncli aliyuncli configure set \
    --output ${Output} \
    --region ${Region} \
    --aliyun_access_key_secret ${AccessSecret} \
    --aliyun_access_key_id ${AccessKey}
fi

swarm::vpc::create_vroute_entry
