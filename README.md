# docker-gluster2nfs


This Docker container allow mounting and access through NFS to multiple Gluster Volumes

## Quick start

# Run gluster2nfs on Gluster host

```
docker run -d -p 2049:2049 --privileged fabriziogaliano/docker-gluster2nfs
```

## Example Docker-Compose file for docker 1.13 (Strongly adviced)

```
version: '3'
services:
    glusterfns:
       image: fabriziogaliano/docker-gluster2nfs:latest

       container_name: gluster2nfs

       privileged: true

       environment:
          GLUSTER_VOLUMES: 'vol01 vol02'
          GLUSTER_HOST: glusterhost01.local.domain

       extra_hosts:
          - glusterhost01.local.domain:192.168.0.5
          - glusterhost02.local.domain:192.168.0.10

       ports:
          - "2049:2049"

       restart: always
```
