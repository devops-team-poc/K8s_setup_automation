#!/bin/bash

# install basic tools
yum install net-tools vim -y

# Docker configuration and installation 
cat <<eof > /etc/yum.repos.d/docker.repo
[Docker]
baseurl=https://download.docker.com/linux/centos/7/x86_64/stable/
gpgcheck=0
eof

yum install docker-ce --nobest -y

systemctl enable --now docker

cat <<eof >> /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"]
}
eof

systemctl restart docker

docker info | grep Cgroup

# stop firewall & selinux
systemctl disable --now firewalld

setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

#disable swap and backup fstab file as well
swapoff -a
sed -i.bak -r 's/(.+ swap .+)/#\1/' /etc/fstab


# k8s repo making and installation
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF

yum install -y kubelet kubeadm kubectl iproute-tc --disableexcludes=kubernetes

systemctl enable --now kubelet

# enabling networking for docker
cat <<EOF >> /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

sysctl --system

# kubeadm initialisation
kubeadm config images pull

kubeadm init --pod-network-cidr=<available ip's cidr> > output.txt
