# packer-tests
Playing with packer

## Docs
* https://packer.io/docs/builders/openstack.html

## Selecting base image

```bash
openstack image list --name "Ubuntu 18.04 server 64bit"
```

## Building a image

Assuming that you already have packer installed, along with OpenStackClient. 

```bash
packer build -var 'availability_zone=ap-southeast-1a' packer-openstack.json
openstack image list --private
```