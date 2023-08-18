# K3D for Airgapped Environments
Deploy k3d in an air-gapped environment

## Prerequisites

- Currently works and tested on Linux amd64 systems.
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
