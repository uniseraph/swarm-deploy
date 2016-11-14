FROM  centos:centos6


WORKDIR /root
RUN yum install -y  epel-release
RUN curl "https://bootstrap.pypa.io/get-pip.py" -o "pip-install.py"    &&  \
    python pip-install.py && \
    pip install aliyuncli && \
    pip install aliyun-python-sdk-rds && \
    pip install aliyun-python-sdk-ecs && \
    pip install aliyun-python-sdk-slb
