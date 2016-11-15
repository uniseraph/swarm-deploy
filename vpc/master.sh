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


#ZK_URL="zk://$(ifconfig eth0 | grep inet | awk '{{print $2}}'):2181"
ETCD_URL="etcd://$(ifconfig eth0 | grep inet | awk '{{print $2}}'):2379"
BIP=${BIP:-192.168.100.1/24}
swarm::multinode::main

swarm::multinode::turndown

swarm::bootstrap::bootstrap_daemon

swarm::multinode::start_etcd
#swarm::multinode::start_zookeeper

#swarm::multinode::start_flannel

swarm::bootstrap::restart_docker

#swarm::multinode::start_k8s_master

swarm::multinode::start_swarm_master

