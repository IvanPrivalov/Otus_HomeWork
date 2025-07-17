#!/bin/bash

sudo -i
sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*
yum install -y iptables-services tcpdump wireshark conntrack-tools
systemctl enable --now iptables
cp -f /vagrant/routes/ip_forwarding.conf /etc/sysctl.d/ip_forwarding.conf
echo "DEFROUTE=no" >> /etc/sysconfig/network-scripts/ifcfg-eth0
ip route del default
systemctl restart network
cp -f /vagrant/routes/inetRouter2-eth1 /etc/sysconfig/network-scripts/route-eth1
systemctl restart network
iptables -F
iptables -t nat -A PREROUTING -i eth2 -p tcp --dport 8080 -j DNAT --to 192.168.0.40:80
service iptables save