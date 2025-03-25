## Домашнее задание: Работа с NFS
____

### Задание:

- запустить 2 виртуальных машины (сервер NFS и клиента);
- на сервере NFS должна быть подготовлена и экспортирована директория; 
- в экспортированной директории должна быть поддиректория с именем upload с правами на запись в неё; 
- экспортированная директория должна автоматически монтироваться на клиенте при старте виртуальной машины (systemd, autofs или fstab — любым способом);
- монтирование и работа NFS на клиенте должна быть организована с использованием NFSv3.

### Запустить 2 виртуальных машины (сервер NFS и клиента)

Создаём 2 виртуальные машины с сетевыми интерфейсами, которые позволяют связь между ними. 
Далее будем называть ВМ с NFS сервером nfss (IP 192.168.0.170), а ВМ с клиентом nfsc (IP 192.168.0.171).

```sh
root@nfss:~# ip a show dev enp0s3 | grep inet
    inet 192.168.0.170/24 metric 100 brd 192.168.0.255 scope global dynamic enp0s3

root@nfsc:~# ip a show dev enp0s3 | grep inet 
    inet 192.168.0.171/24 metric 100 brd 192.168.0.255 scope global dynamic enp0s3
```

### Настроим сервер NFS

```sh
root@nfss:~# apt install nfs-kernel-server
```

Создаём и настраиваем директорию, которая будет экспортирована в будущем:

```sh
root@nfss:~# mkdir -p /srv/share/upload
root@nfss:~# chown -R nobody:nogroup /srv/share
root@nfss:~# chmod 0777 /srv/share/upload
root@nfss:~# ll /srv/
total 12
drwxr-xr-x  3 root   root    4096 Mar 25 10:45 ./
drwxr-xr-x 23 root   root    4096 Mar 21 07:42 ../
drwxr-xr-x  3 nobody nogroup 4096 Mar 25 10:45 share/
root@nfss:~# ll /srv/share/
total 12
drwxr-xr-x 3 nobody nogroup 4096 Mar 25 10:45 ./
drwxr-xr-x 3 root   root    4096 Mar 25 10:45 ../
drwxrwxrwx 2 nobody nogroup 4096 Mar 25 10:45 upload/
```

Cоздаём в файле /etc/exports структуру, которая позволит экспортировать ранее созданную директорию:

```sh
root@nfss:~# cat << EOF > /etc/exports 
/srv/share 192.168.0.171/24(rw,sync,root_squash)
EOF
root@nfss:~# cat /etc/exports
/srv/share 192.168.0.171/24(rw,sync,root_squash)
```

Экспортируем ранее созданную директорию:

```sh
root@nfss:/etc# exportfs -r
exportfs: /etc/exports [1]: Neither 'subtree_check' or 'no_subtree_check' specified for export "192.168.0.171/24:/srv/share".
  Assuming default behaviour ('no_subtree_check').
  NOTE: this default has changed since nfs-utils version 1.0.x

root@nfss:/etc# exportfs -s
/srv/share  192.168.0.171/24(sync,wdelay,hide,no_subtree_check,sec=sys,rw,secure,root_squash,no_all_squash)
```

### Настраиваем клиент NFS

Установим пакет с NFS-клиентом:

```sh
root@nfsc:~# apt install nfs-common
```

Добавляем в /etc/fstab строку:

```sh
root@nfsc:~# echo "192.168.0.170:/srv/share/ /mnt nfs vers=3,noauto,x-systemd.automount 0 0" >> /etc/fstab

root@nfsc:~# cat /etc/fstab
/dev/disk/by-id/dm-uuid-LVM-6rwW4oSi6ILcsSaZ0DkFHx3ecmk1Pcut1nERRReZXanFBDDS2Z6WeifmST7V8KNJ / ext4 defaults 0 1
/dev/disk/by-uuid/bacbe23f-d6ac-4ca8-a4f7-c0fb8f431714 /boot ext4 defaults 0 1
/swap.img	none	swap	sw	0	0
192.168.0.170:/srv/share/ /mnt nfs vers=3,noauto,x-systemd.automount 0 0
```

Выполняем команды:

```sh
root@nfsc:~# systemctl daemon-reload
root@nfsc:~# systemctl restart remote-fs.target
```

Отметим, что в данном случае происходит автоматическая генерация systemd units в каталоге /run/systemd/generator/, которые производят монтирование при первом обращении к каталогу /mnt/.
Заходим в директорию /mnt/ и проверяем успешность монтирования:

```sh
root@nfsc:/mnt# mount | grep mnt
systemd-1 on /mnt type autofs (rw,relatime,fd=60,pgrp=1,timeout=0,minproto=5,maxproto=5,direct,pipe_ino=11132)
192.168.0.170:/srv/share/ on /mnt type nfs (rw,relatime,vers=3,rsize=262144,wsize=262144,namlen=255,hard,proto=tcp,timeo=600,retrans=2,sec=sys,mountaddr=192.168.0.170,mountvers=3,mountport=40603,mountproto=udp,local_lock=none,addr=192.168.0.170)
```

### Проверка работоспособности

- Заходим на сервер. 
- Заходим в каталог /srv/share/upload.
- Создаём тестовый файл touch check_file.

```sh
root@nfss:/srv/share/upload# touch check_file
root@nfss:/srv/share/upload# ll
total 8
drwxrwxrwx 2 nobody nogroup 4096 Mar 25 11:11 ./
drwxr-xr-x 3 nobody nogroup 4096 Mar 25 10:45 ../
-rw-r--r-- 1 root   root       0 Mar 25 11:11 check_file
```

- Заходим на клиент.
- Заходим в каталог /mnt/upload. 
- Проверяем наличие ранее созданного файла.

```sh
root@nfsc:/mnt/upload# ll
total 8
drwxrwxrwx 2 nobody nogroup 4096 Mar 25 11:11 ./
drwxr-xr-x 3 nobody nogroup 4096 Mar 25 10:45 ../
-rw-r--r-- 1 root   root       0 Mar 25 11:11 check_file
```

- Создаём тестовый файл touch client_file. 
- Проверяем, что файл успешно создан.

```sh
root@nfsc:/mnt/upload# touch client_file
root@nfsc:/mnt/upload# ll
total 8
drwxrwxrwx 2 nobody nogroup 4096 Mar 25 11:12 ./
drwxr-xr-x 3 nobody nogroup 4096 Mar 25 10:45 ../
-rw-r--r-- 1 root   root       0 Mar 25 11:11 check_file
-rw-r--r-- 1 nobody nogroup    0 Mar 25 11:12 client_file

root@nfss:/srv/share/upload# ll
total 8
drwxrwxrwx 2 nobody nogroup 4096 Mar 25 11:12 ./
drwxr-xr-x 3 nobody nogroup 4096 Mar 25 10:45 ../
-rw-r--r-- 1 root   root       0 Mar 25 11:11 check_file
-rw-r--r-- 1 nobody nogroup    0 Mar 25 11:12 client_file
```

#### Предварительно проверяем клиент: 

1. перезагружаем клиент;
2. заходим на клиент;
3. заходим в каталог /mnt/upload;
4. проверяем наличие ранее созданных файлов.

```sh
root@nfsc:/mnt/upload# reboot

Broadcast message from root@nfsc on pts/2 (Tue 2025-03-25 11:22:09 UTC):

The system will reboot now!

root@nfsc:/mnt/upload# client_loop: send disconnect: Broken pipe
ivan@ivan-Otus:~$ ssh 192.168.0.171
ivan@192.168.0.171's password: 
Welcome to Ubuntu 24.04.2 LTS (GNU/Linux 6.8.0-55-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/pro

This system has been minimized by removing packages and content that are
not required on a system that users do not log into.

To restore this content, you can run the 'unminimize' command.
Last login: Tue Mar 25 10:29:14 2025 from 192.168.0.163
ivan@nfsc:~$ sudo -i
[sudo] password for ivan: 

root@nfsc:~# cd /mnt/upload/
root@nfsc:/mnt/upload# ll
total 8
drwxrwxrwx 2 nobody nogroup 4096 Mar 25 11:12 ./
drwxr-xr-x 3 nobody nogroup 4096 Mar 25 10:45 ../
-rw-r--r-- 1 root   root       0 Mar 25 11:11 check_file
-rw-r--r-- 1 nobody nogroup    0 Mar 25 11:12 client_file
```

#### Проверяем сервер: 

1. заходим на сервер в отдельном окне терминала;
2. перезагружаем сервер;
3. заходим на сервер;
4. проверяем наличие файлов в каталоге /srv/share/upload/;
5. проверяем экспорты exportfs -s;
6. проверяем работу RPC showmount -a 192.168.0.170.

```sh
root@nfss:/srv/share/upload# reboot

Broadcast message from root@nfss on pts/2 (Tue 2025-03-25 11:27:08 UTC):

The system will reboot now!

root@nfss:/srv/share/upload# client_loop: send disconnect: Broken pipe
ivan@ivan-Otus:~$ ssh 192.168.0.170
ivan@192.168.0.170's password: 
Welcome to Ubuntu 24.04.2 LTS (GNU/Linux 6.8.0-55-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/pro

This system has been minimized by removing packages and content that are
not required on a system that users do not log into.

To restore this content, you can run the 'unminimize' command.
Last login: Tue Mar 25 10:28:13 2025 from 192.168.0.163
ivan@nfss:~$ sudo -i
[sudo] password for ivan: 
root@nfss:~# ll /srv/share/upload/
total 8
drwxrwxrwx 2 nobody nogroup 4096 Mar 25 11:12 ./
drwxr-xr-x 3 nobody nogroup 4096 Mar 25 10:45 ../
-rw-r--r-- 1 root   root       0 Mar 25 11:11 check_file
-rw-r--r-- 1 nobody nogroup    0 Mar 25 11:12 client_file
root@nfss:~# exportfs -s
/srv/share  192.168.0.171/24(sync,wdelay,hide,no_subtree_check,sec=sys,rw,secure,root_squash,no_all_squash)
root@nfss:~# showmount -a 192.168.0.170
All mount points on 192.168.0.170:
192.168.0.171:/srv/share
```

#### Проверяем клиент: 
1. возвращаемся на клиент;
2. перезагружаем клиент;
3. заходим на клиент;
4. проверяем работу RPC showmount -a 192.168.0.170;
5. заходим в каталог /mnt/upload;
6. проверяем статус монтирования mount | grep mnt;
7. проверяем наличие ранее созданных файлов;
8. создаём тестовый файл touch final_check;
9. проверяем, что файл успешно создан.

```sh
root@nfsc:/mnt/upload# reboot

Broadcast message from root@nfsc on pts/1 (Tue 2025-03-25 11:32:16 UTC):

The system will reboot now!

root@nfsc:/mnt/upload# client_loop: send disconnect: Broken pipe
ivan@ivan-Otus:~$ ssh 192.168.0.171
ivan@192.168.0.171's password: 
Welcome to Ubuntu 24.04.2 LTS (GNU/Linux 6.8.0-55-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/pro

This system has been minimized by removing packages and content that are
not required on a system that users do not log into.

To restore this content, you can run the 'unminimize' command.
Last login: Tue Mar 25 11:22:39 2025 from 192.168.0.163
ivan@nfsc:~$ sudo -i
[sudo] password for ivan: 
root@nfsc:~# showmount -a 192.168.0.170
All mount points on 192.168.0.170:
root@nfsc:~# cd /mnt/
root@nfsc:/mnt# showmount -a 192.168.0.170
All mount points on 192.168.0.170:
192.168.0.171:/srv/share
root@nfsc:/mnt# cd ./upload/
root@nfsc:/mnt/upload# mount | grep mnt
systemd-1 on /mnt type autofs (rw,relatime,fd=63,pgrp=1,timeout=0,minproto=5,maxproto=5,direct,pipe_ino=3753)
192.168.0.170:/srv/share/ on /mnt type nfs (rw,relatime,vers=3,rsize=262144,wsize=262144,namlen=255,hard,proto=tcp,timeo=600,retrans=2,sec=sys,mountaddr=192.168.0.170,mountvers=3,mountport=57990,mountproto=udp,local_lock=none,addr=192.168.0.170)
root@nfsc:/mnt/upload# ll
total 8
drwxrwxrwx 2 nobody nogroup 4096 Mar 25 11:12 ./
drwxr-xr-x 3 nobody nogroup 4096 Mar 25 10:45 ../
-rw-r--r-- 1 root   root       0 Mar 25 11:11 check_file
-rw-r--r-- 1 nobody nogroup    0 Mar 25 11:12 client_file
root@nfsc:/mnt/upload# touch final_check
root@nfsc:/mnt/upload# ll
total 8
drwxrwxrwx 2 nobody nogroup 4096 Mar 25 11:34 ./
drwxr-xr-x 3 nobody nogroup 4096 Mar 25 10:45 ../
-rw-r--r-- 1 root   root       0 Mar 25 11:11 check_file
-rw-r--r-- 1 nobody nogroup    0 Mar 25 11:12 client_file
-rw-r--r-- 1 nobody nogroup    0 Mar 25 11:34 final_check
```

Проверяем файл final_check на сервере:

```sh
root@nfss:~# cd /srv/share/upload/
root@nfss:/srv/share/upload# ll
total 8
drwxrwxrwx 2 nobody nogroup 4096 Mar 25 11:34 ./
drwxr-xr-x 3 nobody nogroup 4096 Mar 25 10:45 ../
-rw-r--r-- 1 root   root       0 Mar 25 11:11 check_file
-rw-r--r-- 1 nobody nogroup    0 Mar 25 11:12 client_file
-rw-r--r-- 1 nobody nogroup    0 Mar 25 11:34 final_check
```

### Автоматизированное развертывание

Создал два bash-скрипта, nfss_script.sh — для конфигурирования сервера и nfsc_script.sh — для конфигурирования клиента

Копируем на сервер nfss в папку /tmp скрипт nfss_script.sh
Даем права на запуск скрипта:

```sh
root@nfss:/tmp# chmod 0777 ./nfss_script.sh 
root@nfss:/tmp# ll
total 44
drwxrwxrwt 10 root root 4096 Mar 25 12:41 ./
drwxr-xr-x 23 root root 4096 Mar 21 07:42 ../
drwxrwxrwt  2 root root 4096 Mar 21 07:45 .ICE-unix/
drwxrwxrwt  2 root root 4096 Mar 21 07:45 .X11-unix/
drwxrwxrwt  2 root root 4096 Mar 21 07:45 .XIM-unix/
drwxrwxrwt  2 root root 4096 Mar 21 07:45 .font-unix/
-rwxrwxrwx  1 ivan ivan  227 Mar 25 12:39 nfss_script.sh*
```

Запускаем скрипт:

```sh
root@nfss:/tmp# ./nfss_script.sh
```

Копируем на клиент nfsc в папку /tmp скрипт nfsc_script.sh
Даем права на запуск скрипта:

```sh
root@nfsc:~# chmod 0777 /tmp/nfsc_script.sh 
root@nfsc:~# chown root:root /tmp/nfsc_script.sh 
root@nfsc:~# ll /tmp/
total 48
drwxrwxrwt 11 root root 4096 Mar 25 12:44 ./
drwxr-xr-x 23 root root 4096 Mar 21 07:42 ../
drwxrwxrwt  2 root root 4096 Mar 25 12:16 .ICE-unix/
drwxrwxrwt  2 root root 4096 Mar 25 12:16 .X11-unix/
drwxrwxrwt  2 root root 4096 Mar 25 12:16 .XIM-unix/
drwxrwxrwt  2 root root 4096 Mar 25 12:16 .font-unix/
-rwxrwxrwx  1 root root  190 Mar 25 12:39 nfsc_script.sh*
```

Запускаем скрипт:

```sh
root@nfsc:/tmp# ./nfsc_script.sh
```

#### Проверка работоспособности 

```sh
root@nfss:/tmp# cd /srv/share/upload
root@nfss:/srv/share/upload# touch check_file
root@nfss:/srv/share/upload# ll
total 8
drwxrwxrwx 2 nobody nogroup 4096 Mar 25 12:46 ./
drwxr-xr-x 3 nobody nogroup 4096 Mar 25 12:45 ../
-rw-r--r-- 1 root   root       0 Mar 25 12:46 check_file
root@nfss:/srv/share/upload# ll
total 8
drwxrwxrwx 2 nobody nogroup 4096 Mar 25 12:47 ./
drwxr-xr-x 3 nobody nogroup 4096 Mar 25 12:45 ../
-rw-r--r-- 1 root   root       0 Mar 25 12:46 check_file
-rw-r--r-- 1 nobody nogroup    0 Mar 25 12:47 client_file

root@nfsc:/tmp# cd /mnt/upload
root@nfsc:/mnt/upload# ll
total 8
drwxrwxrwx 2 nobody nogroup 4096 Mar 25 12:46 ./
drwxr-xr-x 3 nobody nogroup 4096 Mar 25 12:45 ../
-rw-r--r-- 1 root   root       0 Mar 25 12:46 check_file
root@nfsc:/mnt/upload# touch client_file
root@nfsc:/mnt/upload# ll
total 8
drwxrwxrwx 2 nobody nogroup 4096 Mar 25 12:47 ./
drwxr-xr-x 3 nobody nogroup 4096 Mar 25 12:45 ../
-rw-r--r-- 1 root   root       0 Mar 25 12:46 check_file
-rw-r--r-- 1 nobody nogroup    0 Mar 25 12:47 client_file
```

#### Предварительно проверяем клиент: 

1. перезагружаем клиент;
2. заходим на клиент;
3. заходим в каталог /mnt/upload;
4. проверяем наличие ранее созданных файлов.

```sh
root@nfsc:/mnt/upload# reboot

Broadcast message from root@otus-server on pts/4 (Tue 2025-03-25 12:57:26 UTC):

The system will reboot now!

root@nfsc:/mnt/upload# client_loop: send disconnect: Broken pipe
ivan@ivan-Otus:~$ ssh 192.168.0.173
ivan@192.168.0.173's password: 
Welcome to Ubuntu 24.04.2 LTS (GNU/Linux 6.8.0-55-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/pro

This system has been minimized by removing packages and content that are
not required on a system that users do not log into.

To restore this content, you can run the 'unminimize' command.
Failed to connect to https://changelogs.ubuntu.com/meta-release-lts. Check your Internet connection or proxy settings

Last login: Tue Mar 25 12:39:59 2025 from 192.168.0.163
ivan@nfsc:~$ sudo -i
[sudo] password for ivan: 
root@nfsc:~# cd /mnt/upload/
root@nfsc:/mnt/upload# ll
total 8
drwxrwxrwx 2 nobody nogroup 4096 Mar 25 12:47 ./
drwxr-xr-x 3 nobody nogroup 4096 Mar 25 12:45 ../
-rw-r--r-- 1 root   root       0 Mar 25 12:46 check_file
-rw-r--r-- 1 nobody nogroup    0 Mar 25 12:47 client_file
```

#### Проверяем сервер: 

1. заходим на сервер в отдельном окне терминала;
2. перезагружаем сервер;
3. заходим на сервер;
4. проверяем наличие файлов в каталоге /srv/share/upload/;
5. проверяем экспорты exportfs -s;
6. проверяем работу RPC showmount -a 192.168.0.170.

```sh
root@nfss:/srv/share# reboot

Broadcast message from root@nfss on pts/1 (Tue 2025-03-25 13:09:30 UTC):

The system will reboot now!

root@nfss:/srv/share# client_loop: send disconnect: Broken pipe
ivan@ivan-Otus:~$ ssh 192.168.0.170
ivan@192.168.0.170's password: 
Welcome to Ubuntu 24.04.2 LTS (GNU/Linux 6.8.0-55-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/pro

This system has been minimized by removing packages and content that are
not required on a system that users do not log into.

To restore this content, you can run the 'unminimize' command.
Last login: Tue Mar 25 13:01:30 2025 from 192.168.0.163
ivan@nfss:~$ sudo -i
[sudo] password for ivan: 
root@nfss:~# ll /srv/share/upload/
total 8
drwxrwxrwx 2 nobody nogroup 4096 Mar 25 12:47 ./
drwxr-xr-x 3 nobody nogroup 4096 Mar 25 12:45 ../
-rw-r--r-- 1 root   root       0 Mar 25 12:46 check_file
-rw-r--r-- 1 nobody nogroup    0 Mar 25 12:47 client_file
root@nfss:~# exportfs -s
/srv/share  192.168.0.173/24(sync,wdelay,hide,no_subtree_check,sec=sys,rw,secure,root_squash,no_all_squash)
root@nfss:~# showmount -a 192.168.0.170
All mount points on 192.168.0.170:
192.168.0.173:/srv/share
```

#### Проверяем клиент: 
1. возвращаемся на клиент;
2. перезагружаем клиент;
3. заходим на клиент;
4. проверяем работу RPC showmount -a 192.168.0.170;
5. заходим в каталог /mnt/upload;
6. проверяем статус монтирования mount | grep mnt;
7. проверяем наличие ранее созданных файлов;
8. создаём тестовый файл touch final_check;
9. проверяем, что файл успешно создан.

```sh
root@nfsc:~# reboot

Broadcast message from root@nfsc on pts/1 (Tue 2025-03-25 13:16:12 UTC):

The system will reboot now!

root@nfsc:~# client_loop: send disconnect: Broken pipe
ivan@ivan-Otus:~$ ssh 192.168.0.173
ivan@192.168.0.173's password: 
Welcome to Ubuntu 24.04.2 LTS (GNU/Linux 6.8.0-55-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/pro

This system has been minimized by removing packages and content that are
not required on a system that users do not log into.

To restore this content, you can run the 'unminimize' command.
Failed to connect to https://changelogs.ubuntu.com/meta-release-lts. Check your Internet connection or proxy settings

Last login: Tue Mar 25 13:15:52 2025 from 192.168.0.163
ivan@nfsc:~$ sudo -i
[sudo] password for ivan: 
root@nfsc:~# cd /mnt/
root@nfsc:/mnt# showmount -a 192.168.0.170
All mount points on 192.168.0.170:
192.168.0.173:/srv/share
root@nfsc:/mnt# cd ./upload/
root@nfsc:/mnt/upload# mount | grep mnt
systemd-1 on /mnt type autofs (rw,relatime,fd=57,pgrp=1,timeout=0,minproto=5,maxproto=5,direct,pipe_ino=3930)
192.168.0.170:/srv/share/ on /mnt type nfs (rw,relatime,vers=3,rsize=262144,wsize=262144,namlen=255,hard,proto=tcp,timeo=600,retrans=2,sec=sys,mountaddr=192.168.0.170,mountvers=3,mountport=45977,mountproto=udp,local_lock=none,addr=192.168.0.170)
root@nfsc:/mnt/upload# ll
total 8
drwxrwxrwx 2 nobody nogroup 4096 Mar 25 12:47 ./
drwxr-xr-x 3 nobody nogroup 4096 Mar 25 12:45 ../
-rw-r--r-- 1 root   root       0 Mar 25 12:46 check_file
-rw-r--r-- 1 nobody nogroup    0 Mar 25 12:47 client_file
root@nfsc:/mnt/upload# touch final_check
root@nfsc:/mnt/upload# ll
total 8
drwxrwxrwx 2 nobody nogroup 4096 Mar 25 13:19 ./
drwxr-xr-x 3 nobody nogroup 4096 Mar 25 12:45 ../
-rw-r--r-- 1 root   root       0 Mar 25 12:46 check_file
-rw-r--r-- 1 nobody nogroup    0 Mar 25 12:47 client_file
-rw-r--r-- 1 nobody nogroup    0 Mar 25 13:19 final_check


root@nfss:~# cd /srv/share/upload/
root@nfss:/srv/share/upload# ll
total 8
drwxrwxrwx 2 nobody nogroup 4096 Mar 25 13:19 ./
drwxr-xr-x 3 nobody nogroup 4096 Mar 25 12:45 ../
-rw-r--r-- 1 root   root       0 Mar 25 12:46 check_file
-rw-r--r-- 1 nobody nogroup    0 Mar 25 12:47 client_file
-rw-r--r-- 1 nobody nogroup    0 Mar 25 13:19 final_check
```