#!/bin/bash

CLUSTER_NAME=zarf-k3d
K3D=./k3d

ARGS="--registry-use k3d-airgap.localhost:5000 --registry-config registry.yaml"

if [[ "###ZARF_VAR_ENABLE_GPUS###" == "true" ]]; then
	ARGS+=" --gpus=###ZARF_VAR_GPU_COUNT### --image=###ZARF_VAR_K3S_CUDA_IMAGE###"
fi
if [[ "###ZARF_VAR_ENABLE_SERVICE_LB###" == "false" ]]; then
	ARGS+=" --no-lb"
fi
if [[ "###ZARF_VAR_ENABLE_TRAEFIK###" == "false" ]]; then
	ARGS+=" --disable=traefik@server:*"
fi
if [[ "###ZARF_VAR_ENABLE_METRICS_SERVER###" == "false" ]]; then
	ARGS+=" --disable=metrics-server@server:*"
fi

# Check if the cluster already exists
if ${K3D} cluster list | grep -q "${CLUSTER_NAME}"; then
  echo "Cluster already exists"
else
    ${K3D} cluster create ${ARGS} ${CLUSTER_NAME}
fi

# Switch to the k3d context
${K3D} kubeconfig merge ${CLUSTER_NAME}
