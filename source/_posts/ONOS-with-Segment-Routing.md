---
title: ONOS with Segment Routing
date: 2018-05-26 21:09:39
tags:
    - ONOS
    - SDN
---

This tutorial is to run Segment Routing application in ONOS on a 2x2 leaf-spine topology built with Mininet. <!-- more -->

## Experiment Environment
I have run this test successfully on Ubuntu 16.04 with ONOS 1.12 and 1.14 two versions.

## Install And Run ONOS
Refer to [ONOS Wiki](https://wiki.onosproject.org/display/ONOS/Developer+Quick+Start).

### Enable Command `onos-netcfg`
Source this file to use command `onos-netcfg`.
```
$ sourc $ONOS_ROOT/tools/dev/bash_profile
```

Or you can simply add the line in `.bashrc`.

### Enable ONOS Applications
Enable necessary applications in ONOS shell.
```
onos> app activate drivers,openflow,netcfghostprovider,segmentrouting
```

Or you can simply add the following line in `.bashrc`.
```
export ONOS_APPS='drivers,openflow,netcfghostprovider,segmentrouting'
```

## Install Mininet
Refer to [Mininet Github page](https://github.com/mininet/mininet).

## 2x2 Leaf-Sping Topology
In this practice, we will run our segment routing application on 2x2 leaf-spine topology as the following picture.

<center>
{% img /images/onos-with-segment-routing/topology.png %}
</center>

Each leaf switches are attached with two hosts. The two subnets are 10.6.1.0/24 and 10.6.2.0/24.

## ONOS Configuration
We are required to configure three network elements in ONOS - devices, ports and hosts.

### Devices
```json
"devices" : {
    "of:0000000000000191" : {
        "segmentrouting" : {
            "name" : "Spine-R1",
            "ipv4NodeSid" : 101,
            "ipv4Loopback" : "10.6.3.254",
            "routerMac" : "00:00:00:00:03:80",
            "isEdgeRouter" : false,
            "adjacencySids" : []
        },
        "basic" : {
            "driver" : "ofdpa-ovs"
        }
    }
}
```

To config the switches as segment routers the following settings are needed to do.

- `of:0000000000000191`: Datapath ID (DPID) - ONOS uses this ID to configure corresponding switches.
- `segmentrouting`: Segment routing application specific parameters
- `name`: name of the switch
- `ipv4NodeSid`: Node segment ID
- `ipv4Lookback`: IP address of the loopback interface of the switch
- `routerMac`: MAC address of the loopback interface - In this implementation, this MAC address is used as src/dst MAC address in Ethernet headers for communication to other switches, instead of using the interface-MAC addresses.
- `isEdgeRouter`: The flag to determine the edge router
- `adjacencySids`: Adjacency segment ID - This is not used in this practice.
- `basic`: Basic parameters
- `driver`: Driver of the switch

### Ports
```json
"ports" : {
    "of:0000000000000101/3" : {
        "interfaces" : [
            {
                "ips" : [ "10.6.1.254/24" ],
                "vlan-untagged" : 20
            }
        ]
    }
}
```

The following is needed to configure links between segment routers and hosts.

- `of:0000000000000101/3`: Datapath Id and the port number
- `ips`: IP of the host which is connected to the switch and it's subnet
- `vlan-untagged`: VLAN tag number

### Hosts
```json
"hosts" : {
    "00:00:00:00:00:01/-1" : {
        "basic": {
            "ips": ["10.6.1.1"],
            "locations": ["of:0000000000000101/3"]
        }
    }
}
```

The following is needed to configure hosts.

- `00:00:00:00:00:01/-1`: Host MAC address and VLAN tag number - In this case, -1 means no VLAN tag
- `ips`: Host IP
- `locations`: The datapath and port number to which the host attaches

The configuration file are shown below.

{% include_code Configuration File onos-with-segment-routing/config.json %}

Load the configuration.
```
$ onos-netcfg <onos_ip> <config_file>
```

## Run Mininet
Here is the topology script to run in Mininet.

{% include_code Topology onos-with-segment-routing/topo.py %}

Run Mininet.
```
$ sudo mn --switch=ovs,protocols=OpenFlow13 --custom=topo.py --topo=mytopo --controller=remote,127.0.0.1:6653
```

Mininet will create a 2x2 leaf-spine fabric with OpenFlow1.3 enabled Open vSwitches and connect to the ONOS controller running at localhost.

## Test
We can run `pingall` at Mininet shell and verify the connectivity between all hosts.

<center>
{% img /images/onos-with-segment-routing/ping_result.png %}
</center>

## Check OpenFlow Table
Check flow tables in switches.
```
$ ovs-ofctl -O OpenFlow13 dump-flows <bridge>
```

Check group tables in switches.
```
$ ovs-ofctl -O OpenFlow13 dump-groups <bridge>
```

See the [Open vSwitch Manual](http://www.openvswitch.org/support/dist-docs/ovs-ofctl.8.txt) for more details.

To run the commands shell Mininet shell, type the following.
```
mininet> 2001 ovs-ofctl -O OpenFlow13 dump-flows "2001"
```

Trace the flow tables and group tables and you can see switches push and pop MPLS labels.

Here are some points I got.

- In this practice, switches did perform segment routing using MPLS labels to route.
- For packets crossing subnets, the leaf switch would only push MPLS labels of the egress edge switch, which was `ipv4NodeSid` we set in device configuration.
- As the packets arrived at spine switches, MPLS labels were popped. The reason was that for this 2x2 leaf-spine fabric, spine switches were called penultimate hop and would perform labels popping to reduce the load at egress switches.
- Since labels were popped at penultimate switches, the egress switches only needed to do IP table lookup without MPLS lookup, solving the Egress LSR Double Lookup problem.

The following picture shows labels of each flow in this practice.

<center>
{% img /images/onos-with-segment-routing/labels.png %}
</center>

## Update
After tracing the flows installed by Segment Routing application, configuration for hosts is not truly necessary. Segment Routing uses flow rules to match the subnet under switches, which is already included in port configuration, but not Ethernet or IP addresses.

Configuration with hosts omitted has been tested and packets could be correctly forwarded.
