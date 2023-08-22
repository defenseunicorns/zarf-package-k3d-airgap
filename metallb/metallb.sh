#!/bin/sh

CLUSTER_NAME=zarf-k3d
POOL=$(docker network inspect k3d-${CLUSTER_NAME}|jq -r .[0].IPAM.Config[0].Subnet | awk -F'.' '{print $1,$2,100}' OFS=".")

cat <<__EOF__ | zarf tools kubectl apply -f -
---
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: example
  namespace: metallb-system
spec:
  addresses:
  - $POOL.100-$POOL.200
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: empty
  namespace: metallb-system
__EOF__
