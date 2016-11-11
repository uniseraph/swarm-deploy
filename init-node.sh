



yum install -y git docker ip


echo "DOCKER_STORAGE_OPTIONS=-s overlay" >> /etc/sysconfig/docker-storage

modprobe overlay
echo "overlay" > /etc/modules-load.d/overlay.conf


systemctl restart docker
