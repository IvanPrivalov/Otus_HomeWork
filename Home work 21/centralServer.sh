#!/bin/bash

sudo -i
sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*
echo "DEFROUTE=no" >> /etc/sysconfig/network-scripts/ifcfg-eth0
ip route del default
systemctl restart network
echo "GATEWAY=192.168.0.33" >> /etc/sysconfig/network-scripts/ifcfg-eth1
systemctl restart network
yum install -y epel-release
yum install -y nginx
cp -f /vagrant/sources/index.html /usr/share/doc/HTML/index.html
systemctl enable --now nginx
yum install -y traceroute