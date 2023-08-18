#!/bin/bash

CLUSTER_NAME=zarf-k3d
K3D=./k3d

# Check if the cluster already exists
if ${K3D} cluster list | grep -q "${CLUSTER_NAME}"; then
  echo "Cluster already exists"
else
    ${K3D} cluster create \
    --registry-use k3d-airgap.localhost:5000 \
    --k3s-arg "--disable=traefik@server:*" \
    --k3s-arg "--disable=metrics-server@server:*" \
    --k3s-arg "--disable=servicelb@server:*" \
    --registry-config registry.yaml \
    ${CLUSTER_NAME}
fi

# Switch to the k3d context
${K3D} kubeconfig merge ${CLUSTER_NAME}
