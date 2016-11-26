#!/bin/bash


IP_ADDRESS=$( ifconfig eth0 | grep inet | awk '{{print $2}}' )
NAMENODE_IP=${IP_ADDRESS}
SWARM_ENDPOINT=${IP_ADDRESS}:2375

hdfs::start_namenode() {
    mkdir -p /hadoop/dfs/name
    SWARM_ENDPOINT=$1
    docker -H ${SWARM_ENDPOINT} run  -d \
      --name=hadoop_namenode_$(utils::small_sha) \
      --net=host \
      --restart=always \
      -v /hadoop/dfs/name:/hadoop/dfs/name \
      -e CLUSTER_NAME=myhadoop \
      -e "affinity:container!=*hadoop_namenode*" \
      -e "HDSF_CONF_dfs_namenode_datanode_registration_ip___hostname___check=false" \
      uhopper/hadoop-namenode

}

hdfs::start_datanode() {

    SWARM_ENDPOINT=$1
    NAMENODE_IP=$2

    mkdir -p /hadoop/dfs/data
    docker -H ${SWARM_ENDPOINT} run  -d \
      --name=hadoop_datanode_$(utils::small_sha) \
      --net=host \
      --restart=always \
      -v /hadoop/dfs/data:/hadoop/dfs/data \
      -e CORE_CONF_fs_defaultFS=hdfs://${NAMENODE_IP}:8020 \
      -e "affinity:container!=*hadoop_datanode*" \
      uhopper/hadoop-datanode

}
