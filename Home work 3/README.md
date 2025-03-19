## Домашнее задание: Работа с LVM
____

### Задание:
На виртуальной машине с Ubuntu 24.04 и LVM.
1. Уменьшить том под / до 8G.
2. Выделить том под /home.
3. Выделить том под /var - сделать в mirror.
4. /home - сделать том для снапшотов.
5. Прописать монтирование в fstab. Попробовать с разными опциями и разными файловыми системами (на выбор).
6. Работа со снапшотами:
    - сгенерить файлы в /home/;
    - снять снапшот;
    - удалить часть файлов;
    - восстановится со снапшота.
* На дисках попробовать поставить btrfs/zfs — с кэшем, снапшотами и разметить там каталог /opt.
Логировать работу можно с помощью утилиты script.

### Уменьшить том под / до 8G

Подготовим стенд, на виртуальной машине с Ubuntu 24.04 с LVM добавим 4 диска:

```sh
root@otus-server:~# lsblk
NAME                      MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda                         8:0    0   15G  0 disk 
├─sda1                      8:1    0    1M  0 part 
├─sda2                      8:2    0  1.8G  0 part /boot
└─sda3                      8:3    0 13.2G  0 part 
  └─ubuntu--vg-ubuntu--lv 252:0    0 13.2G  0 lvm  /
sdb                         8:16   0   10G  0 disk 
sdc                         8:32   0    2G  0 disk 
sdd                         8:48   0    1G  0 disk 
sde                         8:64   0    1G  0 disk 
```

Подготовим временный том для / раздела:

```sh
root@otus-server:~# pvcreate /dev/sdb
  Physical volume "/dev/sdb" successfully created.
root@otus-server:~# pvs
  PV         VG        Fmt  Attr PSize   PFree
  /dev/sda3  ubuntu-vg lvm2 a--  <13.25g    0 
  /dev/sdb   vg_root   lvm2 a--  <10.00g    0 

root@otus-server:~# vgcreate vg_root /dev/sdb
  Volume group "vg_root" successfully created
root@otus-server:~# vgs
  VG        #PV #LV #SN Attr   VSize   VFree
  ubuntu-vg   1   1   0 wz--n- <13.25g    0 
  vg_root     1   1   0 wz--n- <10.00g    0 

root@otus-server:~# lvcreate -n lv_root -l +100%FREE /dev/vg_root
  Logical volume "lv_root" created.
root@otus-server:~# lvs
  LV        VG        Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  ubuntu-lv ubuntu-vg -wi-ao---- <13.25g                                                    
  lv_root   vg_root   -wi-a----- <10.00g  
```

Создадим на нем файловую систему и смонтируем его, чтобы перенести туда данные:

```sh
root@otus-server:~# mkfs.ext4 /dev/vg_root/lv_root
mke2fs 1.47.0 (5-Feb-2023)
Creating filesystem with 2620416 4k blocks and 655360 inodes
Filesystem UUID: d4c42bbe-e07c-4c02-80b7-79525571e9b9
Superblock backups stored on blocks: 
	32768, 98304, 163840, 229376, 294912, 819200, 884736, 1605632

Allocating group tables: done                            
Writing inode tables: done                            
Creating journal (16384 blocks): done
Writing superblocks and filesystem accounting information: done 

root@otus-server:~# mount /dev/vg_root/lv_root /mnt
root@otus-server:~# df -Th
Filesystem                        Type   Size  Used Avail Use% Mounted on
tmpfs                             tmpfs  197M  764K  197M   1% /run
/dev/mapper/ubuntu--vg-ubuntu--lv ext4    13G  4.1G  8.3G  33% /
tmpfs                             tmpfs  984M     0  984M   0% /dev/shm
tmpfs                             tmpfs  5.0M     0  5.0M   0% /run/lock
/dev/sda2                         ext4   1.7G   96M  1.5G   6% /boot
tmpfs                             tmpfs  197M   12K  197M   1% /run/user/1000
/dev/mapper/vg_root-lv_root       ext4   9.8G   24K  9.3G   1% /mnt
```

Этой командой копируем все данные с / раздела в /mnt:

```sh
root@otus-server:~# rsync -avxHAX --progress / /mnt/
sent 4,205,093,930 bytes  received 1,159,303 bytes  106,487,423.62 bytes/sec
total size is 4,204,032,274  speedup is 1.00
```

Проверить что скопировалось:

```sh
root@otus-server:~# ll /mnt
total 2097260
drwxr-xr-x 23 root root       4096 Mar 18 18:25 ./
drwxr-xr-x 23 root root       4096 Mar 18 18:25 ../
lrwxrwxrwx  1 root root          7 Apr 22  2024 bin -> usr/bin/
drwxr-xr-x  2 root root       4096 Feb 26  2024 bin.usr-is-merged/
drwxr-xr-x  2 root root       4096 Mar 18 18:25 boot/
dr-xr-xr-x  2 root root       4096 Feb 16 22:49 cdrom/
drwxr-xr-x  2 root root       4096 Mar 19 10:48 dev/
drwxr-xr-x 84 root root       4096 Mar 18 18:30 etc/
drwxr-xr-x  3 root root       4096 Mar 18 18:30 home/
lrwxrwxrwx  1 root root          7 Apr 22  2024 lib -> usr/lib/
drwxr-xr-x  2 root root       4096 Feb 26  2024 lib.usr-is-merged/
lrwxrwxrwx  1 root root          9 Apr 22  2024 lib64 -> usr/lib64/
drwx------  2 root root      16384 Mar 18 18:23 lost+found/
drwxr-xr-x  2 root root       4096 Feb 16 20:51 media/
drwxr-xr-x  2 root root       4096 Mar 19 10:51 mnt/
drwxr-xr-x  2 root root       4096 Feb 16 20:51 opt/
dr-xr-xr-x  2 root root       4096 Mar 19 09:40 proc/
drwx------  4 root root       4096 Mar 18 18:41 root/
drwxr-xr-x  2 root root       4096 Mar 19 11:05 run/
lrwxrwxrwx  1 root root          8 Apr 22  2024 sbin -> usr/sbin/
drwxr-xr-x  2 root root       4096 Aug 22  2024 sbin.usr-is-merged/
drwxr-xr-x  2 root root       4096 Mar 18 18:30 snap/
drwxr-xr-x  2 root root       4096 Feb 16 20:51 srv/
-rw-------  1 root root 2147483648 Mar 18 18:25 swap.img
dr-xr-xr-x  2 root root       4096 Mar 19 10:42 sys/
drwxrwxrwt 11 root root       4096 Mar 19 11:05 tmp/
drwxr-xr-x 12 root root       4096 Feb 16 20:51 usr/
drwxr-xr-x 13 root root       4096 Mar 18 18:30 var/

root@otus-server:~# df -Th
Filesystem                        Type   Size  Used Avail Use% Mounted on
tmpfs                             tmpfs  197M  768K  197M   1% /run
/dev/mapper/ubuntu--vg-ubuntu--lv ext4    13G  4.1G  8.3G  33% /
tmpfs                             tmpfs  984M     0  984M   0% /dev/shm
tmpfs                             tmpfs  5.0M     0  5.0M   0% /run/lock
/dev/sda2                         ext4   1.7G   96M  1.5G   6% /boot
tmpfs                             tmpfs  197M   12K  197M   1% /run/user/1000
/dev/mapper/vg_root-lv_root       ext4   9.8G  4.1G  5.2G  44% /mnt
```

Затем сконфигурируем grub для того, чтобы при старте перейти в новый /.
Сымитируем текущий root, сделаем в него chroot и обновим grub:

```sh
root@otus-server:~# for i in /proc/ /sys/ /dev/ /run/ /boot/; do mount --bind $i /mnt/$i; done

root@otus-server:~# chroot /mnt/

root@otus-server:/# grub-mkconfig -o /boot/grub/grub.cfg
Sourcing file `/etc/default/grub'
Generating grub configuration file ...
Found linux image: /boot/vmlinuz-6.8.0-55-generic
Found initrd image: /boot/initrd.img-6.8.0-55-generic
Warning: os-prober will not be executed to detect other bootable partitions.
Systems on them will not be added to the GRUB boot configuration.
Check GRUB_DISABLE_OS_PROBER documentation entry.
Adding boot menu entry for UEFI Firmware Settings ...
done
```

Обновим образ initrd:

```sh
root@otus-server:/# update-initramfs -u
update-initramfs: Generating /boot/initrd.img-6.8.0-55-generic
```

Перезагружаемся, чтобы работать с новым разделом.

```sh
root@otus-server:~# reboot
```

Посмотрим картину с дисками после перезагрузки:

```sh
root@otus-server:~# lsblk
NAME                      MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda                         8:0    0   15G  0 disk 
├─sda1                      8:1    0    1M  0 part 
├─sda2                      8:2    0  1.8G  0 part /boot
└─sda3                      8:3    0 13.2G  0 part 
  └─ubuntu--vg-ubuntu--lv 252:1    0 13.2G  0 lvm  
sdb                         8:16   0   10G  0 disk 
└─vg_root-lv_root         252:0    0   10G  0 lvm  /
sdc                         8:32   0    2G  0 disk 
sdd                         8:48   0    1G  0 disk 
sde                         8:64   0    1G  0 disk 
```

Теперь нам нужно изменить размер старой VG и вернуть на него рут. Для этого удаляем старый LV размером в 13.2G и создаём новый на 8G:

```sh
root@otus-server:~# lvremove /dev/ubuntu-vg/ubuntu-lv
Do you really want to remove and DISCARD active logical volume ubuntu-vg/ubuntu-lv? [y/n]: y
  Logical volume "ubuntu-lv" successfully removed.

root@otus-server:~# lvcreate -n ubuntu-vg/ubuntu-lv -L 8G /dev/ubuntu-vg
WARNING: ext4 signature detected on /dev/ubuntu-vg/ubuntu-lv at offset 1080. Wipe it? [y/n]: y
  Wiping ext4 signature on /dev/ubuntu-vg/ubuntu-lv.
  Logical volume "ubuntu-lv" created.
root@otus-server:~# lvs
  LV        VG        Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  ubuntu-lv ubuntu-vg -wi-a-----   8.00g                                                    
  lv_root   vg_root   -wi-ao---- <10.00g 
```

Проделываем на нем те же операции:

```sh
root@otus-server:~# mkfs.ext4 /dev/ubuntu-vg/ubuntu-lv
mke2fs 1.47.0 (5-Feb-2023)
Creating filesystem with 2097152 4k blocks and 524288 inodes
Filesystem UUID: 6279ad04-7e18-4708-bd5d-0a6f9da0ca13
Superblock backups stored on blocks: 
	32768, 98304, 163840, 229376, 294912, 819200, 884736, 1605632

Allocating group tables: done                            
Writing inode tables: done                            
Creating journal (16384 blocks): done
Writing superblocks and filesystem accounting information: done 

root@otus-server:~# mount /dev/ubuntu-vg/ubuntu-lv /mnt

root@otus-server:~# rsync -avxHAX --progress / /mnt/
sent 4,230,270,178 bytes  received 1,159,317 bytes  99,563,046.94 bytes/sec
total size is 4,229,202,780  speedup is 1.00

root@otus-server:~# df -Th
Filesystem                        Type   Size  Used Avail Use% Mounted on
tmpfs                             tmpfs  197M  768K  197M   1% /run
/dev/mapper/vg_root-lv_root       ext4   9.8G  4.1G  5.2G  45% /
tmpfs                             tmpfs  984M     0  984M   0% /dev/shm
tmpfs                             tmpfs  5.0M     0  5.0M   0% /run/lock
/dev/sda2                         ext4   1.7G   96M  1.5G   6% /boot
tmpfs                             tmpfs  197M   12K  197M   1% /run/user/1000
/dev/mapper/ubuntu--vg-ubuntu--lv ext4   7.8G  4.1G  3.3G  56% /mnt
```

Сконфигурируем grub:

```sh
root@otus-server:~# for i in /proc/ /sys/ /dev/ /run/ /boot/; do mount --bind $i /mnt/$i; done

root@otus-server:~# chroot /mnt/

root@otus-server:/# grub-mkconfig -o /boot/grub/grub.cfg
Sourcing file `/etc/default/grub'
Generating grub configuration file ...
Found linux image: /boot/vmlinuz-6.8.0-55-generic
Found initrd image: /boot/initrd.img-6.8.0-55-generic
Warning: os-prober will not be executed to detect other bootable partitions.
Systems on them will not be added to the GRUB boot configuration.
Check GRUB_DISABLE_OS_PROBER documentation entry.
Adding boot menu entry for UEFI Firmware Settings ...
done

root@otus-server:/# update-initramfs -u
update-initramfs: Generating /boot/initrd.img-6.8.0-55-generic
W: Couldn't identify type of root file system for fsck hook
```

### Выделить том под /var в зеркало

На свободных дисках создаем зеркало:

```sh
root@otus-server:/# pvcreate /dev/sdc /dev/sdd
  Physical volume "/dev/sdc" successfully created.
  Physical volume "/dev/sdd" successfully created.

root@otus-server:/# vgcreate vg_var /dev/sdc /dev/sdd
  Volume group "vg_var" successfully created

root@otus-server:/# lvcreate -L 950M -m1 -n lv_var vg_var
  Rounding up size to full physical extent 952.00 MiB
  Logical volume "lv_var" created.
root@otus-server:/# lvs
  LV        VG        Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  ubuntu-lv ubuntu-vg -wi-ao----   8.00g                                                    
  lv_root   vg_root   -wi-ao---- <10.00g                                                    
  lv_var    vg_var    rwi-a-r--- 952.00m                                    100.00 
```

Создаем на нем ФС и перемещаем туда /var:

```sh
root@otus-server:/# mkfs.ext4 /dev/vg_var/lv_var
mke2fs 1.47.0 (5-Feb-2023)
Creating filesystem with 243712 4k blocks and 60928 inodes
Filesystem UUID: 90e9beb2-6d74-4021-8362-e83b3709fcf3
Superblock backups stored on blocks: 
	32768, 98304, 163840, 229376

Allocating group tables: done                            
Writing inode tables: done                            
Creating journal (4096 blocks): done
Writing superblocks and filesystem accounting information: done

root@otus-server:/# mount /dev/vg_var/lv_var /mnt
root@otus-server:/# cp -aR /var/* /mnt/
root@otus-server:/# df -Th
Filesystem                        Type   Size  Used Avail Use% Mounted on
/dev/mapper/ubuntu--vg-ubuntu--lv ext4   7.8G  4.1G  3.3G  56% /
tmpfs                             tmpfs  197M  796K  197M   1% /run
/dev/sda2                         ext4   1.7G   96M  1.5G   6% /boot
/dev/mapper/vg_var-lv_var         ext4   919M  420M  436M  50% /mnt
```

Сохраняем содержимое старого var:

```sh
root@otus-server:/# mkdir /tmp/oldvar && mv /var/* /tmp/oldvar
root@otus-server:/# ll /tmp/oldvar/
total 52
drwxr-xr-x 13 root root  4096 Mar 19 11:51 ./
drwxrwxrwt 11 root root  4096 Mar 19 11:51 ../
drwxr-xr-x  2 root root  4096 Mar 19 10:59 backups/
drwxr-xr-x 12 root root  4096 Feb 16 20:58 cache/
drwxrwsrwt  2 root root  4096 Feb 16 20:58 crash/
drwxr-xr-x 30 root root  4096 Mar 18 18:30 lib/
drwxrwsr-x  2 root staff 4096 Apr 22  2024 local/
lrwxrwxrwx  1 root root     9 Feb 16 20:51 lock -> /run/lock/
drwxr-xr-x  8 root root  4096 Mar 18 18:30 log/
drwxrwsr-x  2 root mail  4096 Feb 16 20:51 mail/
drwxr-xr-x  2 root root  4096 Feb 16 20:51 opt/
lrwxrwxrwx  1 root root     4 Feb 16 20:51 run -> /run/
drwxr-xr-x  2 root root  4096 Oct 11 08:05 snap/
drwxr-xr-x  2 root root  4096 Feb 16 20:51 spool/
drwxrwxrwt  5 root root  4096 Mar 19 11:27 tmp/
```

Монтируем новый var в каталог /var:

```sh
root@otus-server:/# umount /mnt
root@otus-server:/# mount /dev/vg_var/lv_var /var
```

Правим fstab для автоматического монтирования /var:

```sh
root@otus-server:/# echo "`blkid | grep var: | awk '{print $2}'` /var ext4 defaults 0 0" >> /etc/fstab
```

После чего можно успешно перезагружаться в новый (уменьшенный root) и удалять временную Volume Group:

```sh
root@otus-server:~# df -Th
Filesystem                        Type   Size  Used Avail Use% Mounted on
tmpfs                             tmpfs  197M  804K  197M   1% /run
/dev/mapper/ubuntu--vg-ubuntu--lv ext4   7.8G  3.7G  3.7G  50% /
tmpfs                             tmpfs  984M     0  984M   0% /dev/shm
tmpfs                             tmpfs  5.0M     0  5.0M   0% /run/lock
/dev/mapper/vg_var-lv_var         ext4   919M  404M  452M  48% /var
/dev/sda2                         ext4   1.7G   96M  1.5G   6% /boot
tmpfs                             tmpfs  197M   12K  197M   1% /run/user/1000
root@otus-server:~# lsblk
NAME                      MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda                         8:0    0   15G  0 disk 
├─sda1                      8:1    0    1M  0 part 
├─sda2                      8:2    0  1.8G  0 part /boot
└─sda3                      8:3    0 13.2G  0 part 
  └─ubuntu--vg-ubuntu--lv 252:6    0    8G  0 lvm  /
sdb                         8:16   0   10G  0 disk 
└─vg_root-lv_root         252:0    0   10G  0 lvm  
sdc                         8:32   0    2G  0 disk 
├─vg_var-lv_var_rmeta_0   252:1    0    4M  0 lvm  
│ └─vg_var-lv_var         252:5    0  952M  0 lvm  /var
└─vg_var-lv_var_rimage_0  252:2    0  952M  0 lvm  
  └─vg_var-lv_var         252:5    0  952M  0 lvm  /var
sdd                         8:48   0    1G  0 disk 
├─vg_var-lv_var_rmeta_1   252:3    0    4M  0 lvm  
│ └─vg_var-lv_var         252:5    0  952M  0 lvm  /var
└─vg_var-lv_var_rimage_1  252:4    0  952M  0 lvm  
  └─vg_var-lv_var         252:5    0  952M  0 lvm  /var
sde                         8:64   0    1G  0 disk 

root@otus-server:~# lvremove /dev/vg_root/lv_root
Do you really want to remove and DISCARD active logical volume vg_root/lv_root? [y/n]: y
  Logical volume "lv_root" successfully removed.
root@otus-server:~# lvs
  LV        VG        Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  ubuntu-lv ubuntu-vg -wi-ao----   8.00g                                                    
  lv_var    vg_var    rwi-aor--- 952.00m                                    100.00   

root@otus-server:~# vgremove /dev/vg_root
  Volume group "vg_root" successfully removed
root@otus-server:~# vgs
  VG        #PV #LV #SN Attr   VSize   VFree 
  ubuntu-vg   1   1   0 wz--n- <13.25g <5.25g
  vg_var      2   1   0 wz--n-   2.99g  1.12g

root@otus-server:~# pvremove /dev/sdb
  Labels on physical volume "/dev/sdb" successfully wiped.
root@otus-server:~# pvs
  PV         VG        Fmt  Attr PSize    PFree 
  /dev/sda3  ubuntu-vg lvm2 a--   <13.25g <5.25g
  /dev/sdc   vg_var    lvm2 a--    <2.00g  1.06g
  /dev/sdd   vg_var    lvm2 a--  1020.00m 64.00m
```

### Выделить том под /home

```sh
root@otus-server:~# lvcreate -n LogVol_Home -L 2G /dev/ubuntu-vg
  Logical volume "LogVol_Home" created.
root@otus-server:~# lvs
  LV          VG        Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  LogVol_Home ubuntu-vg -wi-a-----   2.00g                                                    
  ubuntu-lv   ubuntu-vg -wi-ao----   8.00g                                                    
  lv_var      vg_var    rwi-aor--- 952.00m                                    100.00 

root@otus-server:~# mkfs.ext4 /dev/ubuntu-vg/LogVol_Home
mke2fs 1.47.0 (5-Feb-2023)
Creating filesystem with 524288 4k blocks and 131072 inodes
Filesystem UUID: a5648320-8071-4372-b522-556eb48d32a1
Superblock backups stored on blocks: 
	32768, 98304, 163840, 229376, 294912

Allocating group tables: done                            
Writing inode tables: done                            
Creating journal (16384 blocks): done
Writing superblocks and filesystem accounting information: done 

root@otus-server:~# mount /dev/ubuntu-vg/LogVol_Home /mnt/
mount: (hint) your fstab has been modified, but systemd still uses
       the old version; use 'systemctl daemon-reload' to reload.
root@otus-server:~# df -Th
Filesystem                         Type   Size  Used Avail Use% Mounted on
tmpfs                              tmpfs  197M  808K  196M   1% /run
/dev/mapper/ubuntu--vg-ubuntu--lv  ext4   7.8G  3.7G  3.7G  50% /
tmpfs                              tmpfs  984M     0  984M   0% /dev/shm
tmpfs                              tmpfs  5.0M     0  5.0M   0% /run/lock
/dev/mapper/vg_var-lv_var          ext4   919M  404M  452M  48% /var
/dev/sda2                          ext4   1.7G   96M  1.5G   6% /boot
tmpfs                              tmpfs  197M   12K  197M   1% /run/user/1000
/dev/mapper/ubuntu--vg-LogVol_Home ext4   2.0G   24K  1.8G   1% /mnt

root@otus-server:~# cp -aR /home/* /mnt/
root@otus-server:~# ll /mnt/
total 28
drwxr-xr-x  4 root root  4096 Mar 19 12:10 ./
drwxr-xr-x 23 root root  4096 Mar 18 18:25 ../
drwxr-x---  4 ivan ivan  4096 Mar 18 18:41 ivan/
drwx------  2 root root 16384 Mar 19 12:08 lost+found/
root@otus-server:~# ll /home/
total 12
drwxr-xr-x  3 root root 4096 Mar 18 18:30 ./
drwxr-xr-x 23 root root 4096 Mar 18 18:25 ../
drwxr-x---  4 ivan ivan 4096 Mar 18 18:41 ivan/
root@otus-server:~# rm -rf /home/*
root@otus-server:~# ll /home/
total 8
drwxr-xr-x  2 root root 4096 Mar 19 12:10 ./
drwxr-xr-x 23 root root 4096 Mar 18 18:25 ../

root@otus-server:~# umount /mnt
root@otus-server:~# mount /dev/ubuntu-vg/LogVol_Home /home/
mount: (hint) your fstab has been modified, but systemd still uses
       the old version; use 'systemctl daemon-reload' to reload.
root@otus-server:~# ll /home/
total 28
drwxr-xr-x  4 root root  4096 Mar 19 12:10 ./
drwxr-xr-x 23 root root  4096 Mar 18 18:25 ../
drwxr-x---  4 ivan ivan  4096 Mar 18 18:41 ivan/
drwx------  2 root root 16384 Mar 19 12:08 lost+found/
```

Правим fstab для автоматического монтирования /home:

```sh
root@otus-server:~# echo "`blkid | grep Home | awk '{print $2}'` /home xfs defaults 0 0" >> /etc/fstab

root@otus-server:~# df -Th
Filesystem                         Type   Size  Used Avail Use% Mounted on
tmpfs                              tmpfs  197M  808K  196M   1% /run
/dev/mapper/ubuntu--vg-ubuntu--lv  ext4   7.8G  3.7G  3.7G  50% /
tmpfs                              tmpfs  984M     0  984M   0% /dev/shm
tmpfs                              tmpfs  5.0M     0  5.0M   0% /run/lock
/dev/mapper/vg_var-lv_var          ext4   919M  404M  452M  48% /var
/dev/sda2                          ext4   1.7G   96M  1.5G   6% /boot
tmpfs                              tmpfs  197M   12K  197M   1% /run/user/1000
/dev/mapper/ubuntu--vg-LogVol_Home ext4   2.0G   52K  1.8G   1% /home
```

### Работа со снапшотами

Генерируем файлы в /home/:

```sh
root@otus-server:~# touch /home/file{1..20}
root@otus-server:~# ll /home/
total 28
drwxr-xr-x  4 root root  4096 Mar 19 12:20 ./
drwxr-xr-x 23 root root  4096 Mar 18 18:25 ../
-rw-r--r--  1 root root     0 Mar 19 12:20 file1
-rw-r--r--  1 root root     0 Mar 19 12:20 file10
-rw-r--r--  1 root root     0 Mar 19 12:20 file11
-rw-r--r--  1 root root     0 Mar 19 12:20 file12
-rw-r--r--  1 root root     0 Mar 19 12:20 file13
-rw-r--r--  1 root root     0 Mar 19 12:20 file14
-rw-r--r--  1 root root     0 Mar 19 12:20 file15
-rw-r--r--  1 root root     0 Mar 19 12:20 file16
-rw-r--r--  1 root root     0 Mar 19 12:20 file17
-rw-r--r--  1 root root     0 Mar 19 12:20 file18
-rw-r--r--  1 root root     0 Mar 19 12:20 file19
-rw-r--r--  1 root root     0 Mar 19 12:20 file2
-rw-r--r--  1 root root     0 Mar 19 12:20 file20
-rw-r--r--  1 root root     0 Mar 19 12:20 file3
-rw-r--r--  1 root root     0 Mar 19 12:20 file4
-rw-r--r--  1 root root     0 Mar 19 12:20 file5
-rw-r--r--  1 root root     0 Mar 19 12:20 file6
-rw-r--r--  1 root root     0 Mar 19 12:20 file7
-rw-r--r--  1 root root     0 Mar 19 12:20 file8
-rw-r--r--  1 root root     0 Mar 19 12:20 file9
drwxr-x---  4 ivan ivan  4096 Mar 18 18:41 ivan/
drwx------  2 root root 16384 Mar 19 12:08 lost+found/
```

Снять снапшот:

```sh
root@otus-server:~# lvcreate -L 100MB -s -n home_snap /dev/ubuntu-vg/LogVol_Home
  Logical volume "home_snap" created.
root@otus-server:~# lvs
  LV          VG        Attr       LSize   Pool Origin      Data%  Meta%  Move Log Cpy%Sync Convert
  LogVol_Home ubuntu-vg owi-aos---   2.00g                                                         
  home_snap   ubuntu-vg swi-a-s--- 100.00m      LogVol_Home 0.01                                   
  ubuntu-lv   ubuntu-vg -wi-ao----   8.00g                                                         
  lv_var      vg_var    rwi-aor--- 952.00m                                         100.00
```

Удалить часть файлов:

```sh
root@otus-server:~# rm -f /home/file{11..20}
root@otus-server:~# ll /home/
total 28
drwxr-xr-x  4 root root  4096 Mar 19 12:33 ./
drwxr-xr-x 23 root root  4096 Mar 18 18:25 ../
-rw-r--r--  1 root root     0 Mar 19 12:20 file1
-rw-r--r--  1 root root     0 Mar 19 12:20 file10
-rw-r--r--  1 root root     0 Mar 19 12:20 file2
-rw-r--r--  1 root root     0 Mar 19 12:20 file3
-rw-r--r--  1 root root     0 Mar 19 12:20 file4
-rw-r--r--  1 root root     0 Mar 19 12:20 file5
-rw-r--r--  1 root root     0 Mar 19 12:20 file6
-rw-r--r--  1 root root     0 Mar 19 12:20 file7
-rw-r--r--  1 root root     0 Mar 19 12:20 file8
-rw-r--r--  1 root root     0 Mar 19 12:20 file9
drwxr-x---  4 ivan ivan  4096 Mar 18 18:41 ivan/
drwx------  2 root root 16384 Mar 19 12:08 lost+found/
```

Процесс восстановления из снапшота:

```sh
root@otus-server:~# umount /home
root@otus-server:~# df -Th
Filesystem                        Type   Size  Used Avail Use% Mounted on
tmpfs                             tmpfs  197M  820K  196M   1% /run
/dev/mapper/ubuntu--vg-ubuntu--lv ext4   7.8G  3.7G  3.7G  50% /
tmpfs                             tmpfs  984M     0  984M   0% /dev/shm
tmpfs                             tmpfs  5.0M     0  5.0M   0% /run/lock
/dev/mapper/vg_var-lv_var         ext4   919M  404M  452M  48% /var
/dev/sda2                         ext4   1.7G   96M  1.5G   6% /boot
tmpfs                             tmpfs  197M   12K  197M   1% /run/user/1000

root@otus-server:~# lvconvert --merge /dev/ubuntu-vg/home_snap
  Merging of volume ubuntu-vg/home_snap started.
  ubuntu-vg/LogVol_Home: Merged: 100.00%
root@otus-server:~# mount /dev/mapper/ubuntu--vg-LogVol_Home /home
mount: (hint) your fstab has been modified, but systemd still uses
       the old version; use 'systemctl daemon-reload' to reload.
root@otus-server:~# df -Th
Filesystem                         Type   Size  Used Avail Use% Mounted on
tmpfs                              tmpfs  197M  816K  196M   1% /run
/dev/mapper/ubuntu--vg-ubuntu--lv  ext4   7.8G  3.7G  3.7G  50% /
tmpfs                              tmpfs  984M     0  984M   0% /dev/shm
tmpfs                              tmpfs  5.0M     0  5.0M   0% /run/lock
/dev/mapper/vg_var-lv_var          ext4   919M  404M  452M  48% /var
/dev/sda2                          ext4   1.7G   96M  1.5G   6% /boot
tmpfs                              tmpfs  197M   12K  197M   1% /run/user/1000
/dev/mapper/ubuntu--vg-LogVol_Home ext4   2.0G   52K  1.8G   1% /home
root@otus-server:~# ll /home/
total 28
drwxr-xr-x  4 root root  4096 Mar 19 12:20 ./
drwxr-xr-x 23 root root  4096 Mar 18 18:25 ../
-rw-r--r--  1 root root     0 Mar 19 12:20 file1
-rw-r--r--  1 root root     0 Mar 19 12:20 file10
-rw-r--r--  1 root root     0 Mar 19 12:20 file11
-rw-r--r--  1 root root     0 Mar 19 12:20 file12
-rw-r--r--  1 root root     0 Mar 19 12:20 file13
-rw-r--r--  1 root root     0 Mar 19 12:20 file14
-rw-r--r--  1 root root     0 Mar 19 12:20 file15
-rw-r--r--  1 root root     0 Mar 19 12:20 file16
-rw-r--r--  1 root root     0 Mar 19 12:20 file17
-rw-r--r--  1 root root     0 Mar 19 12:20 file18
-rw-r--r--  1 root root     0 Mar 19 12:20 file19
-rw-r--r--  1 root root     0 Mar 19 12:20 file2
-rw-r--r--  1 root root     0 Mar 19 12:20 file20
-rw-r--r--  1 root root     0 Mar 19 12:20 file3
-rw-r--r--  1 root root     0 Mar 19 12:20 file4
-rw-r--r--  1 root root     0 Mar 19 12:20 file5
-rw-r--r--  1 root root     0 Mar 19 12:20 file6
-rw-r--r--  1 root root     0 Mar 19 12:20 file7
-rw-r--r--  1 root root     0 Mar 19 12:20 file8
-rw-r--r--  1 root root     0 Mar 19 12:20 file9
drwxr-x---  4 ivan ivan  4096 Mar 18 18:41 ivan/
drwx------  2 root root 16384 Mar 19 12:08 lost+found/
```

Файлы успешно восстановлены с помощью снапшота!!!