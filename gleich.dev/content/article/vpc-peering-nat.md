---
title: "How to use Cloud NAT with VPC Peering"
date: 2020-08-11T14:26:58+02:00
draft: true
---

# Why should I want that

Google itself says that "Cloud NAT gateway created in one VPC network cannot provide NAT to VMs in other VPC networks connected using VPC Network Peering". ([source](https://cloud.google.com/nat/docs/overview#interaction-peering))
But in some cases there are reasons why you want to do that.
In my case it was connecting a [Bare Metal System (BMS)](https://cloud.google.com/bare-metal/docs/bms-planning).

BMS do not have internet access by default.
Actually the [recommendation](https://cloud.google.com/bare-metal/docs/bms-setup#bms-access-options) from Google is to use a VM which does the natting.

But having a VM that does the natting and is connected to the public internet can be or at least become a security risk.

