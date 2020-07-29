#!/bin/bash
# ovs config

# run up the daemon
sudo ovsdb-server --remote=punix:/usr/local/var/run/openvswitch/db.sock \
    --remote=db:Open_vSwitch,Open_vSwitch,manager_options \
    --private-key=db:Open_vSwitch,SSL,private_key \
    --certificate=db:Open_vSwitch,SSL,certificate \
    --bootstrap-ca-cert=db:Open_vSwitch,SSL,ca_cert \
    --pidfile --detach

# initialize the database using ovs-vsctl
# This is only necessary the first time after creating the database
sudo ovs-vsctl --no-wait init

# start the daemon
sudo ovs-vswitchd --pidfile --detach

# set Open vSwitch to be an Openflow switch
sudo ovs-vsctl add-br br0

sudo ovs-vsctl add-port br0 eth2
sudo ovs-vsctl add-port br0 eth3

sudo ovs-vsctl set-controller br0 tcp:192.168.33.33:6633
