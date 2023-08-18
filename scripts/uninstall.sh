#!/bin/bash

CLUSTER_NAME=zarf-k3d
K3D=./k3d

# Check if the cluster already exists
if ${K3D} cluster list | grep -q "${CLUSTER_NAME}"; then
    ${K3D} cluster delete ${CLUSTER_NAME}
else
  echo "K3d cluster: ${CLUSTER_NAME} not found"
fi
