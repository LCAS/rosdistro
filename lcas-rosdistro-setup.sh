#!/bin/bash

# ROS base install

# add repo 
sudo sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list'

# add key
sudo apt-key adv --keyserver hkp://ha.pool.sks-keyservers.net:80 --recv-key 421C365BD9FF1F717815A3895523BAEEB01FA116

# update
sudo apt-get update
sudo apt-get install ros-kinetic-ros-base

# config
echo "source /opt/ros/kinetic/setup.bash" >> ~/.bashrc
source ~/.bashrc

# LCAS REPO CONFIG

# Dependencies
sudo apt-get install apt-transport-https curl

# get key
curl -s http://lcas.lincoln.ac.uk/repos/public.key | sudo apt-key add -

# add repo
sudo apt-add-repository http://lcas.lincoln.ac.uk/ubuntu/main

# update packages
sudo apt-get update

#  Read Restricted Repo Password
echo -n "Type Password for L-CAS restricted repos (empty to skip):"
read -s password
echo

if [ -z "$password" ]
then
      echo "No passord provided. Skipping LCAS restricted repos."
else
      sudo apt-add-repository https://restricted:"$password"@lcas.lincoln.ac.uk/ubuntu/restricted
fi

# only for developers. 
sudo rosdep init
sudo curl -o /etc/ros/rosdep/sources.list.d/20-default.list https://raw.githubusercontent.com/LCAS/rosdistro/master/rosdep/sources.list.d/20-default.list
sudo curl -o /etc/ros/rosdep/sources.list.d/50-lcas.list https://raw.githubusercontent.com/LCAS/rosdistro/master/rosdep/sources.list.d/50-lcas.list
mkdir -p ~/.config/rosdistro && echo "index_url: https://raw.github.com/lcas/rosdistro/master/index.yaml" >> ~/.config/rosdistro/config.yaml
rosdep update

# Nice things
sudo apt-get install ssh openssh-server vim git python-pip tmux openvpn
sudo pip install -U tmule 

sudo curl -o /usr/local/bin/rmate https://raw.githubusercontent.com/aurora/rmate/master/rmate && sudo chmod +x /usr/local/bin/rmate

echo -e ""
echo -e "Install finished. And remember: \"A pull/push a day keeps bugs away\""
echo -e "Bye!"

