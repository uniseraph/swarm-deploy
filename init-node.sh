

echo "deleting all containers ..."

docker rm -f `docker ps -aq`
yum remove -y   docker
yum install -y  docker jq


echo "STORAGE_DRIVER=overlay" > /etc/sysconfig/docker-storage-setup

modprobe overlay
echo "overlay" > /etc/modules-load.d/overlay.conf


DEFAULT_IP=$(ifconfig eth0 | grep inet | awk '{{print $2}}')
DOCKER_LISTEN_URL=tcp://${DEFAULT_IP}:2376

## aliyun ecs hostname can't be resolved
echo "${DEFAULT_IP} $(hostname)" >> /etc/hosts

sed -e  "s#daemon#daemon -H unix:///var/run/docker.sock -H ${DOCKER_LISTEN_URL}#g" -i /usr/lib/systemd/system/docker.service

systemctl daemon-reload

systemctl restart docker
