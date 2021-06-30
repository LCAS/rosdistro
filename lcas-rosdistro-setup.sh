#!/bin/bash

set -x

if [ $(id -u)  = "0" ]; then 
      echo "running as root"
      export DEBIAN_FRONTEND=noninteractive
      SUDO=""
else
      SUDO="sudo -H"
fi

$SUDO apt-get update
$SUDO apt-get install -y lsb-release curl python-software-properties software-properties-common python-rosdep

DISTRIBUTION=$(lsb_release -sc)
export ROS_DISTRIBUTION="kinetic"

case "$DISTRIBUTION" in
        xenial)
            export ROS_DISTRIBUTION="kinetic"
            ;;
         
        bionic)
            export ROS_DISTRIBUTION="melodic"
            ;;
        *)
            echo "unknown distribution $DISTRIBUTION" >&2
            exit 1
esac

echo "identified distribution $DISTRIBUTION, so ROS_DISTRIBUTION is $ROS_DISTRIBUTION"

# ROS base install

# add repo 
$SUDO sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list'

# add key
$SUDO apt-key adv --keyserver 'hkp://keyserver.ubuntu.com:80' --recv-key C1CF6E31E6BADE8868B172B4F42ED6FBAB17C654

# update
$SUDO apt-get update
$SUDO apt-get install -y ros-$ROS_DISTRIBUTION-ros-base

# config

if grep -q "source /opt/ros/$ROS_DISTRIBUTION/setup.bash" ~/.bashrc; then
      echo "ROS already configured in .bashrc"
else
      echo "source /opt/ros/$ROS_DISTRIBUTION/setup.bash" >> ~/.bashrc
fi

source ~/.bashrc

# LCAS REPO CONFIG

# Dependencies
$SUDO apt-get install -y apt-transport-https curl

# get key
curl -s http://lcas.lincoln.ac.uk/repos/public.key | $SUDO apt-key add -

# add repo
#$SUDO apt-add-repository http://lcas.lincoln.ac.uk/ubuntu/main
$SUDO sh -c 'echo "deb http://lcas.lincoln.ac.uk/ubuntu/main $(lsb_release -sc) main" > /etc/apt/sources.list.d/lcas-latest.list'

if [ "$DISTRIBUTION" = "bionic" ]; then
      curl -s https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/cuda-ubuntu1804.pin | $SUDO tee /etc/apt/preferences.d/cuda-repository-pin-600
      $SUDO apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/7fa2af80.pub
      $SUDO add-apt-repository "deb http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/ /"
fi

# update packages
$SUDO apt-get update


if [ -z "$PS1" ]; then
      echo This shell is not interactive
else
      #  Read Restricted Repo Password
      echo -n "Type Password for L-CAS restricted commercial repos (empty to skip, you usually don't need this unless in very special cases):"
      read -s password
      echo
fi

if [ -z "$password" ]
then
      echo "No passord provided. Skipping LCAS restricted commercial repos."
else
      $SUDO apt-add-repository https://restricted:"$password"@lcas.lincoln.ac.uk/ubuntu/restricted
fi

# only for developers. 
$SUDO rosdep init
$SUDO curl -o /etc/ros/rosdep/sources.list.d/20-default.list https://raw.githubusercontent.com/LCAS/rosdistro/master/rosdep/sources.list.d/20-default.list
$SUDO curl -o /etc/ros/rosdep/sources.list.d/50-lcas.list https://raw.githubusercontent.com/LCAS/rosdistro/master/rosdep/sources.list.d/50-lcas.list
mkdir -p ~/.config/rosdistro && echo "index_url: https://raw.github.com/lcas/rosdistro/master/index-v4.yaml" > ~/.config/rosdistro/config.yaml
rosdep update

# Nice things
$SUDO apt-get install -y ssh openssh-server vim git python-pip tmux openvpn python-wstool
$SUDO pip install web.py==0.51
$SUDO pip install tmule

$SUDO curl -o /usr/local/bin/rmate https://raw.githubusercontent.com/aurora/rmate/master/rmate && $SUDO chmod +x /usr/local/bin/rmate

echo -e ""
echo -e "Install finished. And remember: \"A pull/push a day keeps bugs away\""
echo -e "Bye!"


