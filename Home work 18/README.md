## Резервное копирование
____

### Цель домашнего задания:

Научиться настраивать резервное копирование с помощью утилиты Borg.

### Описание домашнего задания:

1. Настроить стенд Vagrant с двумя виртуальными машинами: backup_server и client. (Студент самостоятельно настраивает Vagrant)
2. Настроить удаленный бэкап каталога /etc c сервера client при помощи borgbackup. Резервные копии должны соответствовать следующим критериям:
    a. директория для резервных копий /var/backup. Это должна быть отдельная точка монтирования. В данном случае для демонстрации размер не принципиален, достаточно будет и 2GB; (Студент самостоятельно настраивает)
    b. репозиторий для резервных копий должен быть зашифрован ключом или паролем - на усмотрение студента;
    c. имя бэкапа должно содержать информацию о времени снятия бекапа;
    d. глубина бекапа должна быть год, хранить можно по последней копии на конец месяца, кроме последних трех. Последние три месяца должны содержать копии на каждый день. Т.е. должна быть правильно настроена политика удаления старых бэкапов;
    e. резервная копия снимается каждые 5 минут. Такой частый запуск в целях демонстрации;
    f. написан скрипт для снятия резервных копий. Скрипт запускается из соответствующей Cron джобы, либо systemd timer-а - на усмотрение студента;
    g. настроено логирование процесса бекапа. Для упрощения можно весь вывод перенаправлять в logger с соответствующим тегом. Если настроите не в syslog, то обязательна ротация логов.

## Выполнение:

Создадим Vagrantfile, в котором будут указаны параметры наших ВМ:

```sh
ENV['VAGRANT_SERVER_URL'] = 'http://vagrant.elab.pro'


MACHINES = {
  :"backup" => {
              :box_name => "ubuntu/jammy64",
              :box_version => "1.0.0",
              :cpus => 1,
              :memory => 1024,
              :ip => '192.168.56.160',
            },
  :"client" => {
              :box_name => "ubuntu/jammy64",
              :box_version => "1.0.0",
              :cpus => 1,
              :memory => 1024,
              :ip => '192.168.56.150',
            }
}

Vagrant.configure("2") do |config|
  MACHINES.each do |boxname, boxconfig|
    config.vm.synced_folder ".", "/vagrant", disabled: true
    config.vm.define boxname do |box|
      box.vm.box = boxconfig[:box_name]
      box.vm.box_version = boxconfig[:box_version]
      box.vm.host_name = boxname.to_s
      box.vm.network "private_network", ip: boxconfig[:ip]
      box.vm.provider "virtualbox" do |v|
        v.memory = boxconfig[:memory]
        v.cpus = boxconfig[:cpus]
      end
      box.vm.provision "shell", inline: <<-SHELL
        mkdir -p ~root/.ssh
        cp ~vagrant/.ssh/auth* ~root/.ssh
        sed -i 's/^PasswordAuthentication.*$/PasswordAuthentication yes/' /etc/ssh/sshd_config
        systemctl restart sshd.service
      SHELL
    end
  end
end
```

После создания Vagrantfile запустим наши ВМ командой ```vagrant up```. Будут созданы две виртуальнае машины.

Устанавливаем на client и backup сервере borgbackup: ```apt update```, ```apt install borgbackup```

Создаем диск 2Gb и монтируем его:

```sh
root@backup:~# fdisk -l
Disk /dev/sdc: 2 GiB, 2147483648 bytes, 4194304 sectors
Disk model: HARDDISK        
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes

root@backup:~# fdisk /dev/sdc

Welcome to fdisk (util-linux 2.37.2).
Changes will remain in memory only, until you decide to write them.
Be careful before using the write command.

Device does not contain a recognized partition table.
Created a new DOS disklabel with disk identifier 0x65feff94.

Command (m for help): n
Partition type
   p   primary (0 primary, 0 extended, 4 free)
   e   extended (container for logical partitions)
Select (default p): 

Using default response p.
Partition number (1-4, default 1): 
First sector (2048-4194303, default 2048): 
Last sector, +/-sectors or +/-size{K,M,G,T,P} (2048-4194303, default 4194303): 

Created a new partition 1 of type 'Linux' and of size 2 GiB.

Command (m for help): t
Selected partition 1
Hex code or alias (type L to list all): 8e
Changed type of partition 'Linux' to 'Linux LVM'.

Command (m for help): w
The partition table has been altered.
Calling ioctl() to re-read partition table.
Syncing disks.

root@backup:~# mkfs.ext4 /dev/sdc1
mke2fs 1.46.5 (30-Dec-2021)
Creating filesystem with 524032 4k blocks and 131072 inodes
Filesystem UUID: c69ecce9-2061-4ec7-86d4-2746374eb5e9
Superblock backups stored on blocks: 
	32768, 98304, 163840, 229376, 294912

Allocating group tables: done                            
Writing inode tables: done                            
Creating journal (8192 blocks): done
Writing superblocks and filesystem accounting information: done 
```

На сервере backup создаем пользователя и каталог /var/backup и назначаем на него права пользователя borg:

```sh
root@backup:~# useradd -m borg

root@backup:~# mkdir /var/backup

root@backup:/var# chown borg:borg /var/backup/
root@backup:/var# ll
total 56
drwxr-xr-x 14 root root   4096 Jul  1 12:04 ./
drwxr-xr-x 19 root root   4096 Jul  1 11:55 ../
drwxr-xr-x  3 borg borg   4096 Jul  1 12:11 backup/
drwxr-xr-x  2 root root   4096 Apr 18  2022 backups/
drwxr-xr-x 11 root root   4096 Jul  1 11:17 cache/
drwxrwxrwt  2 root root   4096 May 10  2023 crash/
drwxr-xr-x 36 root root   4096 Jul  1 11:17 lib/
drwxrwsr-x  2 root staff  4096 Apr 18  2022 local/
lrwxrwxrwx  1 root root      9 May 10  2023 lock -> /run/lock/
drwxrwxr-x  8 root syslog 4096 Jul  1 11:58 log/
drwxrwsr-x  2 root mail   4096 May 10  2023 mail/
drwxr-xr-x  2 root root   4096 May 10  2023 opt/
lrwxrwxrwx  1 root root      4 May 10  2023 run -> /run/
drwxr-xr-x  5 root root   4096 May 10  2023 snap/
drwxr-xr-x  4 root root   4096 May 10  2023 spool/
drwxrwxrwt  6 root root   4096 Jul  1 11:56 tmp/

root@backup:~# mount /dev/sdc1 /var/backup
root@backup:~# df -h
Filesystem      Size  Used Avail Use% Mounted on
tmpfs            97M  960K   97M   1% /run
/dev/sda1        39G  1.8G   37G   5% /
tmpfs           485M     0  485M   0% /dev/shm
tmpfs           5.0M     0  5.0M   0% /run/lock
tmpfs            97M  4.0K   97M   1% /run/user/1000
/dev/sdc1       2.0G   24K  1.9G   1% /var/backup
```

На сервер backup создаем каталог ~/.ssh/authorized_keys в каталоге /home/borg

```sh
root@backup:/var# su - borg
$ mkdir .ssh
$ touch .ssh/authorized_keys
$ chmod 700 .ssh
$ chmod 600 .ssh/authorized_keys
$ ls -la
total 24
drwxr-x--- 3 borg borg 4096 Jul  1 12:17 .
drwxr-xr-x 5 root root 4096 Jul  1 12:04 ..
-rw-r--r-- 1 borg borg  220 Jan  6  2022 .bash_logout
-rw-r--r-- 1 borg borg 3771 Jan  6  2022 .bashrc
-rw-r--r-- 1 borg borg  807 Jan  6  2022 .profile
drwx------ 2 borg borg 4096 Jul  1 12:17 .ssh
```

На сервере client: 

```sh
root@client:~# ssh-keygen
Generating public/private rsa key pair.
Enter file in which to save the key (/root/.ssh/id_rsa): 
Enter passphrase (empty for no passphrase): 
Enter same passphrase again: 
Your identification has been saved in /root/.ssh/id_rsa
Your public key has been saved in /root/.ssh/id_rsa.pub
The key fingerprint is:
SHA256:8oNOvl95afovC2uObljFsYxjKgug5fp7IQ34GEG8hQo root@client
The key's randomart image is:
+---[RSA 3072]----+
|o..              |
|Eo .      .      |
|ooo      + o     |
|=.o     + =      |
|.B o  .oSo       |
|o = + .+.  . .   |
| . o +ooo + +    |
|.   o+. .+.*.    |
| .oo  +=+o+.o+.  |
+----[SHA256]-----+
```

Все дальнейшие действия будут проходить на client сервере.

Инициализируем репозиторий borg на backup сервере с client сервера:

```sh
root@client:~# borg init --encryption=repokey borg@192.168.56.160:/var/backup/client

root@backup:/var/backup# ll ./client/
total 76
drwx------ 3 borg borg  4096 Jul  1 19:02 ./
drwxr-xr-x 4 borg borg  4096 Jul  1 19:02 ../
-rw------- 1 borg borg    73 Jul  1 19:02 README
-rw------- 1 borg borg   700 Jul  1 19:02 config
drwx------ 3 borg borg  4096 Jul  1 19:02 data/
-rw------- 1 borg borg    70 Jul  1 19:02 hints.1
-rw------- 1 borg borg 41258 Jul  1 19:02 index.1
-rw------- 1 borg borg   190 Jul  1 19:02 integrity.1
-rw------- 1 borg borg    16 Jul  1 19:02 nonce
```

Запускаем для проверки создания бэкапа:

```sh
root@client:~# borg create --stats --progress --compression lz4 --list borg@192.168.56.160:/var/backup/client::"etc-{now:%Y-%m-%d_%H:%M:%S}" /etc

------------------------------------------------------------------------------                                                                          
Repository: ssh://borg@192.168.56.160/var/backup/client
Archive name: etc-2025-07-01_19:04:38
Archive fingerprint: 43fcf834afbb3e082730a0cddcbe7c0663d3cbe35355c710ddb229a73615a131
Time (start): Tue, 2025-07-01 19:04:48
Time (end):   Tue, 2025-07-01 19:04:59
Duration: 10.51 seconds
Number of files: 689
Utilization of max. archive size: 0%
------------------------------------------------------------------------------
                       Original size      Compressed size    Deduplicated size
This archive:                2.09 MB            920.48 kB            897.45 kB
All archives:                2.09 MB            919.83 kB            963.82 kB

                       Unique chunks         Total chunks
Chunk index:                     660                  682
------------------------------------------------------------------------------

```

Смотрим, что у нас получилось:

```sh
root@client:~# borg list borg@192.168.56.160:/var/backup/client
Enter passphrase for key ssh://borg@192.168.56.160/var/backup/client: 
etc-2025-07-01_19:04:38              Tue, 2025-07-01 19:04:48 [43fcf834afbb3e082730a0cddcbe7c0663d3cbe35355c710ddb229a73615a131]
```

Смотрим список файлов:

```sh
root@client:~# borg list borg@192.168.56.160:/var/backup/client::etc-2025-07-01_19:04:38
```

Достаем файл из бекапа:

```sh
root@client:~# borg extract borg@192.168.56.160:/var/backup/client::etc-2025-07-01_19:04:38 etc/hostname
Enter passphrase for key ssh://borg@192.168.56.160/var/backup/client:
```

### Автоматизируем создание бэкапов с помощью systemd

Создаем сервис и таймер в каталоге /etc/systemd/system/

```sh
root@client:~# vi /etc/systemd/system/borg-backup.service

root@client:~# cat /etc/systemd/system/borg-backup.service
[Unit]
Description=Borg Backup

[Service]
Type=oneshot

# Парольная фраза
Environment="BORG_PASSPHRASE=borg"
# Репозиторий
Environment=REPO=borg@192.168.56.160:/var/backup/client
# Что бэкапим
Environment=BACKUP_TARGET=/etc

# Создание бэкапа
ExecStart=/bin/borg create \
    --stats                \
    ${REPO}::etc-{now:%%Y-%%m-%%d_%%H:%%M:%%S} ${BACKUP_TARGET}

# Проверка бэкапа
ExecStart=/bin/borg check ${REPO}

# Очистка старых бэкапов
ExecStart=/bin/borg prune \
    --keep-daily  90      \
    --keep-monthly 12     \
    --keep-yearly  1       \
    ${REPO}
```

```sh
root@client:~# vi /etc/systemd/system/borg-backup.timer
root@client:~# cat /etc/systemd/system/borg-backup.timer
[Unit]
Description=Borg Backup

[Timer]
OnUnitActiveSec=5min
Unit=borg-backup.service

[Install]
WantedBy=timers.target
```

Включаем и запускаем службу таймера:

```sh
root@client:~# systemctl enable borg-backup.timer
Created symlink /etc/systemd/system/timers.target.wants/borg-backup.timer → /etc/systemd/system/borg-backup.timer.
root@client:~# systemctl start borg-backup.timer
```

Проверяем работу таймера

```sh
root@client:~# systemctl list-timers --all
NEXT                        LEFT          LAST                        PASSED       UNIT                           ACTIVATES                       
Tue 2025-07-01 19:52:18 UTC 1min 36s left Tue 2025-07-01 19:47:18 UTC 3min 23s ago borg-backup.timer              borg-backup.service
```

Настройка логирования:

Создаем файл конфигурации для сбора логов borg:

```sh
root@client:~# vi /etc/rsyslog.d/19-borg.conf

root@client:~# cat /etc/rsyslog.d/19-borg.conf 
if ( $programname startswith "borg" ) then {
    action(type="omfile" file="/var/log/borg.log" flushOnTXEnd="off")
    stop
}

root@client:~# systemctl restart rsyslog.service
```

Проверяем:

```sh
root@client:~# cat /var/log/borg.log 
Jul  2 10:26:17 client borg[4229]: ------------------------------------------------------------------------------
Jul  2 10:26:17 client borg[4229]: Repository: ssh://borg@192.168.56.160/var/backup/client
Jul  2 10:26:17 client borg[4229]: Archive name: etc-2025-07-02_10:26:10
Jul  2 10:26:17 client borg[4229]: Archive fingerprint: ee421491929a976dcc0c1a7547ca420026176167ef27b204ee59f3a85b207103
Jul  2 10:26:17 client borg[4229]: Time (start): Wed, 2025-07-02 10:26:16
Jul  2 10:26:17 client borg[4229]: Time (end):   Wed, 2025-07-02 10:26:17
Jul  2 10:26:17 client borg[4229]: Duration: 0.36 seconds
Jul  2 10:26:17 client borg[4229]: Number of files: 760
Jul  2 10:26:17 client borg[4229]: Utilization of max. archive size: 0%
Jul  2 10:26:17 client borg[4229]: ------------------------------------------------------------------------------
Jul  2 10:26:17 client borg[4229]:                        Original size      Compressed size    Deduplicated size
Jul  2 10:26:17 client borg[4229]: This archive:                2.21 MB            979.73 kB                844 B
Jul  2 10:26:17 client borg[4229]: All archives:                6.51 MB              2.88 MB              1.15 MB
Jul  2 10:26:17 client borg[4229]:                        Unique chunks         Total chunks
Jul  2 10:26:17 client borg[4229]: Chunk index:                     742                 2192
Jul  2 10:26:17 client borg[4229]: ------------------------------------------------------------------------------
```