# swarm-deploy @ aliyun vpc

This is a repository of community maintained Swarm cluster deployment
automations.

目前swarm-deploy只支持centos7u2@aliyun vpc ， 后续会支持ubuntu 。


## 在阿里云海外节点创建一个vpc 虚拟机，注意要选择 centos7u2的基础镜像

## 登录虚拟机，获取swarm-deploy工具

```
yum install -y git && cd /opt && git clone https://github.com/uniseraph/swarm-deploy.git 
```

##  初始化本机环境

```
cd /opt/swarm-deploy && bash init-node.sh
```

注意在初始化环境时候，会删除本机原有的docker环境与容器！

在init-node.sh脚本中，会设置docker存储模式为overlay，使用如下命令确认

```
docker info | grep STORAGE
```

在init-node.sh脚本中，会设置docke engine的监听端口为eth0:2376和unix:///var/run/docker.sock，使用如下命令check

```
netstat -anlp | grep LISTEN | grep docker
```


### 初始化swarm-master节点

```
cd /opt/swarm/swarm-deploy/vpc && bash master.sh
```


在这台ECS上，起了多个服务，组成了一个master*1 node*1的swarm 集群。

服务| 地址|
----|-----|
zk | zk://10.24.136.254:2181 |
swarm master | tcp://10.24.136.254:2375|
docker  | tcp://10.24.136.254:2376 and unix:///var/run/docker.sock|
bootstrap docker | unix:///var/run/docker-bootstrap.sock|

通过docker info命令可以查看集群情况。
```
[root@iZrj91tefvghte2u30htvzZ vpc]# docker -H tcp://10.24.136.254:2375 info
Containers: 2
 Running: 2
 Paused: 0
 Stopped: 0
Images: 1
Server Version: swarm/1.2.5
Role: primary
Strategy: spread
Filters: health, port, containerslots, dependency, affinity, constraint
Nodes: 1
 iZrj91tefvghte2u30htvzZ: 10.24.136.254:2376
  └ ID: 63IV:PSVE:HMSZ:SOAG:4WV4:I5CA:75LU:7HRT:3ZKC:M5HS:3JBS:6R5A
  └ Status: Healthy
  └ Containers: 2 (2 Running, 0 Paused, 0 Stopped)
  └ Reserved CPUs: 0 / 1
  └ Reserved Memory: 0 B / 1.018 GiB
  └ Labels: executiondriver=native-0.2, kernelversion=3.10.0-327.22.2.el7.x86_64, operatingsystem=CentOS Linux 7 (Core), storagedriver=overlay
  └ UpdatedAt: 2016-11-14T09:40:16Z
  └ ServerVersion: 1.10.3
Plugins:
 Volume:
 Network:
Kernel Version: 3.10.0-327.22.2.el7.x86_64
Operating System: linux
Architecture: amd64
Number of Docker Hooks: 2
CPUs: 1
Total Memory: 1.018 GiB
Name: iZrj91tefvghte2u30htvzZ
Registries:
```


通过docker ps命令可以查看集群所有容器
```
[root@iZrj91tefvghte2u30htvzZ vpc]# docker -H tcp://10.24.136.254:2375 ps -a
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS               NAMES
98710ac47dec        swarm:1.2.5         "/swarm manage --host"   12 minutes ago      Up 12 minutes                           iZrj91tefvghte2u30htvzZ/hungry_golick
cd39dbdbfb86        swarm:1.2.5         "/swarm join --addr 1"   12 minutes ago      Up 12 minutes                           iZrj91tefvghte2u30htvzZ/stupefied_noether
```

注意，swarm默认的心跳周期是1分钟，所以如果没看到节点或容器，可以等1分钟。


### 初始化swarm-agent 节点

创建虚拟机与初始化节点步骤于swarm-master相同。

```
cd /opt/swarm-deploy/vpc 
export MASTER_IP=10.24.136.254  
bash worker.sh
```

worker启动成功后，可以查询集群情况，可以发现有两个节点，注意节点注册需要1分钟时间
```
[root@iZrj91tefvghte2u30htvzZ vpc]# docker -H 10.24.136.254:2375 info
Containers: 3
 Running: 3
 Paused: 0
 Stopped: 0
Images: 2
Server Version: swarm/1.2.5
Role: primary
Strategy: spread
Filters: health, port, containerslots, dependency, affinity, constraint
Nodes: 2
 iZrj9ap7v4yegqey9liovkZ: 10.174.72.36:2376
  └ ID: QL4V:DPVF:L3FG:KCPQ:7UIA:QRKL:YMPQ:3I4V:TRYR:2MR5:M7GZ:RQMF
  └ Status: Healthy
  └ Containers: 1 (1 Running, 0 Paused, 0 Stopped)
  └ Reserved CPUs: 0 / 1
  └ Reserved Memory: 0 B / 1.018 GiB
  └ Labels: executiondriver=native-0.2, kernelversion=3.10.0-327.22.2.el7.x86_64, operatingsystem=CentOS Linux 7 (Core), storagedriver=overlay
  └ UpdatedAt: 2016-11-14T10:34:22Z
  └ ServerVersion: 1.10.3
 iZrj91tefvghte2u30htvzZ: 10.24.136.254:2376
  └ ID: 63IV:PSVE:HMSZ:SOAG:4WV4:I5CA:75LU:7HRT:3ZKC:M5HS:3JBS:6R5A
  └ Status: Healthy
  └ Containers: 2 (2 Running, 0 Paused, 0 Stopped)
  └ Reserved CPUs: 0 / 1
  └ Reserved Memory: 0 B / 1.018 GiB
  └ Labels: executiondriver=native-0.2, kernelversion=3.10.0-327.22.2.el7.x86_64, operatingsystem=CentOS Linux 7 (Core), storagedriver=overlay
  └ UpdatedAt: 2016-11-14T10:33:44Z
  └ ServerVersion: 1.10.3
Plugins:
 Volume:
 Network:
Kernel Version: 3.10.0-327.22.2.el7.x86_64
Operating System: linux
Architecture: amd64
Number of Docker Hooks: 2
CPUs: 2
Total Memory: 2.036 GiB
Name: iZrj91tefvghte2u30htvzZ
Registries:```



