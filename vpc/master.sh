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

source $(dirname "${BASH_SOURCE}")/../common/utils.sh
source $(dirname "${BASH_SOURCE}")/../common/docker.sh
source $(dirname "${BASH_SOURCE}")/../common/common.sh
source $(dirname "${BASH_SOURCE}")/../common/aliyun.sh
source $(dirname "${BASH_SOURCE}")/../common/swarm.sh
source $(dirname "${BASH_SOURCE}")/../vpc/hadoop.sh


MASTER_IP=$(ifconfig eth0 | grep inet | awk '{{print $2}}')
ETCD_URL="etcd://${MASTER_IP}:2379"
ZK_URL="zk://${MASTER_IP}:2181"
NETWORK=${NETWORK:-192.168.0.0/16}


common::setup_var

common::turndown

docker::bootstrap_daemon

common::start_zookeeper

common::start_etcd
if [ ! -d "/etc/swarm/aliyuncli" ]; then
  # Control will enter here if $DIRECTORY doesn't exist.
  utils::log::status "init and register aliyunconfig at etcd..."
  docker -H ${BOOTSTRAP_DOCKER_SOCK} run -ti --rm -v /etc/swarm/aliyuncli:/root/.aliyuncli \
    ${ALIYUNCLI_IMG} aliyuncli configure
  common::register_aliyuncli_config
fi

curl -sSL http://${MASTER_IP}:2379/v2/keys/coreos.com/network/config -XPUT \
      -d value="{ \"Network\": \"${NETWORK}\", \"Backend\": {\"Type\": \"vxlan\"}}"

common::get_subnet_bip ${MASTER_IP} ${MASTER_IP}



docker::restart_docker


swarm::start_master ${ZK_URL}

swarm::start_shipyard
aliyun::vpc::create_vroute_entry


mkdir -p /hadoop/dfs/name

docker run -ti --rm  \
  -v /opt/swarm-deploy/vpc:/opt/swarm-deploy/vpc \
  -v /usr/bin/docker:/usr/bin/docker \
  -e NAMENODE_IP=${MASTER_IP} \
  -e DOCKER_HOST=${MASTER_IP}:2376 \
  docker/compose:1.9.0 -f /opt/swarm-deploy/vpc/hadoop.yml -p hadoop up -d
#hdfs::start_namenode  ${MASTER_IP}:2376
#hdfs::start_datanode  ${MASTER_IP}:2376 ${MASTER_IP}

#aliyun::vpc::get_eip_address

#utils::log::status "http://${EIP}:8080"
