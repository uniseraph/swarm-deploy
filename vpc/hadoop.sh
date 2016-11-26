#!/bin/bash




hdfs::start_all() {

MASTER_IP=$1

docker run -ti --rm  \
  -v /opt/swarm-deploy/vpc:/opt/swarm-deploy/vpc \
  -v /usr/bin/docker:/usr/bin/docker \
  -e NAMENODE_IP=${MASTER_IP} \
  -e DOCKER_HOST=${MASTER_IP}:2376 \
  docker/compose:1.9.0 -f /opt/swarm-deploy/vpc/hadoop.yml -p hadoop up -d
}

hdfs::start_datanode() {

IP_ADDRESS=$1
MASTER_IP=$2

docker run -ti --rm  \
  -v /opt/swarm-deploy/vpc:/opt/swarm-deploy/vpc \
  -v /usr/bin/docker:/usr/bin/docker \
  -e NAMENODE_IP=${MASTER_IP} \
  -e DOCKER_HOST=${IP_ADDRESS}:2376 \
  docker/compose:1.9.0 -f /opt/swarm-deploy/vpc/hadoop.yml -p hadoop up -d  hdfs-datanode
}

#hdfs::start_namenode

#hdfs::start_datanode
