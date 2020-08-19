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

But having a VM that does the natting and is connected to the public internet can be or at least become a security risk (patching and so on...).

Spoiler: You still need the VM but you don't need to assign a public IP to it.

# The Setup

## How will it look like

![Setup Graph](/img/vpc-peering-nat/base-setup.png)

The compute instance in the second project (left) is hopping over the VPC Peering and the NAT VM over the [Cloud NAT](https://cloud.google.com/nat/docs/overview).

## Prerequisites

* 2 VPCs (either both in 1 or in 2 different projects)
* One VM within each project. Both without an external IP address
* One VPC setup with Cloud NAT

## How to set it up

I've set it up within one project containing 2 different VPCs but this shouldn't matter.

Some keywords I'm using regularly:

* VPC 1: The VPC that does not have internet access
* VPC 2: The VPC that provides internet access
* NAT VM: The VM that provides access to  Cloud NAT
* Test VM: The VM that should gain internet access via this setup

![VPC Setup](/img/vpc-peering-nat/vpc-setup.png)

### Create a VPC Peering

When creating the VPC Peering make sure you have enabled the [import custom routes](https://cloud.google.com/vpc/docs/vpc-peering#importing-exporting-routes) option
for VPC 2 and the export custom routes option in VPC 1.

Now you can peer both of the VPCs either via Cloud Console or using the gcloud commands:

```shell script
# VPC Peering from VPC 1 to VPC 2
gcloud compute networks peerings create vpc1-vpc2 --network=vpc-1 --peer-network=vpc-2 --import-custom-routes

# VPC Peering from VPC 2 to VPC 1
gcloud compute networks peerings create vpc2-vpc1 --network=vpc-2 --peer-network=vpc-1 --export-custom-routes
```

This then looks like the following picture:

![VPC Peering Setup](/img/vpc-peering-nat/peering-setup.png)

### Delete the default route to the internet in VPC 1

```shell script
# Find the right route
gcloud compute routes list --filter='(network=vpc-1 AND nextHopGateway=default-internet-gateway)'

# Now delete the route
gcloud compute routes delete <YOUR ROUTE NAME>
```
