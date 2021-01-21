#!/bin/bash
# ryu setup

# dependencies
sudo apt-get install git python-pip -y
sudo apt-get install gcc python-dev libffi-dev \
    libssl-dev libxml2-dev libxslt1-dev zlib1g-dev -y

# get Ryu controller and install
git clone https://github.com/osrg/ryu.git
cd ryu
sudo pip install .
sudo pip install --upgrade .
