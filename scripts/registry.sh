#!/bin/bash
#
# This script starts a k3d registry and populates it with pre-downloaded 
# docker images as well as k3s airgap images.
#
# Requires: 'docker' command.

# Start local k3d registry
./k3d registry create airgap.localhost --port 5000

# List of current container images
images=$(docker images --format="{{.Repository}}:{{.Tag}}")

# Define an array of domain prefixes
domain_prefixes=("k3d-airgap.localhost:5000" "ghcr.io" "nvcr.io" "docker.io" "quay.io")

local_registry="k3d-airgap.localhost:5000"

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
