#!/bin/bash

REGISTRY_NAME=k3d-airgap.localhost
K3D=./k3d

# Check if the registry already exists
if ${K3D} registry list | grep -q "${REGISTRY_NAME}"; then
    ${K3D} registry delete ${REGISTRY_NAME}
else
  echo "K3d registry: ${REGISTRY_NAME} not found"
fi
