#!/bin/sh
# https://kubernetes.io/docs/setup/independent/install-kubeadm/

#mkdir -p /etc/docker
#cat << EOF > /etc/docker/daemon.json
#{
#  "exec-opts": ["native.cgroupdriver=systemd"]
#}
#EOF
yum install -y docker
systemctl enable docker && systemctl start docker

cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
setenforce 0
yum install -y kernel-devel # vbguest
yum install -y kubelet kubeadm kubectl
systemctl enable kubelet && systemctl start kubelet
cat <<EOF >  /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system
