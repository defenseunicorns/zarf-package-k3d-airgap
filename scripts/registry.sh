#!/bin/sh
#
# This script starts a k3d registry and populates it with pre-downloaded 
# docker images as well as k3s airgap images.
#
# Requires: 'docker' command.

# Start local k3d registry
./k3d registry create airgap.localhost --port 5000

# Tag images and push them to the airgap registry
docker tag ghcr.io/k3d-io/k3d-proxy:5.5.2 k3d-airgap.localhost:5000/k3d-io/k3d-proxy:5.5.2
docker push k3d-airgap.localhost:5000/k3d-io/k3d-proxy:5.5.2
docker tag ghcr.io/k3d-io/k3d-tools:5.5.2 k3d-airgap.localhost:5000/k3d-io/k3d-tools:5.5.2
docker push k3d-airgap.localhost:5000/k3d-io/k3d-tools:5.5.2

# Remove the docker.io prefix
AIRGAP_IMAGES=$(cat k3s-images.txt | sed 's/docker.io\///')
for i in $AIRGAP_IMAGES; do
	docker tag $i k3d-airgap.localhost:5000/$i
	docker push k3d-airgap.localhost:5000/$i
done
