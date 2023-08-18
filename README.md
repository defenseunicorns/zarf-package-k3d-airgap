# K3D with GPU support for Airgapped Environments
Deploy k3d in an air-gapped environment with GPU support

## Prerequisites

- Currently works and tested on Linux amd64 systems.
- NVIDIA kernel module and the `nvidia-docker2` package is installed.
- A newer release of [Zarf](https://github.com/defenseunicorns/zarf) is installed. Tested with 0.29.0.
- [Docker](https://docs.docker.com/engine/install/) is installed and usable as an unprivileged user.

## Build

```
zarf package create --confirm
```

## Deploy
```
mkdir temp && cd temp
zarf package deploy --confirm
```

## Limitations
- Does not deploy Traefik, ServiceLB or Metrics-Server
- MetalLB support is coming to replace ServiceLB
