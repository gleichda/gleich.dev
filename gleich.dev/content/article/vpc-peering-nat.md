---
title: "How to use Cloud NAT with VPC Peering"
date: 2020-10-03T09:26:58+02:00
draft: false
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

⚠️ ⚠️ This firewall rules allow IAP access for all instances in your networks. In production use firewall tags! ⚠️ ⚠️

```shell script
gcloud compute firewall-rules create ssh-iap-ingress-vpc-1 --source-ranges 35.235.240.0/20 --allow=tcp:22 --network vpc-1 
gcloud compute firewall-rules create ssh-iap-ingress-vpc-2 --source-ranges 35.235.240.0/20 --allow=tcp:22 --network vpc-2
```

### Setup a VM in each network

For the VM in VPC 2 we must make sure that it allows [IP orwarding](https://cloud.google.com/sdk/gcloud/reference/compute/instances/create#--can-ip-forward).

```shell script
# VM in VPC 1
gcloud compute instances create test-vm --machine-type=n1-standard-1 --image-project=ubuntu-os-cloud --image-family=ubuntu-1804-lts --network=vpc-1 --no-address --subnet=subnet-1

# VM  in VPC 2
gcloud compute instances create nat-vm --machine-type=n1-standard-1 --image-project=ubuntu-os-cloud --image-family=ubuntu-1804-lts --network=vpc-2 --no-address --subnet=subnet-2 --can-ip-forward
```

### Connection test

Now SSH into both vms and try to ping some website or something.
I like to use [`1.1.1.1`](https://1.1.1.1/dns/) in this case. Just to make sure that it does not interfere with some Google IP ranges.
(Talking about [Private Google Access](https://cloud.google.com/vpc/docs/private-access-options#pga) for example.) 

Now you can see that the NAT VM already has internet access but the test VM is not able to reach the WWW.

![First Ping NAT VM](/img/vpc-peering-nat/first-ping-natvm.png)
![First Ping test VM](/img/vpc-peering-nat/first-ping-testvm.png)

### Now configure the NAT for the second VPC

#### Configure the VM to do IP forwarding

This is a mostly taken from the [Google BMS Setup](https://cloud.google.com/bare-metal/docs/bms-setup#bms-access-internet-vm-nat).
But instead of configuring everything we just add a small startup script:

```shell script
gcloud compute instances add-metadata nat-vm --metadata=startup-script=$'sysctl -w net.ipv4.ip_forward=1 && iptables -t nat -A POSTROUTING -o $(/sbin/ifconfig | head -1 | awk -F: {\'print $1\'}) -j MASQUERADE'

# Restart the VM afterwards to apply your changes
gcloud compute instances stop nat-vm && gcloud compute instances start nat-vm
```

#### Configure a route that is going to be propagated over the VPC Peering

To access the test VM to access the Internet over the NAT VM we need to create a route that is propagated over the VPC Peering.
This is not happening the `Default route to the Internet` as Google states [here](https://cloud.google.com/vpc/docs/vpc-peering#considerations).

So create a custom route to the internet over the NAT VM. The most important point is that the route has a lower priority than the `Default route to the Internet`

```shell script
gcloud compute routes create vpc-nat-route --network=vpc-2 --priority=10000 --next-hop-instance=nat-vm --destination-range 0.0.0.0/0
```

And allow ingress traffic from VPC 1 to the NAT VM. 

⚠️ ⚠️ This firewall rule will allow ingress for all instances on all IPs in VPC 2. In production use firewall tags! ⚠️ ⚠️

For production you definitely should work with tags again but for demo purposes allowing for all instances is fine.

```shell script
gcloud compute firewall-rules create nat-ingress --source-ranges  <IP RANGE FROM VPC 1> --allow=all --network=vpc-2
```

## Congratulations your VM has internet access now

![Final Ping test VM](/img/vpc-peering-nat/final-ping-testvm.png)
