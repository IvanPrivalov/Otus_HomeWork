#!/bin/bash
echo "excludepkgs=zabbix*" >> /etc/yum.repos.d/epel.repo
rpm -Uvh https://repo.zabbix.com/zabbix/7.0/alma/9/x86_64/zabbix-release-latest-7.0.el9.noarch.rpm
dnf clean all
dnf install -y zabbix-agent2
dnf install -y zabbix-agent2-plugin-mongodb zabbix-agent2-plugin-mssql zabbix-agent2-plugin-postgresql
sed -i 's/Server=127.0.0.1/Server=192.168.56.3/g' /etc/zabbix/zabbix_agent2.conf
sed -i 's/ServerActive=127.0.0.1/ServerActive=192.168.56.3/g' /etc/zabbix/zabbix_agent2.conf
systemctl restart zabbix-agent2
systemctl enable zabbix-agent2
