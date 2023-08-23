# K3D with GPU support for Airgapped Environments
Deploy k3d in an air-gapped environment with GPU support

## Prerequisites

- Currently works and tested on Linux amd64 systems.
- For GPU support, the NVIDIA kernel module and the `nvidia-docker2` package must be installed.
- A newer release of [Zarf](https://github.com/defenseunicorns/zarf) is installed. Tested with 0.29.0.
- [Docker](https://docs.docker.com/engine/install/) is installed and usable as an unprivileged user.

## Build

```
zarf package create --confirm
```

## Deploy
This package supports enabling/disabling the following K3D cluster options, via Zarf variables:
| Service | Zarf Variable | Value | Default |
| --- | --- | --- | --- |
| Traefik | enable_traefik | true or false | true |
| Service LB | enable_service_lb | true or false | true |
| Metrics Server | enable_metrics_server | true or false | true |
| GPU Support | enable_gpus | true or false | false |
| Number of GPUs to expose| gpu_count | "all" or an integer value | "all" |

```
mkdir temp && cd temp
zarf package deploy --confirm
```

## Limitations
- Does not deploy Traefik, ServiceLB or Metrics-Server
- MetalLB support is coming to replace ServiceLB
