#!/bin/bash
set -x
  
VAGRANTFILE="Vagrantfile"
BOXVMNAME="kubeadmCentosBox"
rm -f $VAGRANTFILE
cat > $VAGRANTFILE <<VAGRANTFILE_END
# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
installk8s = <<SCRIPT
set -x
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=http://yum.kubernetes.io/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=0
repo_gpgcheck=0
EOF

setenforce 0
[ -f /etc/selinux/config ] && sed -i "s/SELINUX=.*/SELINUX=disabled/g" /etc/selinux/config
yum install -y kubelet kubeadm kubectl kubernetes-cni ntp
usermod -aG docker vagrant 
systemctl enable kubelet && systemctl start kubelet
systemctl enable ntpd && systemctl start ntpd
systemctl -q is-active firewalld && systemctl stop firewalld  || true
systemctl -q is-enabled firewalld && systemctl disable firewalld || true
rm -f /etc/udev/rules.d/70*
history -c
history -w

SCRIPT

Vagrant.configure("2") do |config|
  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://atlas.hashicorp.com/search.
  config.vm.box = "contiv/centos73"
  config.ssh.insert_key = false
  config.vm.network :private_network, ip: '10.33.2.100'
  config.vm.network :private_network, ip: '10.34.2.100', virtualbox__intnet: 'true', auto_config: false
  config.vm.provider 'virtualbox' do |v|
       # make all nics 'virtio' to take benefit of builtin vlan tag
       # support, which otherwise needs to be enabled in Intel drivers,
       # which are used by default by virtualbox
       v.customize ['modifyvm', :id, '--nictype1', 'virtio']
       v.customize ['modifyvm', :id, '--nictype2', 'virtio']
       v.customize ['modifyvm', :id, '--nictype3', 'virtio']
       v.customize ['modifyvm', :id, '--nicpromisc2', 'allow-all']
       v.customize ['modifyvm', :id, '--nicpromisc3', 'allow-all']
       v.customize ['modifyvm', :id, '--paravirtprovider', 'kvm']
  end

  # Disable automatic box update checking. If you disable this, then
  # boxes will only be checked for updates when the user runs
  # `vagrant box outdated`. This is not recommended.
  # config.vm.box_check_update = false

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  # config.vm.network "forwarded_port", guest: 80, host: 8080

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  # config.vm.network "private_network", ip: "192.168.33.10"

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
  # config.vm.network "public_network"

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  # config.vm.synced_folder "../data", "/vagrant_data"

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  # Example for VirtualBox:
  #
  config.vm.provider "virtualbox" do |vb|
  #   # Display the VirtualBox GUI when booting the machine
  #   vb.gui = true
  #
  #   # Customize the amount of memory on the VM:
     vb.memory = "2048"
     vb.name = "kubeadmCentosBox"
  end
  config.vm.provision "shell" do |s|
     s.inline = installk8s
  end
  #
  # View the documentation for the provider you are using for more
  # information on available options.

  # Define a Vagrant Push strategy for pushing to Atlas. Other push strategies
  # such as FTP and Heroku are also available. See the documentation at
  # https://docs.vagrantup.com/v2/push/atlas.html for more information.
  # config.push.define "atlas" do |push|
  #   push.app = "YOUR_ATLAS_USERNAME/YOUR_APPLICATION_NAME"
  # end

  # Enable provisioning with a shell script. Additional provisioners such as
  # Puppet, Chef, Ansible, Salt, and Docker are also available. Please see the
  # documentation for more information about their specific syntax and use.
  # config.vm.provision "shell", inline: <<-SHELL
  #   apt-get update
  #   apt-get install -y apache2
  # SHELL
end
VAGRANTFILE_END
vagrant destroy -f && vagrant up
rm -f ${BOXVMNAME}.tar
# create box image
vagrant package --base $BOXVMNAME -o ${BOXVMNAME}.tar
vagrant destroy -f
rm -f $VAGRANTFILE
