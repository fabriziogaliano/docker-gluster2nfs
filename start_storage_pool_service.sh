docker service create \
-e GLUSTER_VOLUMES='vcm01' \
-e GLUSTER_HOST=192.168.10.41 \
--publish 2049:2049 \
--with-registry-auth \
whale.mosfarm.eu/gluster2nfs
