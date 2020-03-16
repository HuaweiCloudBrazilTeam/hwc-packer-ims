yum -y install git
cd /tmp
wget https://releases.hashicorp.com/packer/1.5.4/packer_1.5.4_linux_amd64.zip
unzip packer_1.5.4_linux_amd64.zip
cp packer /usr/local/bin
chmod +x /usr/local/bin/packer