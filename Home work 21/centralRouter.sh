#!/bin/bash

sudo -i
sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*
cp -f /vagrant/routes/ip_forwarding.conf /etc/sysctl.d/ip_forwarding.conf
echo "DEFROUTE=no" >> /etc/sysconfig/network-scripts/ifcfg-eth0 
ip route del default
systemctl restart network
echo "GATEWAY=10.1.1.1" >> /etc/sysconfig/network-scripts/ifcfg-eth1
cp -f /vagrant/routes/centralRouter-eth2 /etc/sysconfig/network-scripts/route-eth2
systemctl restart network
yum install -y nmap
cp /vagrant/sources/knock.sh /opt
chmod +x /opt/knock.sh