# Using Packer with Huawei Cloud IMS (Image Management Service)

These are the required steps to build an IMS image, for use in Huawei Cloud ECS (Elastic Cloud Server) service, using HashiCorp Packer.

This documentation focuses in the use of the [Openstack builder](https://www.packer.io/docs/builders/openstack).

There is a [Huawei Cloud specific builder](https://github.com/huaweicloud/packer-builder-huaweicloud-ecs), but it is not currently maintained. I suggest to avoid it.

There is a regression bug in most recent version (v1.5) of Packer when used with the Huawei Cloud IMS API. The current workaround is to use Packer v.1.4.2. More details in the next section.

## Docs
* [Openstack builder](https://packer.io/docs/builders/openstack.html)
* [Huawei Cloud IMS: Creating a Private Image Using Packer](https://support.huaweicloud.com/intl/en-us/bestpractice-ims/ims_bp_0031.html)

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

## Testing authentication

The simplest way to test authentication is to configure [OpenStack Client](https://docs.openstack.org/python-openstackclient/latest), and try to do some basic operations.

To install the OpenStack Client you will need Python. It's highly recommended to use [`pipx`](https://pypi.org/project/pipx) (to avoid dependencies conflicts).

```bash
openstack image list
openstack server list
```

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



## Building an image

Assuming that you already have packer installed, along with OpenStackClient. 

```bash
# (optional) Enable debug messages
export PACKER_LOG=1

# Selecting the first AZ in Region
export AZ=$(openstack availability zone list -f value -c "Zone Name"|head -n 1)

# Manually selecting the network (VPC) and subnet
## https://docs.openstack.org/python-openstackclient/latest/cli/command-objects/network.html#network-list
## https://docs.openstack.org/python-openstackclient/latest/cli/command-objects/subnet.html#subnet-list
openstack subnet list -c Name -c Network -c Subnet
export SUBNET_ID="<subnet_id>"


# If you don't have any unbounded (unused) Elastic IP, you should create one first
openstack floating ip list --status DOWN # this will return empty
openstack floating ip create admin_external_net


# Selecting an unbounded EIP (Floating IP)
export EIP_ID=$(openstack floating ip list --status DOWN -f value -c ID|head -n 1)



# Selecting base image
export SOURCE_IMAGE_ID=$(openstack image list --public --name "Ubuntu 18.04 server 64bit" -f value -c ID)

# Building
packer build \
    -on-error=ask \
    -var "availability_zone=$AZ"\
    -var "networks=$SUBNET_ID" \
    -var "floating_ip=$EIP_ID" \
    -var "source_image=$SOURCE_IMAGE_ID" \
    packer-openstack-ims.json

# Your newly created image should be listed here
openstack image list --private --long
```


## Testing the built image

```bash
export TEST_SERVER_NAME="packer-ubuntu-test-server_$(date +%F-%kh%M)"

openstack server create \
  --image "Ubuntu-image-updating-powered-by-Packer" \
  --flavor "s3.large.2" \
  --availability-zone "$AZ" \
  --network "$SUBNET_ID" \
  "$TEST_SERVER_NAME"

# FIXME: Find a way to attach an EIP during server creation
openstack server add floating ip packer-ubuntu-test-server $EIP_ID

### CONNECT TO THE SERVER AND DO THE REQUIRED VERIFICATIONS

openstack server delete "$TEST_SERVER_NAME"
```