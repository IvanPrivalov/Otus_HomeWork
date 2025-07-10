#!/bin/bash

echo "DEFROUTE=no" >> /etc/sysconfig/network-scripts/ifcfg-eth0 
echo "GATEWAY=192.168.0.1" >> /etc/sysconfig/network-scripts/ifcfg-eth1
systemctl restart network
ip route delete default 2>&1 >/dev/null || true
ip route add default via 192.168.0.1
ip route add 192.168.2.0/24 via 192.168.0.3
ip route add 192.168.1.0/24 via 192.168.0.4