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
source $(dirname "${BASH_SOURCE}")/../common/utils.sh
source $(dirname "${BASH_SOURCE}")/../common/docker.sh
source $(dirname "${BASH_SOURCE}")/../common/common.sh
source $(dirname "${BASH_SOURCE}")/../common/aliyun.sh
source $(dirname "${BASH_SOURCE}")/../common/swarm.sh
source $(dirname "${BASH_SOURCE}")/../vpc/hadoop.sh

if [[ -z ${MASTER_IP} ]]; then
    echo "Please export MASTER_IP in your env"
    exit 1
fi

# Make sure MASTER_IP is properly set
if [[ -z ${ECTD_URL} ]]; then
    ETCD_URL=etcd://${MASTER_IP}:2379
fi
if [[ -z ${ZK_URL} ]]; then
    ZK_URL=zk://${MASTER_IP}:2181
fi

#LOCAL_IP=$(ifconfig eth0  | grep inet | awk '{{print $2}}' )

common::setup_var

common::turndown

docker::bootstrap_daemon

common::get_subnet_bip ${MASTER_IP} ${IP_ADDRESS}

docker::restart_docker

swarm::start_agent ${ETCD_URL}


if [ ! -d "/etc/swarm/aliyuncli" ]; then
  # Control will enter here if $DIRECTORY doesn't exist.

  ALIYUNCLI_CONFIG=$(curl -sSL http://${MASTER_IP}:2379/v2/keys/cores.com/aliyuncli/config   | jq .node.value   |  sed -e 's/^.//' | sed -e 's/.$//' | tr -d "\\")
  echo "${ALIYUNCLI_CONFIG}" > /tmp/aliyuncli_config
  AccessKey=$( echo ${ALIYUNCLI_CONFIG} |  jq .AccessKey | tr -d '"' )
  AccessSecret=$( echo ${ALIYUNCLI_CONFIG} | jq  .AccessSecret | tr -d '"')
  Region=$( echo ${ALIYUNCLI_CONFIG} | jq .Region | tr -d '"')
  Output=$( echo ${ALIYUNCLI_CONFIG} | jq .Output | tr -d '"')
  
  docker run -ti --rm -v /etc/swarm/aliyuncli:/root/.aliyuncli \
    ${ALIYUNCLI_IMG} aliyuncli configure set \
    --output ${Output} \
    --region ${Region} \
    --aliyun_access_key_secret ${AccessSecret} \
    --aliyun_access_key_id ${AccessKey}
fi

aliyun::vpc::create_vroute_entry

hdfs::start_datanode ${MASTER_IP}
