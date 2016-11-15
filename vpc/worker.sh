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

if [[ -z ${BIP} ]]; then
    echo "Please export BIP in your env"
    exit 1
fi

swarm::multinode::main

swarm::multinode::turndown


swarm::bootstrap::bootstrap_daemon

docker -H ${BOOTSTRAP_DOCKER_SOCK} run -ti  --rm \
      --net=host \
      ${IPAM_SUBNET_IMG} \
      ipam-subnet   \
      --etcd-endpoints=http://${MASTER_IP}:2379 \
      --etcd-prefix=/coreos.com/network
#swarm::multinode::start_flannel

swarm::bootstrap::restart_docker

#swarm::multinode::start_k8s_master

swarm::multinode::start_swarm_agent

