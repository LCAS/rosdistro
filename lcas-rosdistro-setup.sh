#!/bin/bash

set -x

if [ $(id -u)  = "0" ]; then 
      echo "running as root"
      export DEBIAN_FRONTEND=noninteractive
      SUDO=""
else
      SUDO="sudo"
fi

$SUDO apt-get update
$SUDO apt-get install -y lsb-release curl python-software-properties software-properties-common

# ROS base install

# add repo 
$SUDO sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list'

# add key
$SUDO apt-key adv --keyserver hkp://ha.pool.sks-keyservers.net:80 --recv-key 421C365BD9FF1F717815A3895523BAEEB01FA116

# update
$SUDO apt-get update
$SUDO apt-get install -y ros-kinetic-ros-base

# config
echo "source /opt/ros/kinetic/setup.bash" >> ~/.bashrc
source ~/.bashrc

# LCAS REPO CONFIG

# Dependencies
$SUDO apt-get install -y apt-transport-https curl

# get key
curl -s http://lcas.lincoln.ac.uk/repos/public.key | $SUDO apt-key add -

# add repo
$SUDO apt-add-repository http://lcas.lincoln.ac.uk/ubuntu/main

# update packages
$SUDO apt-get update


if [ -z "$PS1" ]; then
      echo This shell is not interactive
else
      #  Read Restricted Repo Password
      echo -n "Type Password for L-CAS restricted repos (empty to skip):"
      read -s password
      echo
fi

if [ -z "$password" ]
then
      echo "No passord provided. Skipping LCAS restricted repos."
else
      $SUDO apt-add-repository https://restricted:"$password"@lcas.lincoln.ac.uk/ubuntu/restricted
fi

# only for developers. 
$SUDO rosdep init
$SUDO curl -o /etc/ros/rosdep/sources.list.d/20-default.list https://raw.githubusercontent.com/LCAS/rosdistro/master/rosdep/sources.list.d/20-default.list
$SUDO curl -o /etc/ros/rosdep/sources.list.d/50-lcas.list https://raw.githubusercontent.com/LCAS/rosdistro/master/rosdep/sources.list.d/50-lcas.list
mkdir -p ~/.config/rosdistro && echo "index_url: https://raw.github.com/lcas/rosdistro/master/index.yaml" >> ~/.config/rosdistro/config.yaml
rosdep update

# Nice things
$SUDO apt-get install -y ssh openssh-server vim git python-pip tmux openvpn
$SUDO pip install -U tmule 

$SUDO curl -o /usr/local/bin/rmate https://raw.githubusercontent.com/aurora/rmate/master/rmate && $SUDO chmod +x /usr/local/bin/rmate

echo -e ""
echo -e "Install finished. And remember: \"A pull/push a day keeps bugs away\""
echo -e "Bye!"

