# packer-tests
Playing with packer

## Docs
* https://packer.io/docs/builders/openstack.html
* [Huawei Cloud IMS: Creating a Private Image Using Packer](https://support.huaweicloud.com/intl/en-us/bestpractice-ims/ims_bp_0031.html)


## Account parameters
```bash
# https://docs.openstack.org/python-openstackclient/latest/cli/command-objects/availability-zone.html
openstack availability zone list
```

## Selecting base image

* https://docs.openstack.org/python-openstackclient/latest/cli/command-objects/image.html#image-list

```bash
# owned by HWC in ap-southeast-1
openstack image list  --status active \
    --property 'owner=c16e072bc1334180868fd8ae507c80ad'\
    --property '__platform=CentOS'

# owned by HWC in sa-brazil-1
openstack image list  --status active \
    --property 'owner=31c994ac72fe4640be63048da1a58429'


openstack image list --name "Ubuntu 18.04 server 64bit"
openstack image list | grep -i "ubuntu"
openstack image list | grep -i "centos"
```

## Building a image

Assuming that you already have packer installed, along with OpenStackClient. 

```bash
# Debug messages
export PACKER_LOG=1

# Selecting the first AZ in Region
export AZ=`(openstack availability zone list -f value -c "Zone Name"|head -n 1)`

# Selecting the network (VPC) and subnet
## https://docs.openstack.org/python-openstackclient/latest/cli/command-objects/network.html#network-list
## https://docs.openstack.org/python-openstackclient/latest/cli/command-objects/subnet.html#subnet-list
openstack subnet list -c Name -c Network -c Subnet
export SUBNET_ID="<subnet_id>"


# Selecting an unbounded EIP (Floating IP)
export EIP_ID=$(openstack floating ip list --status DOWN -f json | jq -r .[0].ID)



packer build \
    -on-error=ask \
    -var "availability_zone=$AZ"\
    -var "networks=$SUBNET_ID" \
    -var "floating_ip=$EIP_ID" \
    packer-openstack-ims.json

openstack image list --private
```
