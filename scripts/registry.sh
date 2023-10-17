#!/bin/bash
#
# This script starts a k3d registry and populates it with pre-downloaded 
# docker images as well as k3s airgap images.
#
# Requires: 'docker' command.

K3D=./k3d
REGISTRY_NAME=k3d-airgap.localhost
REGISTRY_PORT=###ZARF_VAR_K3D_REGISTRY_PORT###
if ${K3D} registry list | grep -q "${REGISTRY_NAME}" && ${K3D} registry list | grep -q "running"; then
    echo "Registry with name: ${REGISTRY_NAME} already exists and is running. Skipping create."
elif ${K3D} registry list | grep -q "${REGISTRY_NAME}" && ! ${K3D} registry list | grep -q "running"; then
    echo "Registry with name: ${REGISTRY_NAME} exists, but is not running. Re-creating a new one."
    ${K3D} registry delete ${REGISTRY_NAME}

    # Start a new local k3d registry
    ${K3D} registry create airgap.localhost --port ${REGISTRY_PORT}} 
else
    # Start a new local k3d registry
    ${K3D} registry create airgap.localhost --port ${REGISTRY_PORT} 
fi

# List of current container images
images=$(docker images --format="{{.Repository}}:{{.Tag}}")

# Define an array of domain prefixes
domain_prefixes=("k3d-airgap.localhost:${REGISTRY_PORT}" "ghcr.io" "nvcr.io" "docker.io" "quay.io")

local_registry="k3d-airgap.localhost:${REGISTRY_PORT}"

for image in $images; do
	# Iterate through the domain prefixes and strip out the matching one
	image_name_without_domain="$image"
	for prefix in "${domain_prefixes[@]}"; do
		if [[ "$image_name_without_domain" == "$prefix"* ]]; then
			image_name_without_domain="${image_name_without_domain#$prefix/}"
			break
		fi
	done

	# Construct the new image name for the local registry
	local_image_name="$local_registry/$image_name_without_domain"

	# Check if the image already exists in the local registry
	if docker images "$local_image_name" | grep -q "$local_image_name"; then
		echo "Image already exists in the local registry: $local_image_name"
	else
		# Tag and push the image to the local registry
		docker tag $image $local_image_name
		docker push $local_image_name
	fi
done
