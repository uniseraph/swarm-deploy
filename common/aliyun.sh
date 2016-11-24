#!/bin/bash

#source ./utils.sh

aliyun::vpc::create_vroute_entry(){
   utils::log::status "Add custom route ..."
   VpcId=$(curl 100.100.100.200/latest/meta-data/vpc-id)
   InstanceId=$(curl 100.100.100.200/latest/meta-data/instance-id)

   utils::log::status "VpcId is ${VpcId} ... "
   utils::log::status "InstanceId is ${InstanceId} ... "

   VRouterId=$( docker ${BOOTSTRAP_DOCKER_PARAM} run \
     --net=host -ti --rm -v /etc/swarm/aliyuncli:/root/.aliyuncli \
     ${ALIYUNCLI_IMG} aliyuncli ecs DescribeVpcs \
     --VpcId ${VpcId} | jq .Vpcs[][].VRouterId | \
     tr -d '\"' )

   utils::log::status "VRouterId is ${VRouterId} ... "
   RouteTableId=$(docker ${BOOTSTRAP_DOCKER_PARAM} run \
     --net=host -ti --rm -v /etc/swarm/aliyuncli:/root/.aliyuncli \
     ${ALIYUNCLI_IMG} aliyuncli ecs DescribeVRouters \
     --VRouterId ${VRouterId} | \
     jq .VRouters[][].RouteTableIds.RouteTableId[] | \
     tr -d '\"')

   utils::log::status "RouteTableId is ${RouteTableId} ... "
   docker ${BOOTSTRAP_DOCKER_PARAM}  run --net=host -ti --rm -v /etc/swarm/aliyuncli:/root/.aliyuncli \
     ${ALIYUNCLI_IMG} aliyuncli ecs CreateRouteEntry \
      --DestinationCidrBlock ${SUBNET} \
      --NextHopId ${InstanceId} \
      --RouteTableId ${RouteTableId}
}



aliyun::vpc::get_eip_address(){

   RegionId=$(curl 100.100.100.200/latest/meta-data/region-id)
   InstanceId=$(curl 100.100.100.200/latest/meta-data/instance-id)

   IpAddress=$( docker ${BOOTSTRAP_DOCKER_PARAM} run \
     --net=host -ti --rm -v /etc/swarm/aliyuncli:/root/.aliyuncli \
     ${ALIYUNCLI_IMG} aliyuncli ecs DescribeEipAddresses \
     --RegionId ${RegionId} | \
     --AssociatedInstanceType EcsInstance | \
     --AssociatedInstanceId ${InstanceId} | jq .IpAddress \
     tr -d '\"' )

   return ${IpAddress}
}
