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
``
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

### 初始化swarm-agent 节点
