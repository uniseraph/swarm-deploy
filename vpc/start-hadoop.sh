#!/bin/bash


if [[ -z ${MASTER_IP} ]]; then
    echo "Please export MASTER_IP in your env"
    exit 1
fi

SWARM_ENDPOINT=${SWARM_ENDPOINT:-"${MASTER_IP}:2375"}

start_hadoop_namenode
start_hadoop_datanode ${MASTER_IP}

start_hadoop_namenode() {

    mkdir -p /hadoop/dfs/name


    docker run -H ${SWARM_ENDPOINT}   -d \
      --name=hadoop_namenode_$(utils::small_sha) \
      --net=host \
      --restart=always \
      -v /hadoop/dfs/name:/hadoop/dfs/name \
      -e CLUSTER_NAME=myhadoop \
      -e "affinity:container!=*hadoop_name*" \
      -e "HDSF_CONF_dfs_namenode_datanode_registration_ip___hostname___check=false" \
      uhopper/hadoop-namenode

}

start_hadoop_datanode() {


    NAMENODE_IP=$1

    mkdir -p /hadoop/dfs/data

    docker run -H ${SWARM_ENDPOINT}   -d \
      --name=hadoop_datanode_$(utils::small_sha) \
      --net=host \
      --restart=always \
      -v /hadoop/dfs/data:/hadoop/dfs/data \
      -e CORE_CONF_fs_defaultFS=hdfs://${NAMENODE_IP}:8020 \
      -e "affinity:container!=*hadoop_data*"
      uhopper/hadoop-datanode

}
