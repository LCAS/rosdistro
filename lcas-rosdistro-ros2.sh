#!/bin/bash

set -x
set -e

if [ $(id -u)  = "0" ]; then 
      echo "running as root"
      export DEBIAN_FRONTEND=noninteractive
      SUDO=""
else
      SUDO="sudo -H"
fi

$SUDO apt-get update
$SUDO apt-get install -y lsb-release curl wget python3-software-properties python3-pip lsb-release curl software-properties-common build-essential apt-transport-https curl devscripts ssh openssh-server vim nano git tmux openvpn 

DISTRIBUTION=$(lsb_release -sc||echo "unknown")
export ROS_DISTRIBUTION="humble"

case "$DISTRIBUTION" in
        jammy)
            export ROS_DISTRIBUTION="humble"
            ;;         
        *)
            echo "unknown distribution '$DISTRIBUTION'" >&2
            exit 1
esac

echo "identified distribution $DISTRIBUTION, so ROS_DISTRIBUTION is $ROS_DISTRIBUTION"

$SUDO sh -c 'echo "deb http://packages.ros.org/ros2/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list' 
curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | $SUDO apt-key add -

$SUDO sh -c 'echo "deb https://lcas.lincoln.ac.uk/apt/lcas $(lsb_release -sc) lcas" > /etc/apt/sources.list.d/lcas-latest.list' 
curl -s https://lcas.lincoln.ac.uk/apt/repo_signing.gpg | $SUDO apt-key add -



# ADD GAZEBO REPO
$SUDO sh -c 'echo "deb http://packages.osrfoundation.org/gazebo/ubuntu-stable `lsb_release -cs` main" > /etc/apt/sources.list.d/gazebo-stable.list'
wget https://packages.osrfoundation.org/gazebo.key -O - | $SUDO apt-key add -




# docker
$SUDO install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | $SUDO gpg --dearmor -o /etc/apt/keyrings/docker.gpg
$SUDO chmod a+r /etc/apt/keyrings/docker.gpg

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  $SUDO tee /etc/apt/sources.list.d/docker.list > /dev/null



distro=$DISTRIBUTION
arch=`arch`

# if no CUDA repos enabled, enable them
if ! apt-cache show cuda > /dev/null 2>&1; then
      if [ "$distro" == "jammy" ]; then
            echo "setup CUDA"
            nvidia_name=ubuntu2204
            wget https://developer.download.nvidia.com/compute/cuda/repos/${nvidia_name}/${arch}/cuda-archive-keyring.gpg
            $SUDO mv cuda-archive-keyring.gpg /usr/share/keyrings/cuda-archive-keyring.gpg
            echo "deb [signed-by=/usr/share/keyrings/cuda-archive-keyring.gpg] https://developer.download.nvidia.com/compute/cuda/repos/${nvidia_name}/${arch}/ /" | $SUDO tee /etc/apt/sources.list.d/cuda-${nvidia_name}-${arch}.list
            curl -s https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/cuda-ubuntu1804.pin | $SUDO tee /etc/apt/preferences.d/cuda-repository-pin-600
      else
            echo "CUDA repos not configured for ${distro}"
      fi
fi

# update
$SUDO apt-get update
$SUDO apt-get install -y ros-$ROS_DISTRIBUTION-ros-base python3-rosdep

# config
if grep -q "source /opt/ros/$ROS_DISTRIBUTION/setup.bash" ~/.bashrc; then
      echo "ROS already configured in .bashrc"
else
      echo "source /opt/ros/$ROS_DISTRIBUTION/setup.bash" >> ~/.bashrc
fi

source ~/.bashrc


# only for developers. 
$SUDO rosdep init
$SUDO curl -o /etc/ros/rosdep/sources.list.d/20-default.list https://raw.githubusercontent.com/LCAS/rosdistro/master/rosdep/sources.list.d/20-default.list
$SUDO curl -o /etc/ros/rosdep/sources.list.d/50-lcas.list https://raw.githubusercontent.com/LCAS/rosdistro/master/rosdep/sources.list.d/50-lcas.list
mkdir -p ~/.config/rosdistro && echo "index_url: https://raw.github.com/lcas/rosdistro/master/index-v4.yaml" > ~/.config/rosdistro/config.yaml
rosdep update

# Nice things
#$SUDO apt-get install -y ssh openssh-server vim git python-pip tmux openvpn python-wstool
$SUDO pip install -U tmule pip

echo -e ""
echo -e "Install finished. And remember: \"A pull/push a day keeps bugs away\""
echo -e "Bye!"


