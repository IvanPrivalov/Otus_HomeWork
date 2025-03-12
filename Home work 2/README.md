## Домашнее задание: работа с mdadm
____

### Задание:
- Добавить в виртуальную машину несколько дисков
- Собрать RAID-0/1/5/10 на выбор
- Сломать и починить RAID
- Создать GPT таблицу, пять разделов и смонтировать их в системе.

### Запустить ВМ c 5 дополнительными дисками по 1Gb.

Запускаем виртуальную машину из каталога с нашим Vagrantfile, выполнив команду:

```sh
vagrant up
```

Подключаемся по ssh к созданной виртуальной машине. Для этого в каталоге с нашим Vagrantfile вводим команду:

```sh
vagrant ssh
```

Устанавливаем mdadm

```sh
[root@mdadm ~]# sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
[root@mdadm ~]# sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*
[root@mdadm ~]# yum install -y mdadm
```

Проверим какие блочные устройства у нас есть:

```sh
[root@mdadm ~]# lsblk
NAME   MAJ:MIN RM SIZE RO TYPE MOUNTPOINT
sda      8:0    0  10G  0 disk 
└─sda1   8:1    0  10G  0 part /
sdb      8:16   0   1G  0 disk 
sdc      8:32   0   1G  0 disk 
sdd      8:48   0   1G  0 disk 
sde      8:64   0   1G  0 disk 
sdf      8:80   0   1G  0 disk
```

```sh
[root@mdadm ~]# lshw -short | grep disk
/0/100/1.1/0.0.0    /dev/sda   disk        10GB VBOX HARDDISK
/0/100/d/0          /dev/sdb   disk        1073MB VBOX HARDDISK
/0/100/d/1          /dev/sdc   disk        1073MB VBOX HARDDISK
/0/100/d/2          /dev/sdd   disk        1073MB VBOX HARDDISK
/0/100/d/3          /dev/sde   disk        1073MB VBOX HARDDISK
/0/100/d/0.0.0      /dev/sdf   disk        1073MB VBOX HARDDISK
```

Занулим на всякий случай суперблоки:

```sh
[root@mdadm ~]# mdadm --zero-superblock --force /dev/sd{b,c,d,e,f}
mdadm: Unrecognised md component device - /dev/sdb
mdadm: Unrecognised md component device - /dev/sdc
mdadm: Unrecognised md component device - /dev/sdd
mdadm: Unrecognised md component device - /dev/sde
mdadm: Unrecognised md component device - /dev/sdf
```

### Создам RAID 10 следующей командой:

```sh
[root@mdadm ~]# mdadm --create --verbose /dev/md0 -l 10 -n 5 /dev/sd{b,c,d,e,f}
```

Проверим, что RAID собрался:

```sh
[root@mdadm ~]# cat /proc/mdstat
Personalities : [raid10] 
md0 : active raid10 sdf[4] sde[3] sdd[2] sdc[1] sdb[0]
      2616320 blocks super 1.2 512K chunks 2 near-copies [5/5] [UUUUU]
      
unused devices: <none>
```

```sh
[root@mdadm ~]# mdadm -D /dev/md0
/dev/md0:
           Version : 1.2
     Creation Time : Wed Mar 12 12:52:01 2025
        Raid Level : raid10
        Array Size : 2616320 (2.50 GiB 2.68 GB)
     Used Dev Size : 1046528 (1022.00 MiB 1071.64 MB)
      Raid Devices : 5
     Total Devices : 5
       Persistence : Superblock is persistent

       Update Time : Wed Mar 12 12:52:15 2025
             State : clean 
    Active Devices : 5
   Working Devices : 5
    Failed Devices : 0
     Spare Devices : 0

            Layout : near=2
        Chunk Size : 512K

Consistency Policy : resync

              Name : mdadm:0  (local to host mdadm)
              UUID : 46fcad66:b993c524:e7065ed9:01176e87
            Events : 17

    Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync   /dev/sdb
       1       8       32        1      active sync   /dev/sdc
       2       8       48        2      active sync   /dev/sdd
       3       8       64        3      active sync   /dev/sde
       4       8       80        4      active sync   /dev/sdf
```

### Сломаю и починю RAID

Искусственно “зафейлил” одно из блочных устройств:

```sh
[root@mdadm ~]# mdadm /dev/md0 --fail /dev/sdb
mdadm: set /dev/sdb faulty in /dev/md0
```

Посмотрим, как это отразилось на RAID:

```sh
[root@mdadm ~]# cat /proc/mdstat
Personalities : [raid10] 
md0 : active raid10 sdf[4] sde[3] sdd[2] sdc[1] sdb[0](F)
      2616320 blocks super 1.2 512K chunks 2 near-copies [5/4] [_UUUU]
      
unused devices: <none>
```

```sh
[root@mdadm ~]# mdadm -D /dev/md0
/dev/md0:
           Version : 1.2
     Creation Time : Wed Mar 12 12:52:01 2025
        Raid Level : raid10
        Array Size : 2616320 (2.50 GiB 2.68 GB)
     Used Dev Size : 1046528 (1022.00 MiB 1071.64 MB)
      Raid Devices : 5
     Total Devices : 5
       Persistence : Superblock is persistent

       Update Time : Wed Mar 12 16:53:39 2025
             State : clean, degraded 
    Active Devices : 4
   Working Devices : 4
    Failed Devices : 1
     Spare Devices : 0

            Layout : near=2
        Chunk Size : 512K

Consistency Policy : resync

              Name : mdadm:0  (local to host mdadm)
              UUID : 46fcad66:b993c524:e7065ed9:01176e87
            Events : 19

    Number   Major   Minor   RaidDevice State
       -       0        0        0      removed
       1       8       32        1      active sync   /dev/sdc
       2       8       48        2      active sync   /dev/sdd
       3       8       64        3      active sync   /dev/sde
       4       8       80        4      active sync   /dev/sdf

       0       8       16        -      faulty   /dev/sdb
```

Удалим “сломанный” диск из массива:

```sh
[root@mdadm ~]# mdadm /dev/md0 --remove /dev/sdb
mdadm: hot removed /dev/sdb from /dev/md0
[root@mdadm ~]# cat /proc/mdstat
Personalities : [raid10] 
md0 : active raid10 sdf[4] sde[3] sdd[2] sdc[1]
      2616320 blocks super 1.2 512K chunks 2 near-copies [5/4] [_UUUU]
      
unused devices: <none>
```

Добавляем диск в RAID:

```sh
[root@mdadm ~]# mdadm /dev/md0 --add /dev/sdb
mdadm: added /dev/sdb
[root@mdadm ~]# cat /proc/mdstat
Personalities : [raid10] 
md0 : active raid10 sdb[5] sdf[4] sde[3] sdd[2] sdc[1]
      2616320 blocks super 1.2 512K chunks 2 near-copies [5/5] [UUUUU]
      
unused devices: <none>
[root@mdadm ~]# mdadm -D /dev/md0
/dev/md0:
           Version : 1.2
     Creation Time : Wed Mar 12 12:52:01 2025
        Raid Level : raid10
        Array Size : 2616320 (2.50 GiB 2.68 GB)
     Used Dev Size : 1046528 (1022.00 MiB 1071.64 MB)
      Raid Devices : 5
     Total Devices : 5
       Persistence : Superblock is persistent

       Update Time : Wed Mar 12 17:00:22 2025
             State : clean 
    Active Devices : 5
   Working Devices : 5
    Failed Devices : 0
     Spare Devices : 0

            Layout : near=2
        Chunk Size : 512K

Consistency Policy : resync

              Name : mdadm:0  (local to host mdadm)
              UUID : 46fcad66:b993c524:e7065ed9:01176e87
            Events : 39

    Number   Major   Minor   RaidDevice State
       5       8       16        0      active sync   /dev/sdb
       1       8       32        1      active sync   /dev/sdc
       2       8       48        2      active sync   /dev/sdd
       3       8       64        3      active sync   /dev/sde
       4       8       80        4      active sync   /dev/sdf
```

Создание файла mdadm.conf:

```sh
[root@mdadm /]#  mkdir /etc/mdadm
[root@mdadm /]#  touch /etc/mdadm/mdadm.conf
[root@mdadm /]#  echo "DEVICE partitions" > /etc/mdadm/mdadm.conf
[root@mdadm /]#  mdadm --detail --scan --verbose | awk '/ARRAY/ {print}' >> /etc/mdadm/mdadm.conf
[root@mdadm /]# cat /etc/mdadm/mdadm.conf
DEVICE partitions
ARRAY /dev/md0 level=raid10 num-devices=5 metadata=1.2 name=mdadm:0 UUID=46fcad66:b993c524:e7065ed9:01176e87
```

### Создать GPT таблицу, пять разделов и смонтировать их в системе.

Создаем раздел GPT на RAID:

```sh
[root@mdadm /]# parted -s /dev/md0 mklabel gpt
```

Создаем партиции:

```sh
[root@mdadm /]# parted /dev/md0 mkpart primary ext4 0% 20%
Information: You may need to update /etc/fstab.

[root@mdadm /]# parted /dev/md0 mkpart primary ext4 20% 40%               
Information: You may need to update /etc/fstab.

[root@mdadm /]# parted /dev/md0 mkpart primary ext4 40% 60%               
Information: You may need to update /etc/fstab.

[root@mdadm /]# parted /dev/md0 mkpart primary ext4 60% 80%               
Information: You may need to update /etc/fstab.

[root@mdadm /]# parted /dev/md0 mkpart primary ext4 80% 100%              
Information: You may need to update /etc/fstab.
```

```sh
[root@mdadm /]# lsblk
NAME      MAJ:MIN RM   SIZE RO TYPE   MOUNTPOINT
sda         8:0    0    10G  0 disk   
└─sda1      8:1    0    10G  0 part   /
sdb         8:16   0     1G  0 disk   
└─md0       9:0    0   2.5G  0 raid10 
  ├─md0p1 259:0    0 507.5M  0 md     
  ├─md0p2 259:1    0 512.5M  0 md     
  ├─md0p3 259:2    0   510M  0 md     
  ├─md0p4 259:3    0 512.5M  0 md     
  └─md0p5 259:4    0 507.5M  0 md     
sdc         8:32   0     1G  0 disk   
└─md0       9:0    0   2.5G  0 raid10 
  ├─md0p1 259:0    0 507.5M  0 md     
  ├─md0p2 259:1    0 512.5M  0 md     
  ├─md0p3 259:2    0   510M  0 md     
  ├─md0p4 259:3    0 512.5M  0 md     
  └─md0p5 259:4    0 507.5M  0 md     
sdd         8:48   0     1G  0 disk   
└─md0       9:0    0   2.5G  0 raid10 
  ├─md0p1 259:0    0 507.5M  0 md     
  ├─md0p2 259:1    0 512.5M  0 md     
  ├─md0p3 259:2    0   510M  0 md     
  ├─md0p4 259:3    0 512.5M  0 md     
  └─md0p5 259:4    0 507.5M  0 md     
sde         8:64   0     1G  0 disk   
└─md0       9:0    0   2.5G  0 raid10 
  ├─md0p1 259:0    0 507.5M  0 md     
  ├─md0p2 259:1    0 512.5M  0 md     
  ├─md0p3 259:2    0   510M  0 md     
  ├─md0p4 259:3    0 512.5M  0 md     
  └─md0p5 259:4    0 507.5M  0 md     
sdf         8:80   0     1G  0 disk   
└─md0       9:0    0   2.5G  0 raid10 
  ├─md0p1 259:0    0 507.5M  0 md     
  ├─md0p2 259:1    0 512.5M  0 md     
  ├─md0p3 259:2    0   510M  0 md     
  ├─md0p4 259:3    0 512.5M  0 md     
  └─md0p5 259:4    0 507.5M  0 md  
```

Далее создаем на этих партициях ФС:

```sh
[root@mdadm /]# for i in $(seq 1 5); do sudo mkfs.ext4 /dev/md0p$i; done
mke2fs 1.45.6 (20-Mar-2020)
Creating filesystem with 519680 1k blocks and 130048 inodes
Filesystem UUID: e8a194ea-5f19-441a-9512-ab3e124cf004
Superblock backups stored on blocks: 
	8193, 24577, 40961, 57345, 73729, 204801, 221185, 401409

Allocating group tables: done                            
Writing inode tables: done                            
Creating journal (8192 blocks): done
Writing superblocks and filesystem accounting information: done 

mke2fs 1.45.6 (20-Mar-2020)
Creating filesystem with 131072 4k blocks and 32832 inodes
Filesystem UUID: 5c9e2a81-2185-428c-8a4f-744a4b951f77
Superblock backups stored on blocks: 
	32768, 98304

Allocating group tables: done                            
Writing inode tables: done                            
Creating journal (4096 blocks): done
Writing superblocks and filesystem accounting information: done

mke2fs 1.45.6 (20-Mar-2020)
Creating filesystem with 522240 1k blocks and 130560 inodes
Filesystem UUID: 029fe1cc-a2e6-46ec-9436-09033991c03d
Superblock backups stored on blocks: 
	8193, 24577, 40961, 57345, 73729, 204801, 221185, 401409

Allocating group tables: done                            
Writing inode tables: done                            
Creating journal (8192 blocks): done
Writing superblocks and filesystem accounting information: done 

mke2fs 1.45.6 (20-Mar-2020)
Creating filesystem with 131072 4k blocks and 32832 inodes
Filesystem UUID: a326bb8b-8e50-4ab0-8807-f48b18b483fb
Superblock backups stored on blocks: 
	32768, 98304

Allocating group tables: done                            
Writing inode tables: done                            
Creating journal (4096 blocks): done
Writing superblocks and filesystem accounting information: done

mke2fs 1.45.6 (20-Mar-2020)
Creating filesystem with 519680 1k blocks and 130048 inodes
Filesystem UUID: cc95a7d5-7c2c-4a60-9382-3c7814fe3fe2
Superblock backups stored on blocks: 
	8193, 24577, 40961, 57345, 73729, 204801, 221185, 401409

Allocating group tables: done                            
Writing inode tables: done                            
Creating journal (8192 blocks): done
Writing superblocks and filesystem accounting information: done 
```

Смонтируем их по каталогам:

```sh
[root@mdadm /]# mkdir -p /raid/part{1,2,3,4,5}
[root@mdadm /]# for i in $(seq 1 5); do mount /dev/md0p$i /raid/part$i; done
[root@mdadm /]# df -h
Filesystem      Size  Used Avail Use% Mounted on
devtmpfs        467M     0  467M   0% /dev
tmpfs           485M     0  485M   0% /dev/shm
tmpfs           485M   13M  472M   3% /run
tmpfs           485M     0  485M   0% /sys/fs/cgroup
/dev/sda1        10G  3.4G  6.7G  34% /
tmpfs            97M     0   97M   0% /run/user/1000
/dev/md0p1      484M  2.3M  452M   1% /raid/part1
/dev/md0p2      488M  780K  452M   1% /raid/part2
/dev/md0p3      486M  2.3M  455M   1% /raid/part3
/dev/md0p4      488M  780K  452M   1% /raid/part4
/dev/md0p5      484M  2.3M  452M   1% /raid/part5
[root@mdadm /]# ll /raid/
total 11
drwxr-xr-x. 3 root root 1024 Mar 12 17:23 part1
drwxr-xr-x. 3 root root 4096 Mar 12 17:23 part2
drwxr-xr-x. 3 root root 1024 Mar 12 17:23 part3
drwxr-xr-x. 3 root root 4096 Mar 12 17:23 part4
drwxr-xr-x. 3 root root 1024 Mar 12 17:23 part5
[root@mdadm /]# lsblk
NAME      MAJ:MIN RM   SIZE RO TYPE   MOUNTPOINT
sda         8:0    0    10G  0 disk   
└─sda1      8:1    0    10G  0 part   /
sdb         8:16   0     1G  0 disk   
└─md0       9:0    0   2.5G  0 raid10 
  ├─md0p1 259:0    0 507.5M  0 md     /raid/part1
  ├─md0p2 259:1    0 512.5M  0 md     /raid/part2
  ├─md0p3 259:2    0   510M  0 md     /raid/part3
  ├─md0p4 259:3    0 512.5M  0 md     /raid/part4
  └─md0p5 259:4    0 507.5M  0 md     /raid/part5
sdc         8:32   0     1G  0 disk   
└─md0       9:0    0   2.5G  0 raid10 
  ├─md0p1 259:0    0 507.5M  0 md     /raid/part1
  ├─md0p2 259:1    0 512.5M  0 md     /raid/part2
  ├─md0p3 259:2    0   510M  0 md     /raid/part3
  ├─md0p4 259:3    0 512.5M  0 md     /raid/part4
  └─md0p5 259:4    0 507.5M  0 md     /raid/part5
sdd         8:48   0     1G  0 disk   
└─md0       9:0    0   2.5G  0 raid10 
  ├─md0p1 259:0    0 507.5M  0 md     /raid/part1
  ├─md0p2 259:1    0 512.5M  0 md     /raid/part2
  ├─md0p3 259:2    0   510M  0 md     /raid/part3
  ├─md0p4 259:3    0 512.5M  0 md     /raid/part4
  └─md0p5 259:4    0 507.5M  0 md     /raid/part5
sde         8:64   0     1G  0 disk   
└─md0       9:0    0   2.5G  0 raid10 
  ├─md0p1 259:0    0 507.5M  0 md     /raid/part1
  ├─md0p2 259:1    0 512.5M  0 md     /raid/part2
  ├─md0p3 259:2    0   510M  0 md     /raid/part3
  ├─md0p4 259:3    0 512.5M  0 md     /raid/part4
  └─md0p5 259:4    0 507.5M  0 md     /raid/part5
sdf         8:80   0     1G  0 disk   
└─md0       9:0    0   2.5G  0 raid10 
  ├─md0p1 259:0    0 507.5M  0 md     /raid/part1
  ├─md0p2 259:1    0 512.5M  0 md     /raid/part2
  ├─md0p3 259:2    0   510M  0 md     /raid/part3
  ├─md0p4 259:3    0 512.5M  0 md     /raid/part4
  └─md0p5 259:4    0 507.5M  0 md     /raid/part5
[root@mdadm /]# cat /proc/mdstat
Personalities : [raid10] 
md0 : active raid10 sdb[5] sdf[4] sde[3] sdd[2] sdc[1]
      2616320 blocks super 1.2 512K chunks 2 near-copies [5/5] [UUUUU]
```