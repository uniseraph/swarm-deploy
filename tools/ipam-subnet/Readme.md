

init a network
```
 curl -sSL http://localhost:2379/v2/keys/coreos.com/network/config -XPUT \
       -d value="{ \"Network\": \"192.168.1.1/16\", \"Backend\": {\"Type\": \"vxlan\"}}"
```


apply a subnet ip range
```
./ipam-subnet   --etcd-endpoints=http://localhost:2379 --etcd-prefix=/coreos.com/network
```
