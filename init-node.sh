

echo "deleting all containers ..."

docker rm -f `docker ps -aq`
yum remove -y   docker
yum install -y  docker


echo "STORAGE_DRIVER=-s overlay" > /etc/sysconfig/docker-storage-setup

modprobe overlay
echo "overlay" > /etc/modules-load.d/overlay.conf


DOCKER_LISTEN_URL=$(ifconfig eth0 | grep inet | awk '{{print $2}}'):2375


sed -e  "s#daemon#daemon -H unix:///var/run/docker.sock -H ${DOCKER_LISTEN_URL}#g" -i /usr/lib/systemd/system/docker.service

systemctl daemon-reload

systemctl restart docker
