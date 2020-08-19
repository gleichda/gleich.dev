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

## Prerequestites

Prepare your gcloud command line with some defaults:

```shell script
gcloud config set compute/region <YOUR REGION>
# Set a zone within that region for the VMs
gcloud config set compute/zone <YOUR ZONE>


```

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

### Setup the Cloud NAT in VPC 2

```shell script
# Create the Router for Cloud NAT
gcloud compute routers create nat-router --network=vpc-2

# Create the Cloud NAT
gcloud compute routers nats create vpc-2-nat --router=nat-router --auto-allocate-nat-external-ips --nat-all-subnet-ip-ranges
```

### Create Firewall Rules to access the VMs over SSH

For accessing the VMs without an external IP you can go use the [Identity Aware Proxy with TCP forwarding](https://cloud.google.com/iap/docs/using-tcp-forwarding).

:warning: **Th

```shell script
gcloud compute firewall-rules create ssh-iap-ingress-vpc-1 --source-ranges 35.235.240.0/20 --allow=tcp:22 --network vpc-1 
gcloud compute firewall-rules create ssh-iap-ingress-vpc-2 --source-ranges 35.235.240.0/20 --allow=tcp:22 --network vpc-2
```

### Setup a VM in each network

For the VM in VPC 2 we must make sure that it allows [IP orwarding](https://cloud.google.com/sdk/gcloud/reference/compute/instances/create#--can-ip-forward).

```shell script
# VM in VPC 1
gcloud compute instances create test-vm --machine-type=n1-standard-1 --image-project=ubuntu-os-cloud --image-family=ubuntu-2004-lts --network=vpc-1 --no-address --subnet=subnet-1

# VM  in VPC 2
gcloud compute instances create nat-vm --machine-type=n1-standard-1 --image-project=ubuntu-os-cloud --image-family=ubuntu-2004-lts --network=vpc-2 --no-address --subnet=subnet-2 --can-ip-forward
```

### Connection test

Now SSH into both vms and try to ping some website or something.
I like to use [`1.1.1.1`](https://1.1.1.1/dns/) in this case. Just to make sure that it does not interfere with some Google IP ranges.
(Talking about [Private Google Access](https://cloud.google.com/vpc/docs/private-access-options#pga) for example.) 

Now you can see that the NAT VM already has internet access but the test VM is not able to reach the WWW.

![First Ping NAT VM](/img/vpc-peering-nat/first-ping-natvm.png)
![First Ping test VM](/img/vpc-peering-nat/first-ping-testvm.png)

