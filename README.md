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

### Example Deployments
```
mkdir temp && cd temp
zarf package deploy --confirm

or

mkdir temp && cd temp
zarf package deploy --set enable_traefik=false --set enable_service_lb=false --set enable_metrics_server=false --set enable_gpus=true --confirm
```

## MetalLB

If multiple loadbalancers are required, MetalLB support exists in this repo. Please take a look at the [metallb](metallb) directory.
MetalLB can be added into the newly created Kubernetes cluster after `zarf init` has been run.

e.g.

```
zarf tools download-init
zarf init --components git-server --confirm
cd metallb
zarf package create --confirm
zarf package deploy --confirm
```

## Limitations
- MetalLB must be installed after running `zarf init` in the cluster
