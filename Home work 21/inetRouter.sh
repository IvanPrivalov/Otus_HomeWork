#!/bin/bash

sudo -i
sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*       
cp -f /vagrant/routes/ip_forwarding.conf /etc/sysctl.d/ip_forwarding.conf
# echo "DEFROUTE=no" >> /etc/sysconfig/network-scripts/ifcfg-eth0
# ip route del default
systemctl restart network
cp -f /vagrant/routes/inetRouter-eth1 /etc/sysconfig/network-scripts/route-eth1
systemctl restart network
useradd user1
echo "user" | passwd --stdin user1
sed -i 's/^PasswordAuthentication.*$/PasswordAuthentication yes/' /etc/ssh/sshd_config && systemctl restart sshd.service
yum install -y iptables-services
systemctl enable --now iptables
iptables-restore < /vagrant/firewall/inetrouter.rules
service iptables save