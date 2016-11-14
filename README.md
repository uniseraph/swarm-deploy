# swarm-deploy

This is a repository of community maintained Swarm cluster deployment
automations.

目前swarm-deploy只支持centos7u2@aliyun vpc ， 后续会支持centos7u2@aliyun经典网络以及centos7u2@物理网络

## 在阿里云海外节点创建一个vpc 虚拟机，注意要选择 centos7u2的基础镜像

## 登录虚拟机，获取swarm-deploy工具

```
yum install -y git && cd /opt && git clone https://github.com/uniseraph/swarm-deploy.git 
```
