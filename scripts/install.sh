#!/bin/bash

CLUSTER_NAME=zarf-k3d
K3D=./k3d

ARGS="--registry-use k3d-airgap.localhost:###ZARF_VAR_K3D_REGISTRY_PORT### --registry-config registry.yaml"

if [[ "###ZARF_VAR_ENABLE_GPUS###" == "true" ]]; then
	ARGS+=" --gpus=###ZARF_VAR_GPU_COUNT### --image=###ZARF_CONST_K3S_GPU_IMAGE###"
fi
if [[ "###ZARF_VAR_ENABLE_SERVICE_LB###" == "false" ]]; then
	ARGS+=" --no-lb --k3s-arg --disable=servicelb@server:*"
fi
if [[ "###ZARF_VAR_ENABLE_TRAEFIK###" == "false" ]]; then
	ARGS+=" --k3s-arg --disable=traefik@server:*"
fi
if [[ "###ZARF_VAR_ENABLE_METRICS_SERVER###" == "false" ]]; then
	ARGS+=" --k3s-arg --disable=metrics-server@server:*"
fi

# Check if the cluster already exists
if ${K3D} cluster list | grep -q "${CLUSTER_NAME}"; then
  echo "Cluster already exists"
else
    ${K3D} cluster create ${ARGS} ${CLUSTER_NAME}
fi

# Switch to the k3d context
${K3D} kubeconfig merge ${CLUSTER_NAME}
