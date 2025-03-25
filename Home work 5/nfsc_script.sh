#!/bin/bash
apt install nfs-common -y
echo "192.168.0.170:/srv/share/ /mnt nfs vers=3,noauto,x-systemd.automount 0 0" >> /etc/fstab
systemctl daemon-reload
systemctl restart remote-fs.target