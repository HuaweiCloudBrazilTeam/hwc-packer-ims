# packer-tests
Playing with packer

## Docs
* https://packer.io/docs/builders/openstack.html


## Account parameters
```bash
# https://docs.openstack.org/python-openstackclient/latest/cli/command-objects/availability-zone.html
openstack availability zone list
```

## Selecting base image

* https://docs.openstack.org/python-openstackclient/latest/cli/command-objects/image.html#image-list

```bash
openstack image list  --status active \
    --property 'owner=c16e072bc1334180868fd8ae507c80ad'\
    --property '__platform=CentOS'

openstack image list --name "Ubuntu 18.04 server 64bit"
openstack image list | grep -i "ubuntu"
openstack image list | grep -i "centos"
```

## Building a image

Assuming that you already have packer installed, along with OpenStackClient. 

```bash
# Selecting the first AZ in Region
export AZ=`(openstack availability zone list -f value -c "Zone Name"|head -n 1)`

# Selecting the network (VPC) and subnet
## https://docs.openstack.org/python-openstackclient/latest/cli/command-objects/network.html#network-list
## https://docs.openstack.org/python-openstackclient/latest/cli/command-objects/subnet.html#subnet-list
openstack subnet list -c Name -c Network -c Subnet
export SUBNET_ID="<subnet_id>"

packer build \
    -on-error=ask \
    -var "availability_zone=$AZ"\
    -var "network=$SUBNET_ID"\
    packer-openstack.json

openstack image list --private
```