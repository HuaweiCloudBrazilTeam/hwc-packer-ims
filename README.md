# Using Packer with Huawei Cloud IMS


## Docs
* https://packer.io/docs/builders/openstack.html
* [Huawei Cloud IMS: Creating a Private Image Using Packer](https://support.huaweicloud.com/intl/en-us/bestpractice-ims/ims_bp_0031.html)

## Selecting base image

* https://docs.openstack.org/python-openstackclient/latest/cli/command-objects/image.html#image-list
* https://wiki.openstack.org/wiki/Glance-v2-community-image-sharing-faq

```bash
openstack image list --public

openstack image list --public --name "Ubuntu 18.04 server 64bit"
openstack image list --public | grep -i "ubuntu"
openstack image list --public | grep -i "centos"

# owned by HWC in ap-southeast-1
openstack image list  --status active \
    --property 'owner=c16e072bc1334180868fd8ae507c80ad'\
    --property '__platform=CentOS'

# owned by HWC in sa-brazil-1
openstack image list  --status active \
    --property 'owner=31c994ac72fe4640be63048da1a58429'
```

## Installing Packer v1.4.2

**FIXME:** Workaround for API incompatibility bug regression in newer releases. Should be fixed in Packer v.1.6.0. More details in this [issue](https://github.com/hashicorp/packer/issues/9190).

```bash
pushd /tmp
# Assuming that you are running in an x86-64 Linux environment.
wget https://releases.hashicorp.com/packer/1.4.2/packer_1.4.2_linux_amd64.zip
unzip packer_1.4.2_linux_amd64.zip
sudo install packer /usr/local/bin
popd

which packer
packer version
```

## Building a image

Assuming that you already have packer installed, along with OpenStackClient. 

```bash
# Selecting the first AZ in Region
export AZ=`(openstack availability zone list -f value -c "Zone Name"|head -n 1)`

# Manually selecting the network (VPC) and subnet
## https://docs.openstack.org/python-openstackclient/latest/cli/command-objects/network.html#network-list
## https://docs.openstack.org/python-openstackclient/latest/cli/command-objects/subnet.html#subnet-list
openstack subnet list -c Name -c Network -c Subnet
export SUBNET_ID="<subnet_id>"

# Selecting an unbounded EIP (Floating IP)
export EIP_ID=$(openstack floating ip list --status DOWN -f value -c ID|head -n 1)

# Selecting base image
export SOURCE_IMAGE_ID=$(openstack image list --public --name "Ubuntu 18.04 server 64bit" -f value -c ID)

packer build \
    -on-error=ask \
    -var "availability_zone=$AZ"\
    -var "networks=$SUBNET_ID" \
    -var "floating_ip=$EIP_ID" \
    -var "source_image=$SOURCE_IMAGE_ID" \
    packer-openstack-ims.json

openstack image list --private
```
