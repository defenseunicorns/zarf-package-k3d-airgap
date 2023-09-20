#!/bin/bash

###############################################################################
############### SCRIPT TO PREPARE EC2 INSTANCE FOR K3D CLUSTER ################
# TESTED ON RHEL 9 p3.8xlarge	32 cpu x86_64 / 244 GB RAM / 4 16 GB v100 GPUs ##
#################### REGION US-GOV-WEST-1 UNCLASSIFIED ########################
# Script is idempotent and can be run until you receive only positive #########
# confirmation messages of successful installs and the target system doesn't ##
# reboot after running the script. ############################################
###############################################################################

############################ VARIABLES ######################################## 
REBOOT=0 
ZARF_URL="https://github.com/defenseunicorns/zarf/releases/download/v0.29.0/zarf_v0.29.0_Linux_amd64"
NVIDIA_REPO="http://developer.download.nvidia.com/compute/cuda/repos/rhel9/$(uname -i)/cuda-rhel9.repo"

######################## REQUIRED STEPS #######################################

# REQUIRED - Update system prior to installing packages, not fully sure about 
# dependencies satisfied by this requirement, but the base AMI provided by
# Amazon is not up to date and requires over 397 updates prior to executing
# remainder of this script and installing k3d, metallb, and DUBBD. Failure to
# update the system prior to installing packages will result in errors during
# application of GPU drivers and remaining deployments.
sudo dnf update -y 

# REQUIRED - Install jq, which is required to deploy metallb based on existing 
# implementation deployment will fail without it
if ! rpm -q jq > /dev/null 2>&1; then
  echo "jq is not installed. Installing jq..."
  sudo dnf install jq -y > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    echo "jq installed successfully."
  else
    echo "Failed to install jq."
  fi
else
  echo "jq is already installed."
fi

# REQUIRED - Configure fs.inotify.max_user_instances if not already configured, 
# this is required for promtail to deploy and will result in a failed
# deployment state for DUBBD, but won't be obvious as to why
if ! grep -q "fs.inotify.max_user_instances=1024" /etc/sysctl.d/99-sysctl.conf; then
  echo "Configuring fs.inotify.max_user_instances..."
  echo "fs.inotify.max_user_instances=1024" | \
    sudo tee -a /etc/sysctl.d/99-sysctl.conf > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    echo "fs.inotify.max_user_instances configured successfully."
    REBOOT=1
  else
    echo "Failed to configure fs.inotify.max_user_instances."
  fi
else
  echo "fs.inotify.max_user_instances is already configured."
fi

# REQUIRED - Configure iptables modules if not already configured, this is 
# required for DUBBD to deploy and monitoring will fail without it however the 
# error is clear as to why and will tell you IPTables is not configured for 
# NAT, but you need both iptable_filter and iptable_nat.
if ! { [ -f /etc/modules-load.d/iptables.conf ] \
    && grep -q -x -F -e 'iptable_filter' -e 'iptable_nat' \
    /etc/modules-load.d/iptables.conf; }; then
  echo "Configuring iptables modules..."
  echo -e "iptable_filter\niptable_nat" | \
    sudo tee /etc/modules-load.d/iptables.conf > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    echo "Iptables modules configured successfully."
    REBOOT=1
  else
    echo "Failed to configure iptables modules."
  fi
else
  echo "Iptables modules are already configured."
fi

# REQUIRED - Install Docker
if ! command -v docker &> /dev/null; then
  echo "Docker is not installed. Installing Docker..."
  sudo dnf config-manager --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo > /dev/null 2>&1
  sudo dnf install docker-ce docker-ce-cli containerd.io docker-buildx-plugin \
    docker-compose-plugin -y > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    sudo systemctl enable docker --now > /dev/null 2>&1
    if [ $? -eq 0 ]; then
      sudo usermod -aG docker ec2-user
      if [ $? -eq 0 ]; then
        echo "Docker installed and started successfully."
        REBOOT=1
      else
        echo "Failed to add ec2-user to docker group."
      fi
    else
      echo "Failed to start Docker."
    fi
  else
    echo "Failed to install Docker."
  fi
else
  echo "Docker is already installed."
fi

# REQUIRED - for NVIDIA drivers
if ! rpm -q epel-release > /dev/null 2>&1; then
  echo "EPEL is not installed. Installing EPEL..."
  sudo dnf install \
    https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm -y > \
    /dev/null 2>&1
  if [ $? -eq 0 ]; then
    sudo dnf config-manager --set-enabled epel > /dev/null 2>&1
    if [ $? -eq 0 ]; then
      echo "EPEL installed and enabled successfully."
    else
      echo "Failed to enable EPEL."
    fi
  else
    echo "Failed to install EPEL."
  fi
else
  echo "EPEL is already installed."
fi

# REQUIRED - required for NVIDIA drivers
if ! rpm -q dkms > /dev/null 2>&1; then
  echo "DKMS is not installed. Installing DKMS..."
  sudo dnf install dkms -y > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    echo "DKMS installed successfully."
  else
    echo "Failed to install DKMS."
  fi
else
  echo "DKMS is already installed."
fi

# REQUIRED - Install GCC, make, perl, kernel-devel, and kernel-headers, 
# required for NVIDIA drivers
if ! rpm -q gcc make perl kernel-devel kernel-headers > /dev/null 2>&1; then
  echo "GCC, make, perl, kernel-devel, or kernel-headers are not installed." \
   " Installing..."
  sudo dnf install gcc make perl kernel-devel kernel-headers -y > \
    /dev/null 2>&1
  if [ $? -eq 0 ]; then
    echo "GCC, make, perl, kernel-devel, and kernel-headers installed" \
      " successfully."
  else
    echo "Failed to install GCC, make, perl, kernel-devel, or kernel-headers."
  fi
else
  echo "GCC, make, perl, kernel-devel, and kernel-headers are already installed."
fi

# REQUIRED - You must disable/blacklist nouveau to install NVIDIA drivers
if [ ! -e /etc/modprobe.d/blacklist-nouveau.conf ]; then
  echo "File /etc/modprobe.d/blacklist-nouveau.conf does not exist. Creating..."
  sudo touch /etc/modprobe.d/blacklist-nouveau.conf
  if [ $? -eq 0 ]; then
    echo "File /etc/modprobe.d/blacklist-nouveau.conf created successfully."
  else
    echo "Failed to create /etc/modprobe.d/blacklist-nouveau.conf."
  fi
else
  echo "File /etc/modprobe.d/blacklist-nouveau.conf already exists."
fi

if ! grep -q "blacklist nouveau" /etc/modprobe.d/blacklist-nouveau.conf; then
  echo "Config 'blacklist nouveau' is not found in" \
    " /etc/modprobe.d/blacklist-nouveau.conf. Adding..."
  echo "blacklist nouveau" | sudo tee -a /etc/modprobe.d/blacklist-nouveau.conf \
    > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    echo "Config 'blacklist nouveau' added successfully to" \
      " /etc/modprobe.d/blacklist-nouveau.conf."
  else
    echo "Failed to add 'blacklist nouveau' to" \
      " /etc/modprobe.d/blacklist-nouveau.conf."
  fi
else
  echo "Config 'blacklist nouveau' already exists in" \
    " /etc/modprobe.d/blacklist-nouveau.conf."
fi

# REQUIRED - You must FIRST disable/blacklist nouveau to install NVIDIA 
# drivers, dracut is required to rebuild the initial ramdisk for reboot and 
# then reboot prior to nvidia driver install
if ! grep -q "options nouveau modeset=0" \
    /etc/modprobe.d/blacklist-nouveau.conf; then
  echo "Config 'options nouveau modeset=0' is not found in" \
    " /etc/modprobe.d/blacklist-nouveau.conf. Adding..."
  echo "options nouveau modeset=0" | \
    sudo tee -a /etc/modprobe.d/blacklist-nouveau.conf > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    echo "Config 'options nouveau modeset=0' added successfully to" \
      " /etc/modprobe.d/blacklist-nouveau.conf."
    echo "Rebuilding the initial ramdisk..."
    sudo dracut --force
    if [ $? -eq 0 ]; then
      echo "Initial ramdisk rebuilt successfully. Rebooting..."
      sudo reboot
    else
      echo "Failed to rebuild the initial ramdisk."
    fi
  else
    echo "Failed to add 'options nouveau modeset=0' to" \
      " /etc/modprobe.d/blacklist-nouveau.conf."
  fi
else
  echo "Config 'options nouveau modeset=0' already exists in" \
    " /etc/modprobe.d/blacklist-nouveau.conf."
fi

# REQUIRED - Install NVIDIA drivers for leapfrog gpu enablement
if ! rpm -q kmod-nvidia-latest-dkms > /dev/null 2>&1; then
  echo "NVIDIA drivers are not installed. Installing..."
  sudo dnf config-manager --add-repo "$NVIDIA_REPO" > /dev/null 2>&1
  sudo dnf module install nvidia-driver:latest-dkms -y > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    echo "NVIDIA drivers installed successfully."
    REBOOT=1
  else
    echo "Failed to install NVIDIA drivers."
  fi
else
  echo "NVIDIA drivers are already installed."
fi

# REQUIRED - Install nvidia-docker2 enables containers to access GPUs
if ! rpm -q nvidia-docker2 > /dev/null 2>&1; then
  echo "nvidia-docker2 is not installed. Installing..."
  sudo dnf install nvidia-docker2 -y > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    echo "nvidia-docker2 installed successfully. Restarting docker..."
    sudo systemctl restart docker > /dev/null 2>&1
    if [ $? -eq 0 ]; then
      echo "Docker restarted successfully."
      REBOOT=1
    else
      echo "Failed to restart docker."
    fi
  else
    echo "Failed to install nvidia-docker2."
  fi
else
  echo "nvidia-docker2 is already installed."
fi

# REQUIRED - needed for k8s tooling, zarf deployments, and packaging
if ! command -v zarf &> /dev/null; then
  echo "zarf is not installed. Installing..."
  curl -LO "$ZARF_URL" > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    chmod +x zarf_v0.29.0_Linux_amd64
    sudo mv zarf_v0.29.0_Linux_amd64 /usr/local/bin/zarf
    if [ $? -eq 0 ]; then
      echo "zarf installed successfully."
    else
      echo "Failed to move zarf to /usr/local/bin."
    fi
  else
    echo "Failed to download zarf."
  fi
elif ! zarf version &> /dev/null; then
  echo "Error: zarf is installed but not working. Please check the installation." >&2
  exit 1
else
  echo "zarf is already installed."
fi

# REQUIRED - Update /etc/hosts to include k3d-airgap.localhost; 
# required for DUBBD to deploy successfully; this is AMI dependent, however
# on multiple AMIs I tested the routing to localhost wasn't being done 
# automatically
if ! grep -q "127.0.0.1 k3d-airgap.localhost" /etc/hosts; then
  echo "Updating /etc/hosts..."
  echo "127.0.0.1 k3d-airgap.localhost" | sudo tee -a /etc/hosts > /dev/null
  if [ $? -eq 0 ]; then
    echo "Successfully updated /etc/hosts."
    REBOOT=1
  else
    echo "Failed to update /etc/hosts."
  fi
else
  echo "Entry 127.0.0.1 k3d-airgap.localhost already exists in /etc/hosts."
fi

############################ OPTIONAL QOL STEPS ###############################

# OPTIONAL - I used this  to pull leapfrog and build the Zarf package due to
# lack of a published package for use and constant changes to the codebase
if ! rpm -q git > /dev/null 2>&1; then
  echo "git is not installed. Installing git..."
  sudo dnf install git -y > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    echo "git installed successfully."
  else
    echo "Failed to install git."
  fi
else
  echo "git is already installed."
fi

# OPTIONAL - Install bind-utils, I needed this for troubleshooting and working
# through networking issues related to localhost routing for k3d/Docker
if ! rpm -q bind-utils > /dev/null 2>&1; then
  echo "bind-utils is not installed. Installing bind-utils..."
  sudo dnf install bind-utils -y > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    echo "bind-utils installed successfully."
  else
    echo "Failed to install bind-utils."
  fi
else
  echo "bind-utils is already installed."
fi

# OPTIONAL - Install flux, I ended up needing this to test helm charts, however
# I don't see this as being required for the deployment of DUBBD
if ! command -v flux &> /dev/null; then
  echo "Flux is not installed. Installing flux..."
  curl -s https://fluxcd.io/install.sh | sudo bash > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    echo "Flux installed successfully."
  else
    echo "Failed to install flux."
  fi
else
  echo "Flux is already installed."
fi

# OPTIONAL - Install kubectl if not already installed or not the latest version
# You don't technically need this and can use zarf tools aliased to k 
# or kubectl if you don't want to install kubectl separately
KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)

if ! command -v kubectl &> /dev/null; then
  CURRENT_VERSION="not installed"
else
  CURRENT_VERSION=$(kubectl version --client --short 2>&1 | \
    awk -Fv '/Client Version:/ { print $2 }')
fi

if ! command -v kubectl &> /dev/null || \
    [ "$CURRENT_VERSION" != "$KUBECTL_VERSION" ]; then
  echo "Kubectl is not installed or not the latest version." \
    "Installing/Updating kubectl..."
  curl -LO "https://dl.k8s.io/release/$KUBECTL_VERSION/bin/linux/amd64/kubectl" \
    > /dev/null 2>&1
  sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
  if [ $? -eq 0 ]; then
    echo "Kubectl installed/updated successfully."
    rm kubectl
  else
    echo "Failed to install/update kubectl."
  fi
else
  echo "Kubectl is already installed and is the latest version."
fi

# OPTIONAL - this is to enable autocompletion within bash for kubectl
if ! rpm -q bash-completion > /dev/null 2>&1; then
  echo "bash-completion is not installed. Installing bash-completion..."
  sudo dnf install bash-completion -y > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    echo "bash-completion installed successfully."
  else
    echo "Failed to install bash-completion."
    exit 1
  fi
else
  echo "bash-completion is already installed."
fi

if ! kubectl > /dev/null 2>&1; then
  echo "kubectl is not installed. Please install it first."
  exit 1
fi

echo "Enabling kubectl autocomplete..."
kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl > /dev/null

if [ $? -eq 0 ]; then
  echo "kubectl autocomplete enabled successfully."
else
  echo "Failed to enable kubectl autocomplete."
fi

# OPTIONAL - Create clusterOne directory, working dir for installation
if [ ! -d "clusterOne" ]; then
  echo "Creating directory clusterOne..."
  mkdir clusterOne
  if [ $? -eq 0 ]; then
    echo "Directory clusterOne created successfully."
  else
    echo "Failed to create directory clusterOne."
  fi
else
  echo "Directory clusterOne already exists."
fi

# OPTIONAL - Add aliases to ~/.bashrc for kubectl, kg, kgpa, and z
if ! grep -q "alias k='kubectl'" ~/.bashrc; then
  echo "Adding alias k='kubectl' to ~/.bashrc..."
  echo "alias k='kubectl'" >> ~/.bashrc
  echo "complete -F __start_kubectl k" >> ~/.bashrc
  if [ $? -eq 0 ]; then
    echo "Alias k='kubectl' added successfully."
  else
    echo "Failed to add alias k='kubectl' to ~/.bashrc."
  fi
else
  echo "Alias k='kubectl' already exists in ~/.bashrc."
fi

if ! grep -q "alias kg='kubectl get'" ~/.bashrc; then
  echo "Adding alias kg='kubectl get' to ~/.bashrc..."
  echo "alias kg='kubectl get'" >> ~/.bashrc
  if [ $? -eq 0 ]; then
    echo "Alias kg='kubectl get' added successfully."
  else
    echo "Failed to add alias kg='kubectl get' to ~/.bashrc."
  fi
else
  echo "Alias kg='kubectl get' already exists in ~/.bashrc."
fi

if ! grep -q "alias kgpa='kubectl get pods -A'" ~/.bashrc; then
  echo "Adding alias kgpa='kubectl get pods -A' to ~/.bashrc..."
  echo "alias kgpa='kubectl get pods -A'" >> ~/.bashrc
  if [ $? -eq 0 ]; then
    echo "Alias kgpa='kubectl get pods -A' added successfully."
  else
    echo "Failed to add alias kgpa='kubectl get pods -A' to ~/.bashrc."
  fi
else
  echo "Alias kgpa='kubectl get pods -A' already exists in ~/.bashrc."
fi

if ! grep -q "alias z='zarf'" ~/.bashrc; then
  echo "Adding alias z='zarf' to ~/.bashrc..."
  echo "alias z='zarf'" >> ~/.bashrc
  if [ $? -eq 0 ]; then
    echo "Alias z='zarf' added successfully."
  else
    echo "Failed to add alias z='zarf' to ~/.bashrc."
  fi
else
  echo "Alias z='zarf' already exists in ~/.bashrc."
fi

# Reboot if necessary
if [ $REBOOT -eq 1 ]; then
  echo "Rebooting..." >&2
  sudo reboot
fi

echo "Setup complete."