# swarm-deploy

This is a repository of community maintained Swarm cluster deployment
automations.

目前swarm-deploy只支持centos7u2@aliyun vpc ， 后续会支持centos7u2@aliyun经典网络以及centos7u2@物理网络

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
[root@iZrj91tefvghte2u30htvzZ vpc]# bash master.sh
+++ [1114 17:26:35] ARCH is set to: amd64
+++ [1114 17:26:35] SWARM_VERSION is set to: 1.2.5
+++ [1114 17:26:35] ETCD_VERSION is set to: 3.0.4
+++ [1114 17:26:35] ZK_VERSION is set to: 3.4.9
+++ [1114 17:26:35] ZK_URL  is set to: zk://10.24.136.254:2181
+++ [1114 17:26:35] BIP is set to: 192.168.1.1/24
+++ [1114 17:26:35] MTU is set to: 1472
+++ [1114 17:26:35] IP_ADDRESS is set to: 10.24.136.254
+++ [1114 17:26:35] Killing docker bootstrap...
+++ [1114 17:26:35] Killing all swarm containers...
a24b6301e0ba
cf11ff187bda
+++ [1114 17:26:35] Launching docker bootstrap...
+++ [1114 17:26:36] Launching zookeeper...
5166ee34422c544c452f6814ad75076adcbc335c89ad96261d4d2feee7f1691f
+++ [1114 17:26:36] waiting 10 seconds for zk starting...
+++ [1114 17:26:46] Restarting main docker daemon...
+++ [1114 17:26:47] Launching swarm master ...
+++ [1114 17:26:47] Launching swarm master , listening at 10.24.136.254:2375 ...
011507b60b5d3430c96442e5d77f115a63addd115a42794ad27b6ddc14bd586f
be6469a959c72c05e629de7b8caf3e04409916d952194f6ade117f5bc7e07c45
```

在这台ECS上，起了多个服务，其中zk 在 zk:///10.24.136.254:2181 , docker 在 tcp:///10.24.136.254:2376 和 unix


type | TCP BW(MB/s) | TCP lat(us)|
------------ | ------------- | ------------
Native       |117	          | 24.5

服务| 地址|
----|-----|
zk | zk:///10.24.136.254:2181 |




### 初始化swarm-agent 节点
