---
title: "My Projects"
---

<center>
  <h1>A Cloud Native Management and Orchestration Framework for 5G End-to-end Network Slicing</h1>
  <small>
    <div>November 2019 to May 2020</div>
    <div>
      <a href="https://github.com/stevenchiu30801/bans5gc-operator-framework">
        https://github.com/stevenchiu30801/bans5gc-operator-framework
      </a>
    </div>
  </small>
</center>
<br>

The project provides a Cloud Native management and orchestration (MANO) framework for automation of end-to-end (E2E) network slicing, which is also my research in Master degree.

The E2E network slices (NS) consist of 5G core network (CN) slices and transport network (TN) slices.

- The CN slicing follows the slicing mechanism in 3GPP specifications, including slice selection and assignment
- The TN slicing integrates state-of-the-art [P4-Enabled Bandwidth Management](https://ieeexplore.ieee.org/document/8892909) to enforce bandwidth control on the TN

The MANO framework adopts all open-source approaches.

- Kubernetes and Operator pattern as container and service orchestrator
- free5GC, which is containerized and deployed on Kubernetes, as 5G core network
  <center>
  {% img /images/project/cn_slicing.png 700 %}
  </center>
- Open Network Operating System (ONOS) as the Software-Defined Networking (SDN) controller and P4 switches as the data plane.
  <center>
  {% img /images/project/tn_slicing.png 700 %}
  </center>
