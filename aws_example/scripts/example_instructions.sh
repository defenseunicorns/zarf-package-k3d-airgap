#!/bin/bash

INSTANCE_NAME="" # Match this to your instance name from Terraform
# ensure you're authenticated via AWS vault or other means to your AWS account
EC2_URL=$(aws ec2 describe-instances --region us-gov-west-1 --filter "Name=tag:Name,Values=$INSTANCE_NAME" --query 'Reservations[].Instances[].PublicDnsName' --output text)
PEM="" # Match this to your pem file name

# Transfer files to ec2 instance, connect to ec2 instance, and run 
# ec2_prep_final.sh three times validating that the script executes without 
# executing actions
scp -i "$PEM" scripts/ec2_prep_final.sh ec2-user@$EC2_URL:/home/ec2-user
ssh -i "$PEM" ec2-user@$EC2_URL
chmod +x /home/ec2-user/ec2_prep_final.sh
./ec2_prep_final.sh
./ec2_prep_final.sh
./ec2_prep_final.sh # Shouldn't reboot the system

scp -i "$PEM" zarf-config.yaml ec2-user@$EC2_URL:/home/ec2-user/clusterOne

# Working directory for cluster deployment
cd clusterOne

# If a new package needs to be published prior to k3d deployment
# $ echo $CR_PAT | docker login ghcr.io -u USERNAME --password-stdin
# zarf package create . --confirm
# zarf package publish zarf-package-k3d-airgap-amd64-5.5.2.tar.zst oci://ghcr.io/defenseunicorns/zarf-package-k3d-airgap

## Start K3d Install
zarf package deploy oci://ghcr.io/defenseunicorns/zarf-package-k3d-airgap/k3d-airgap:5.5.2-amd64 --set enable_traefik=false --set enable_service_lb=false --set enable_metrics_server=false --set enable_gpus=true --confirm
# sudo mv k3d /usr/local/bin/k3d # just moves k3d to /usr/local/bin so you don't have to prefix ./k3d whenever you wanna run commands
# k3d version # validates k3d is installed
## END K3d Install

# WARNING - make sure your zarf-config.yaml is correct and on your ec2 
# endpoint before initing the cluster
## Start Zarf Init
zarf tools download-init
zarf init --registry-push-password dummy --registry-push-username dummy --registry-url k3d-airgap.localhost:5000 --components git-server --confirm
# Make sure you record the app, un, and pass for resources on production deployments
## End Zarf Init

## Start Metallb Install - requires jq
zarf package deploy oci://ghcr.io/defenseunicorns/zarf-package-k3d-airgap/metallb:v0.13.10-amd64 --confirm
## End Metallb Install

## WARNING - make sure your zarf-config.yaml is correct and on your ec2 
# endpoint before deploying dubbd
## Start Dubbd Install - requires fs.inotify.max_user_instances=1024 or 
# promtail will fail to start  
# Also required iptable_filter and iptable_nat kernel modules
zarf package deploy oci://ghcr.io/defenseunicorns/packages/dubbd-k3d:0.7.0-amd64 --confirm
## End Dubbd Install
## Wait for promtail to finish building

R1_USERNAME="" #imput username for registry1.dso.mil
read -s -p "Enter Password for $R1_USERNAME: " R1_PASSWORD

# You have to preposture sidecar pull or login to registry1 to prevent failure
docker login registry1.dso.mil -u $R1_USERNAME -p $R1_PASSWORD 
git clone https://github.com/defenseunicorns/leapfrogai.git
cd leapfrogai
zarf package create . --confirm
zarf package deploy zarf-package-leapfrogai-*.zst --confirm
