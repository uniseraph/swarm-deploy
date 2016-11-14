

yum remove docker
yum install -y  docker


echo "DOCKER_STORAGE_OPTIONS=-s overlay" >> /etc/sysconfig/docker-storage

modprobe overlay
echo "overlay" > /etc/modules-load.d/overlay.conf


DOCKER_LISTEN_URL=$(ifconfig eth0 | grep inet | awk '{{print $2}}'):2375


sed -i  "s/daemon/daemon -H unix:\/\/\/var\/run\/docker.sock -H ${DOCKER_LISTEN_URL}/g" -e /usr/lib/systemd/system/docker.service



systemctl restart docker
