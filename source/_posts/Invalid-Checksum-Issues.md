---
title: Invalid Checksum Issues
date: 2020-03-04 19:14:59
tags:
    - Debug
---

I often encounter invalid checksum issues in containerized deployment. This post records several root causes and solutions of such issues from other developers. <!-- more -->

# Possibly Common Root Causes

- Packets get corrupted
- veth bugs in containerized environment

or

- Tx/Rx offloading on NIC is enabled (which means you trust hardware/NIC would do something for you, and thus the software/OS would not take care of those)
- Checksum is not recalculated by NICs

Then the destination gets the wrong packets

---

# Case 1 - [Linux kernel bug delivers corrupt TCP/IP data to Mesos, Kubernetes, Docker containers](https://tech.vijayp.ca/linux-kernel-bug-delivers-corrupt-tcp-ip-data-to-mesos-kubernetes-docker-containers-4986f88f7a19)

## Incident

Applications of Twitter in containers received packets with wrong checksum

Disabling Rx checksum offloading on veth device would fix the problem

## Root Cause

- 10% of packets could be corrupted on the wire
- Bugs on veth Kernel module

Quote the blog:

```
In the kernel, packets that arrive from real hardware devices have ip_summed set to CHECKSUM_UNNECESSARY if the hardware verified the checksums, or CHECKSUM_NONE if the packet is bad or it was unable to verify it.

Code in veth.c replaced CHECKSUM_NONE with CHECKSUM_UNNECESSARY — this resulted in checksums that should have been verified and rejected by software to be silently ignored.
```

---

# Case 2 - [OVS + DPDK + Docker 共同玩耍](https://www.hwchiu.com/ovs-dpdk-docker.html)

[Part 1](https://hwchiu.com/ovs-dpdk-docker.html)

[Part 2](https://hwchiu.com/ovs-dpdk-docker-2.html)

## Incident

{% img /images/invalid-checksum-issues/case2.png %}

The OvS on Linux host (say Host 1) is applied with DPDK, which is an userspace datapath

Each nodes could reach others using `ping` (ICMP)

However, TCP packets from Container 1 could not reach both Container 2 and outside host (say Host 2)

The checksum in TCP packets was found corrupted

- If disabled DPDK, everything works
- If disabled Tx/Rx Offloading on Container 1, everything works

## Root Cause

The root cause is depicted in Case 3, which has the same scenario

Actually, there are some conflicts between the discovered root cause of Case 2 and 3

---

# Case 3 - [OVS Deep Dive 5: Datapath and TX Offloading](https://arthurchiao.github.io/blog/ovs-deep-dive-5-datapath-tx-offloading/?fbclid=IwAR13kbYeRqMa3_VwWB4lRsCgPjr4aP6Z1TvGz2z4TluS3hZ-M2A-ht1NdpY)

## Incident

{% img /images/invalid-checksum-issues/case3.png 600 %}

TCP Packets could not be transmitted between Instance A and B

## Root Cause

Quote the blog:

```
When TX offload is enabled on instance’s tap devices (default setting), OVS will utilize physical NICs for checksum calculating for each packet sent out from instance, and this is handled by the kernel module openvswitch.ko.

A problem occurs when TX offloading is enabled while OVS bridge uses Userspace Datapath: Userspace Datapath does not support TX offloading.

... A enables TCP TX offloading, so the packet is sent to OVS with faked TCP checksum; while OVS with Userspace Datapath does not do TCP checksum, the packet is sent out (or forwarded to B) with wrong checksum; ...

In summary, if deploy OVS with DPDK enabled, you have to turn off TX offload flags in your instances. In this case, instances themselves will take care of the checksum calculating.
```
