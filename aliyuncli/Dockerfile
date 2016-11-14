FROM  centos:centos6


WORKDIR /root
RUN yum install -y  epel-release
RUN yum install -y  python-pip   &&  \
    pip install aliyuncli && \
    pip install aliyun-python-sdk-rds && \
    pip install aliyun-python-sdk-ecs && \
    pip install aliyun-python-sdk-slb
