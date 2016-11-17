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
ZK_URL="zk://${MASTER_IP}:2181"
NETWORK=${NETWORK:-192.168.0.0/16}


swarm::multinode::main

swarm::multinode::turndown

swarm::bootstrap::bootstrap_daemon

swarm::multinode::start_etcd
if [ ! -d "/etc/swarm/aliyuncli" ]; then
  # Control will enter here if $DIRECTORY doesn't exist.
  docker run -ti --rm -v /etc/swarm/aliyuncli:/root/.aliyuncli \
    ${ALIYUNCLI_IMG} aliyuncli configure
  swarm::common::register_aliyuncli_config
fi

curl -sSL http://${MASTER_IP}:2379/v2/keys/coreos.com/network/config -XPUT \
      -d value="{ \"Network\": \"${NETWORK}\", \"Backend\": {\"Type\": \"vxlan\"}}"

swarm::common::register_aliyuncli_config

swarm::common::get_subnet_bip ${MASTER_IP} ${MASTER_IP}



swarm::bootstrap::restart_docker


swarm::multinode::start_swarm_master ${ETCD_URL}


swarm::vpc::create_vroute_entry

