---
title: Use Open vSwitch as OpenFlow Switch
date: 2018-04-14 19:35:11
tags:
    - OvS
    - SDN
---

This is the second experiment in the course Software-Defined Network at NCTU. The requirement is to use virtual machine to build a simple topology with an OpenFlow switch emulated by Open vSwitch. <!-- more -->

The topology is an Open vSwitch connected with a Ryu controller and two hosts. The following picture is the network settings.

<center>
{% img /images/use-open-vswitch-as-openflow-switch/topology.png topology %}
</center>

## Install VirtualBox and Vagrant
I use VirtualBox to deploy the topology.
```
$ wget https://download.virtualbox.org/virtualbox/5.2.8/virtualbox-5.2_5.2.8-121009~Ubuntu~xenial_amd64.deb
$ dpkg -i virtualbox-5.2_5.2.8-121009~Ubuntu~xenial_amd64.deb
```

Since my computer is dual boot, I encountered the following error messege when installing it.
```
vboxdrv.sh: failed: modprobe vboxdrv failed. Please use 'dmesg' to find out why.
```
[Here](https://askubuntu.com/a/900121) is the solution for your reference.

Vagrant is a command line tool to manage virtual machines. In this experiment I use Vagrant to set up my VirtualBox environments.

Reference [official guide](https://www.vagrantup.com/docs/installation/source.html) to install Vagrant from source.

Or you can simply install it by using `apt-get`.

## Use Vagrant to Build VMs
See the [official tutorial](https://www.vagrantup.com/docs/).

## Some Setup on VMs
There are some system and network setups in Vagrantfile.

To acces the Ryu controller web UI from host, we need to set up port forwarding. Ryu web UI is open at port 8080, which is set up in next section.
```
ryu.vm.network "forwarding_port", guest: 8080, host: 8080
```

Adjust the memory size to 1024 MB.
```
ryu.vm.provider :virtualbox do |vb|
    vb.memory = 1024
end
```
This adjustment is also done in Open vSwitch VM.

In Open vSwitch VM, set promiscuous mode to `Allow All` at two adapters connecting to hosts. This allow the traffic between hosts and the switch.
```
ovs.vm.rpovider :virtualbox do |vb|
    vb.customize ["modifyvm", :id, "--nicpromisc3", "allow-all"]
    vb.customize ["modifyvm", :id, "--nicpromisc4", "allow-all"]
end
```
The number after `--nicpromisc` is the network interface card ID. The default NIC's ID is set to 1, and every NIC you add has the ID incremented by 1.

## Set up VMs' Environment
Set up Open vSwitch. You can reference the [installation guide](https://github.com/openvswitch/ovs/blob/master/Documentation/intro/install/general.rst).
{% include_code OvS Setup use-open-vswitch-as-openflow-switch/ovs_setup.sh %}

Run up Open vSwitch daemon and config it to be an OpenFlow switch.
{% include_code OvS Config use-open-vswitch-as-openflow-switch/ovs_config.sh %}

Set up Ryu controller.
{% include_code Ryu Setup use-open-vswitch-as-openflow-switch/ryu_setup.sh %}

Run Ryu web UI.
```
$ ryu-manager --observe-links \
    ryu/app/gui_topology/gui_topology.py \
    ryu/app/simple_switch_websocket_13.py
```
or
```
$ PYTHONPATH=. ./bin/ryu --observe-links \
    ryu/app/gui_topology/gui_topology.py \
    ryu/app/simple_switch_websocket_13.py
```
Now you can see the Ryu web UI at port 8080.

<center>
{% img /images/use-open-vswitch-as-openflow-switch/ryu_web_ui.png RyuWebUI %}
</center>

## Vagrantfile
Following is the Vagrantfile to set up the environment.
{% include_code Vagrant file use-open-vswitch-as-openflow-switch/Vagrantfile %}

If you set up and configure correctly, you could ping the host from the other host.

## Issues
Shutdown the OvS daemon correctly.
```
$ sudo /usr/local/share/openvswitch/scripts/ovs-ctl stop
```
