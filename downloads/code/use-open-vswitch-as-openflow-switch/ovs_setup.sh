#!/bin/bash
# ovs setup

# dependencies
sudo apt-get install git autoconf automake libtool -y

# get Open vSwitch project
git clone -b v2.5.4 https://github.com/openvswitch/ovs.git

# build Open vSwitch
cd ovs
./boot.sh
./configure
make && sudo make install

# load kernel module
sudo /sbin/modprobe openvswitch

# initialize the configuration database
sudo mkdir -p /usr/local/etc/openvswitch
sudo ovsdb-tool create /usr/local/etc/openvswitch/conf.db \
    vswitchd/vswitch.ovsschema
