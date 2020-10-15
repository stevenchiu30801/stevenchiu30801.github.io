---
title: MEC in 5G Networks
date: 2020-10-15 22:22:41
tags:
    - 5G
    - MEC
---

This post is a note for integrating MEC in 5G networks. <!-- more -->

# Reference Architecture

<center>
{% img /images/mec-in-5g-networks/reference_architecture.png %}
</center>

## Architecture Diagram

- The MEC platform is deployed as a VNF
    - Consequently, the MEC platform should have it own lifecycle management
- The MEC applications appear as VNFs towards the ETSI NFV MANO components
- The virtualization infrastructure is deployed as an NFVI and is managed by a VIM
- The MEC platform manager (MEPM) is replaced by a MEC platform manager - NFV (MEPM-V) that delegates the VNF lifecycle management to one or more VNF managers (VNFM)
    - In short, MEPM may be treated as VNFM in ETSI NFV-MANO
- The MEC orchestrator (MEO) is replaced by a MEC application orchestrator (MEAO) that relies on the NFV orchestrator (NFVO) for resource orchestration and for orchestration of the set of MEC application VNFs as one or more NFV network services (NSs)
    - In short, MEO may be treated as NFVO in ETSI NFV-MANO

## MEC Platform

- Offer an environment where the MEC applications can discover, advertise, consume and offer MEC services
- Receive traffic rules from the MEC platform manager, applications, or services, and instructing the data plane accordingly. When supported, this includes the translation of tokens representing UEs in the traffic rules into specific IP addresses
    - The data plane may be UPFs in 5G core networks
- Host MEC services
- Provide access to persistent storage and time of day information

In my Opinion, the MEC platform, basically, is in charge of offering services (e.g. service registry, DNS handling or even providing radio network information, location services and bandwidth management) required by MEC applications and also controlling the traffic rules through the NEF-PCF-SMF route

## MEC Services

- A MEC service is a service provided and consumed either by the MEC platform or a MEC application
    - In microservice architecture, the MEC platform should be decoupled into several microservices
- When provided by an application, it can be registered in the list of services to the MEC platform over the Mp1 reference point
    - Here comes into the service registry and such functionality is similar to NRF in 5G SBA

# MEC in 5G Networks

<center>
{% img /images/mec-in-5g-networks/mec_in_5g_networks.png %}
</center>

## Selection and Re-location of UPF

<center>
{% img /images/mec-in-5g-networks/selection_re-location_of_upf.png 600 %}
</center>

- The MEC platform, or MEPM and MEO, as an AF can request the 5GC to select a local UPF near the target (R)AN node
- The 5GC can re-select a new local UPF more suitable to handle application traffic identified by MEC (AF)
    - Based on UE mobility and connectivity related events received from the AMF and SMF
- Refer to clause 5.6.7 Application Function influence on traffic routing in 3GPP TS 23.501 V16.6.0

## AF Influence on Traffic Routing

<center>
{% img /images/mec-in-5g-networks/af_influence_on_traffic_routing.png 600 %}
</center>

- MEC as an AF can influence traffic steering based on a wide set of different parameters
    - information to identify the traffic (DNN, S-NSSAI, AF-Service-Identifier, 5 tuple, etc.)
    - a reference ID to preconfigured routing information
    - a list of DNAIs (Data Network Access Identifier)
    - information about target UE(s)
    - etc.
- Refer to clause 5.6.7 Application Function influence on traffic routing in 3GPP TS 23.501 V16.6.0

Note: 5GC also allows MEC (AF) to request information about UEs

## Mobility Event Notifications

<center>
{% img /images/mec-in-5g-networks/mobility_event_notifications.png 600 %}
</center>

- 5GC allows MEC as an AF to
    - subscribe to UE mobility events that may affect traffic forwarding to MEC applications
    - receive notifications of UE mobility events affecting MEC application instances

## Concurrent Access to Local and Central DN

<center>
{% img /images/mec-in-5g-networks/concurrent_access_to_local_and_central_dn.png 800 %}
</center>

- Same UP session allows the UE to obtain content both from local server and central server
- No impact on UE and service continuity in case of Uplink Classifier (UL CL) is used, or alternatively for PDU sessions using IPv6 or IPv4v6, Branching Point function with Multi-homing concept
- Refer to clause 5.6.4 Single PDU Session with multiple PDU Session Anchors in 3GPP TS 23.501 V16.6.0
