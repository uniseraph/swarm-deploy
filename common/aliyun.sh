#!/bin/bash
aliyun::vpc::create_vroute_entry(){
   swarm::log::status "Add custom route ..."
   VpcId=$(curl 100.100.100.200/latest/meta-data/vpc-id)
   InstanceId=$(curl 100.100.100.200/latest/meta-data/instance-id)

   swarm::log::status "VpcId is ${VpcId} ... "
   swarm::log::status "InstanceId is ${InstanceId} ... "

   VRouterId=$( docker ${BOOTSTRAP_DOCKER_PARAM} run \
     --net=host -ti --rm -v /etc/swarm/aliyuncli:/root/.aliyuncli \
     ${ALIYUNCLI_IMG} aliyuncli ecs DescribeVpcs \
     --VpcId ${VpcId} | jq .Vpcs[][].VRouterId | \
     tr -d '\"' )

   swarm::log::status "VRouterId is ${VRouterId} ... "
   RouteTableId=$(docker ${BOOTSTRAP_DOCKER_PARAM} run \
     --net=host -ti --rm -v /etc/swarm/aliyuncli:/root/.aliyuncli \
     ${ALIYUNCLI_IMG} aliyuncli ecs DescribeVRouters \
     --VRouterId ${VRouterId} | \
     jq .VRouters[][].RouteTableIds.RouteTableId[] | \
     tr -d '\"')

   swarm::log::status "RouteTableId is ${RouteTableId} ... "
   docker ${BOOTSTRAP_DOCKER_PARAM}  run --net=host -ti --rm -v /etc/swarm/aliyuncli:/root/.aliyuncli \
     ${ALIYUNCLI_IMG} aliyuncli ecs CreateRouteEntry \
      --DestinationCidrBlock ${SUBNET} \
      --NextHopId ${InstanceId} \
      --RouteTableId ${RouteTableId}
}

