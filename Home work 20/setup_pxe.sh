#!/bin/bash

echo Install PXE server
sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*
yum -y install epel-release
yum -y install vim
yum -y install dhcp
yum -y install tftp-server
yum -y install nfs-utils
firewall-cmd --add-service=tftp
# disable selinux or permissive
setenforce 0
# 

cat >/etc/dhcp/dhcpd.conf <<EOF
option space pxelinux;
option pxelinux.magic code 208 = string;
option pxelinux.configfile code 209 = text;
option pxelinux.pathprefix code 210 = text;
option pxelinux.reboottime code 211 = unsigned integer 32;
option architecture-type code 93 = unsigned integer 16;
subnet 10.0.0.0 netmask 255.255.255.0 {
	#option routers 10.0.0.254;
	range 10.0.0.2 10.0.0.120;
	class "pxeclients" {
	  match if substring (option vendor-class-identifier, 0, 9) = "PXEClient";
	  next-server 10.0.0.20;
	  if option architecture-type = 00:07 {
	    filename "uefi/shim.efi";
	    } else {
	    filename "pxelinux/pxelinux.0";
	  }
	}
}
EOF
systemctl start dhcpd
systemctl enable dhcpd
systemctl start tftp.service
yum -y install syslinux-tftpboot.noarch
mkdir /var/lib/tftpboot/pxelinux
cp /var/lib/tftpboot/pxelinux.0 /var/lib/tftpboot/pxelinux
cp /var/lib/tftpboot/libutil.c32 /var/lib/tftpboot/pxelinux
cp /var/lib/tftpboot/menu.c32 /var/lib/tftpboot/pxelinux
cp /var/lib/tftpboot/libmenu.c32 /var/lib/tftpboot/pxelinux
cp /var/lib/tftpboot/ldlinux.c32 /var/lib/tftpboot/pxelinux
cp /var/lib/tftpboot/vesamenu.c32 /var/lib/tftpboot/pxelinux

mkdir /var/lib/tftpboot/pxelinux/pxelinux.cfg

cat >/var/lib/tftpboot/pxelinux/pxelinux.cfg/default <<EOF
default menu
prompt 0
timeout 600
MENU TITLE Demo PXE setup
LABEL linux
  menu label ^Install system
  menu default
  kernel images/CentOS-7/vmlinuz
  append initrd=images/CentOS-7/initrd.img ip=enp0s3:dhcp inst.repo=nfs:10.0.0.20:/mnt/centos7-install
LABEL linux-auto
  menu label ^Auto install system
  kernel images/CentOS-7/vmlinuz
  append initrd=images/CentOS-7/initrd.img ip=enp0s3:dhcp inst.ks=nfs:10.0.0.20:/home/vagrant/cfg/ks.cfg inst.repo=nfs:10.0.0.20:/mnt/centos7-autoinstall
LABEL vesa
  menu label Install system with ^basic video driver
  kernel images/CentOS-7/vmlinuz
  append initrd=images/CentOS-7/initrd.img ip=dhcp inst.xdriver=vesa nomodeset
LABEL rescue
  menu label ^Rescue installed system
  kernel images/CentOS-7/vmlinuz
  append initrd=images/CentOS-7/initrd.img rescue
LABEL local
  menu label Boot from ^local drive
  localboot 0xffff
EOF

mkdir -p /var/lib/tftpboot/pxelinux/images/CentOS-7/
curl -O https://vault.centos.org/7.9.2009/os/x86_64/images/pxeboot/initrd.img
curl -O https://vault.centos.org/7.9.2009/os/x86_64/images/pxeboot/vmlinuz
cp {vmlinuz,initrd.img} /var/lib/tftpboot/pxelinux/images/CentOS-7/


# Setup NFS auto install
# 

curl -O https://vault.centos.org/7.9.2009/os/x86_64/images/boot.iso
mkdir /mnt/centos7-install
mount -t iso9660 boot.iso /mnt/centos7-install
echo '/mnt/centos7-install *(ro)' > /etc/exports
systemctl start nfs-server.service


autoinstall(){
  curl -O https://vault.centos.org/7.9.2009/isos/x86_64/CentOS-7-x86_64-Minimal-2009.iso
  mkdir /mnt/centos7-autoinstall
  mount -t iso9660 CentOS-7-x86_64-Minimal-2009.iso /mnt/centos7-autoinstall
  echo '/mnt/centos7-autoinstall *(ro)' >> /etc/exports
  mkdir /home/vagrant/cfg
cat > /home/vagrant/cfg/ks.cfg <<EOF
#version=RHEL8
ignoredisk --only-use=sda
autopart --type=lvm
# Partition clearing information
clearpart --all --initlabel --drives=sda
# Use graphical install
graphical
# Keyboard layouts
keyboard --vckeymap=us --xlayouts='us'
# System language
lang en_US.UTF-8
#repo
#url --url=https://vault.centos.org/7.9.2009/os/x86_64
# Network information
network  --bootproto=dhcp --device=enp0s3 --ipv6=auto --activate
network  --bootproto=dhcp --device=enp0s8 --onboot=off --ipv6=auto --activate
network  --hostname=localhost.localdomain
# Root password
rootpw --iscrypted $6$g4WYvaAf1mNKnqjY$w2MtZxP/Yj6MYQOhPXS2rJlYT200DcBQC5KGWQ8gG32zASYYLUzoONIYVdRAr4tu/GbtB48.dkif.1f25pqeh.
# Run the Setup Agent on first boot
firstboot --enable
# Do not configure the X Window System
skipx
# System services
services --enabled="chronyd"
# System timezone
timezone America/New_York --isUtc
user --groups=wheel --name=val --password=$6$ihX1bMEoO3TxaCiL$OBDSCuY.EpqPmkFmMPVvI3JZlCVRfC4Nw6oUoPG0RGuq2g5BjQBKNboPjM44.0lJGBc7OdWlL17B3qzgHX2v// --iscrypted --gecos="val"
%packages
@^minimal-environment
kexec-tools
%end
%addon com_redhat_kdump --enable --reserve-mb='auto'
%end
%anaconda
pwpolicy root --minlen=6 --minquality=1 --notstrict --nochanges --notempty
pwpolicy user --minlen=6 --minquality=1 --notstrict --nochanges --emptyok
pwpolicy luks --minlen=6 --minquality=1 --notstrict --nochanges --notempty
%end
EOF
echo '/home/vagrant/cfg *(ro)' >> /etc/exports
  systemctl reload nfs-server.service
  systemctl start tftp.service
}
# uncomment to enable automatic installation
#autoinstall