---
title: SR-IOV CNI on Kubernetes
date: 2020-02-07 19:43:23
tags:
    - CNI
    - Kubernetes
    - SR-IOV
---

Single Root I/O Virtualization (SR-IOV) is a acceleration technique in virtualized environment. This post is a setup guide for the use of SR-IOV CNI on Kubernetes. <!-- more -->

# Comparison with DPDK

See [DPDK vs SR-IOV for NFV? – Why a wrong decision can impact performance!](https://www.telcocloudbridge.com/blog/dpdk-vs-sr-iov-for-nfv-why-a-wrong-decision-can-impact-performance/)

# Usage

Please refer to [Intel - SR-IOV Configuration Guide](https://www.intel.com/content/www/us/en/embedded/products/networking/xl710-sr-iov-config-guide-gbe-linux-brief.html) and [GitHub - intel/sriov-network-device-plugin](https://github.com/intel/sriov-network-device-plugin)# workflow

## SR-IOV Configuration

1. Enable I/O Memory Management Unit (IOMMU) support

    ```bash
    # Enable IOMMU support for linux kernel
    # Update Grub `GRUB_CMDLINE_LINUX` with `intel_iommu=on`
    $ cat /etc/default/grub
    ...
    GRUB_CMDLINE_LINUX="intel_iommu=on"

    $ sudo update-grub
    $ sudo reboot

    # Check if IOMMU is correctly enabled
    $ dmesg | grep IOMMU
    [    0.000000] DMAR: IOMMU enabled
    ```

2. Load device's kernel module

    For [Intel® Ethernet Server Adapter I350-T2](https://ark.intel.com/content/www/us/en/ark/products/59062/intel-ethernet-server-adapter-i350-t2.html), VF driver is included in Ubuntu Xenial distribution

    One can simply load it

    ```bash
    # Check which driver is used by the adapter
    $ ethtool -i enp1s0f0
    driver: igb
    version: 5.4.0-k

    firmware-version: 1.67, 0x80000d6a, 15.0.27
    expansion-rom-version: 
    bus-info: 0000:01:00.0
    supports-statistics: yes
    supports-test: yes
    supports-eeprom-access: yes
    supports-register-dump: yes
    supports-priv-flags: yes

    # Check available driver, see https://unix.stackexchange.com/a/184880
    $ find /lib/modules/$(uname -r) -type f -name '*.ko' | grep igb
    /lib/modules/4.15.0-76-generic/kernel/drivers/net/ethernet/intel/igb/igb.ko
    /lib/modules/4.15.0-76-generic/kernel/drivers/net/ethernet/intel/igbvf/igbvf.ko

    # Load kernel module, PF driver (igb) and VF driver (igbvf)
    $ modprobe igb
    # It is not necessary to load VF driver,
    # since it would be automatically loaded upon creating VFs later
    $ modprobe igbvf
    ```

    If you want to use the latest driver, download, compile and then load it

3. Create VFs

    ```bash
    # Check maximum number of VFs supported by the adapter
    $ cat /sys/class/net/enp1s0f0/device/sriov_totalvfs
    7

    # Create VFs to `sriov_numvfs`
    $ echo 4 > /sys/class/net/enp1s0f0/device/sriov_numvfs
    # echo 4 | sudo tee /sys/class/net/enp1s0f0/device/sriov_numvfs
    ```

    To ensure number of VFs are created each time the server is power-cycled (not verified)

    ```bash
    # Append the creating VFs command to `rc.local` file
    $ cat /etc/rc.local
    #!/bin/bash

    echo 4 > /sys/class/net/<device_name>/device/sriov_numvfs
    ```

4. Confirm VFs are created

    ```bash
    # Confirm VFs are created
    # Each PCI device is identified by a unique slot name ([domain:]bus:device.function)
    # See http://manpages.ubuntu.com/manpages/trusty/man8/lspci.8.html for more information
    $ lspci | grep Ethernet
    01:00.0 Ethernet controller: Intel Corporation I350 Gigabit Network Connection (rev 01)
    01:00.1 Ethernet controller: Intel Corporation I350 Gigabit Network Connection (rev 01)
    # The four devices below are created VFs
    02:10.0 Ethernet controller: Intel Corporation I350 Ethernet Controller Virtual Function (rev 01)
    02:10.4 Ethernet controller: Intel Corporation I350 Ethernet Controller Virtual Function (rev 01)
    02:11.0 Ethernet controller: Intel Corporation I350 Ethernet Controller Virtual Function (rev 01)
    02:11.4 Ethernet controller: Intel Corporation I350 Ethernet Controller Virtual Function (rev 01)
    05:00.0 Ethernet controller: Realtek Semiconductor Co., Ltd. RTL8111/8168/8411 PCI Express Gigabit Ethernet Controller (rev 15)

    # Check VF MAC address assignment
    $ ip link show 
    1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN mode DEFAULT group default qlen 1000
        link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    2: enp5s0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq state UP mode DEFAULT group default qlen 1000
        link/ether 4c:ed:fb:cb:bc:28 brd ff:ff:ff:ff:ff:ff
    3: enp1s0f0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP mode DEFAULT group default qlen 1000
        link/ether a0:36:9f:39:be:32 brd ff:ff:ff:ff:ff:ff
        vf 0 MAC 66:6e:2d:05:55:12, spoof checking on, link-state auto
        vf 1 MAC 6a:8b:4a:98:64:7e, spoof checking on, link-state auto
        vf 2 MAC 46:6b:c9:b5:dc:a8, spoof checking on, link-state auto
        vf 3 MAC 96:12:1f:38:8b:78, spoof checking on, link-state auto
    4: enp1s0f1: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc mq state DOWN mode DEFAULT group default qlen 1000
        link/ether a0:36:9f:39:be:33 brd ff:ff:ff:ff:ff:ff
    5: docker0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN mode DEFAULT group default 
        link/ether 02:42:8b:85:39:32 brd ff:ff:ff:ff:ff:ff
    6: enp2s16: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq state UP mode DEFAULT group default qlen 1000
        link/ether 66:6e:2d:05:55:12 brd ff:ff:ff:ff:ff:ff
    7: enp2s16f4: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq state UP mode DEFAULT group default qlen 1000
        link/ether 6a:8b:4a:98:64:7e brd ff:ff:ff:ff:ff:ff
    8: enp2s17: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq state UP mode DEFAULT group default qlen 1000
        link/ether 46:6b:c9:b5:dc:a8 brd ff:ff:ff:ff:ff:ff
    9: enp2s17f4: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq state UP mode DEFAULT group default qlen 1000
        link/ether 96:12:1f:38:8b:78 brd ff:ff:ff:ff:ff:ff
    ```

## Additional Information

```bash
# List network hardware
$ lshw -class network -businfo
Bus info          Device           Class          Description
=============================================================
pci@0000:01:00.0  enp1s0f0         network        I350 Gigabit Network Connection
pci@0000:01:00.1  enp1s0f1         network        I350 Gigabit Network Connection
pci@0000:05:00.0  enp5s0           network        RTL8111/8168/8411 PCI Express Gigabit Ethernet Controller
pci@0000:02:10.0  enp2s16          network        Illegal Vendor ID
pci@0000:02:10.4  enp2s16f4        network        Illegal Vendor ID
pci@0000:02:11.0  enp2s17          network        Illegal Vendor ID
pci@0000:02:11.4  enp2s17f4        network        Illegal Vendor ID
```

```bash
# Display PCI device in verbose format using slot name
$ lspci -vmm -s 01:00.0
Slot:   01:00.0
Class:  Ethernet controller
Vendor: Intel Corporation
Device: I350 Gigabit Network Connection
SVendor:        Intel Corporation
SDevice:        Ethernet Server Adapter I350-T2
Rev:    01
```

```bash
# A list of all known PCI ID's (vendors, devices, classes and subclasses)
$ cat /usr/share/misc/pci.ids | grep "Intel Corporation"
8086  Intel Corporation

$ cat /usr/share/misc/pci.ids | grep "I350 Gigabit Network Connection"
        1521  I350 Gigabit Network Connection

# Display PCI device in verbose format using vendor and device ID
$ lspci -vmm -d 8086:1521
Slot:   01:00.0
Class:  Ethernet controller
Vendor: Intel Corporation
Device: I350 Gigabit Network Connection
SVendor:        Intel Corporation
SDevice:        Ethernet Server Adapter I350-T2
Rev:    01

Slot:   01:00.1
Class:  Ethernet controller
Vendor: Intel Corporation
Device: I350 Gigabit Network Connection
SVendor:        Intel Corporation
SDevice:        Ethernet Server Adapter I350-T2
Rev:    01
```

## Work with Kubernetes

Please refer to [GitHub - intel/sriov-network-device-plugin](https://github.com/intel/sriov-network-device-plugin)#Quick Start

1. Build SR-IOV CNI

    ```bash
    $ git clone https://github.com/intel/sriov-cni.git
    $ cd sriov-cni
    $ make
    $ cp build/sriov /opt/cni/bin
    ```

2. Build and run SR-IOV network device plugin

    ```bash
    $ git clone https://github.com/intel/sriov-network-device-plugin.git
    $ cd sriov-network-device-plugin
    $ make
    $ make image
    ```

3. Create a ConfigMap that defines SR-IOV resrouce pool configuration

    ```bash
    # `vendors` and `devices` in `selectors` have not verified yet
    # See https://github.com/intel/sriov-network-device-plugin#configurations
    $ cat deployment/configMap.yaml
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: sriovdp-config
      namespace: kube-system
    data:
      config.json: |
        {
            "resourceList": [{
                    "resourceName": "intel_sriov",
                    "selectors": {
                                            "vendors": ["8086"],
                                            "devices": ["1521"],
                        "pfName": ["enp1s0f0"]
                    }
                }
            ]
        }
    $ kubectl create -f deployments/configMap.yaml
    ```

4. Deploy SRIOV network device plugin Daemonset

    ```bash
    $ kubectl create -f deployments/k8s-v1.16/sriovdp-daemonset.yaml
    ```

5. Check the allocatable resource for the node

    ```bash
    $ kubectl get node <node> -o json | jq '.status.allocatable'
    {
      "cpu": "6",
      "ephemeral-storage": "424282646236",
      "hugepages-1Gi": "0",
      "hugepages-2Mi": "0",
      "intel.com/intel_sriov": "5",
      "memory": "32676196Ki",
      "pods": "110"
    }
    ```

6. Install one compatible CNI meta plugin, which is Multus here
7. Create the SRIOV Network CRD

    ```bash
    $ cat deployments/sriov-crd.yaml
    apiVersion: "k8s.cni.cncf.io/v1"
    kind: NetworkAttachmentDefinition
    metadata:
      name: sriov-net1
      annotations:
        k8s.v1.cni.cncf.io/resourceName: intel.com/intel_sriov
    spec:
      config: '{
      "type": "sriov",
      "cniVersion": "0.3.1",
      "name": "sriov-network",
      "ipam": {
        "type": "host-local",
        "subnet": "192.168.3.0/24"
      },
      "args": {
        "cni": {
          "ips": ["192.168.3.10"]
        }
      }
    }'
    $ kubectl create -f deployments/sriov-crd.yaml
    ```

8. Create deployment/pod using the SR-IOV interface

    ```bash
    $ cat deployment.yaml
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: test-deployment
      labels:
        app: test
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: test
      template:
        metadata:
          labels:
            app: test
          annotations:
            k8s.v1.cni.cncf.io/networks: sriov-net1
        spec:
          containers:
            - name: test
              image: ubuntu:16.04
              imagePullPolicy: IfNotPresent
              command: ["/bin/bash"]
              stdin: true
              tty: true
              resources:
                requests:
                  intel.com/intel_sriov: '1' 
                limits:
                  intel.com/intel_sriov: '1'
    $ kubectl apply -f deployment.yaml
    ```

# Troubleshooting

## Cannot Configure VFs

### Problem

```bash
$ echo 4 > /sys/class/net/enp2s0f1/device/sriov_numvfs
-bash: echo: write error: Cannot allocate memory

$ dmesg
... can't enable 4 VFs (bus 02 out of range of [bus 01])
```

### Solution

```bash
# Add `pci=assign-busses` to Grub
$ cat /etc/default/grub
...
GRUB_CMDLINE_LINUX="intel_iommu=on pci=assign-busses"

# Update Grub and reboot
$ sudo update-grub
$ sudo reboot
```

Also see

- [Bug 1223376 - not enough MMIO resources for SR-IOV](https://bugzilla.redhat.com/show_bug.cgi?id=1223376)
- [SRIOV fails with "SR-IOV: bus number out of range"](https://patchwork.ozlabs.org/patch/30000/#73079)
- [创建vf报错，问题求助](https://www.sdnlab.com/community/question/dpdk/397)

# Reference

- [GitHub - intel/sriov-network-device-plugin](https://github.com/intel/sriov-network-device-plugin)
- [Intel - SR-IOV Configuration Guide](https://www.intel.com/content/www/us/en/embedded/products/networking/xl710-sr-iov-config-guide-gbe-linux-brief.html)
- [gitlab.com/nctuwinlab/0556186-kubefree5GC/kube-free5gc-installer/blob/master/notes/NCTU-new/kubecordA.md](http://gitlab.com/nctuwinlab/0556186-kubefree5GC/kube-free5gc-installer/blob/master/notes/NCTU-new/kubecordA.md)
