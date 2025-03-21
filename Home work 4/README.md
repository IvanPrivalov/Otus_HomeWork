## Домашнее задание: Работа с ZFS
____

### Задание:

1. Определить алгоритм с наилучшим сжатием:
- Определить какие алгоритмы сжатия поддерживает zfs (gzip, zle, lzjb, lz4).
- Создать 4 файловых системы на каждой применить свой алгоритм сжатия, для сжатия использовать либо текстовый файл, либо группу файлов.

2. Определить настройки пула.
С помощью команды zfs import собрать pool ZFS.
Командами zfs определить настройки:
- размер хранилища;
- тип pool;
- значение recordsize;
- какое сжатие используется;
- какая контрольная сумма используется.

3. Работа со снапшотами:
- скопировать файл из удаленной директории;
- восстановить файл локально. zfs receive;
- найти зашифрованное сообщение в файле secret_message.

### Определение алгоритма с наилучшим сжатием

Список всех дисков, которые есть в виртуальной машине:

```sh
root@otus-server:~# lsblk
NAME                      MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda                         8:0    0   15G  0 disk 
├─sda1                      8:1    0    1M  0 part 
├─sda2                      8:2    0  1.8G  0 part /boot
└─sda3                      8:3    0 13.2G  0 part 
  └─ubuntu--vg-ubuntu--lv 252:0    0 13.2G  0 lvm  /
sdb                         8:16   0  512M  0 disk 
sdc                         8:32   0  512M  0 disk 
sdd                         8:48   0  512M  0 disk 
sde                         8:64   0  512M  0 disk 
sdf                         8:80   0  512M  0 disk 
sdg                         8:96   0  512M  0 disk 
sdh                         8:112  0  512M  0 disk 
sdi                         8:128  0  512M  0 disk 
```

Установим пакет утилит для ZFS:

```sh
root@otus-server:~# apt install zfsutils-linux -y
```

Создаём 4 пула из двух дисков в режиме RAID 1:

```sh
root@otus-server:~# zpool create otus1 mirror /dev/sdb /dev/sdc
root@otus-server:~# zpool create otus2 mirror /dev/sdd /dev/sde
root@otus-server:~# zpool create otus3 mirror /dev/sdf /dev/sdg
root@otus-server:~# zpool create otus4 mirror /dev/sdh /dev/sdi
root@otus-server:~# lsblk
NAME                      MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda                         8:0    0   15G  0 disk 
├─sda1                      8:1    0    1M  0 part 
├─sda2                      8:2    0  1.8G  0 part /boot
└─sda3                      8:3    0 13.2G  0 part 
  └─ubuntu--vg-ubuntu--lv 252:0    0 13.2G  0 lvm  /
sdb                         8:16   0  512M  0 disk 
├─sdb1                      8:17   0  502M  0 part 
└─sdb9                      8:25   0    8M  0 part 
sdc                         8:32   0  512M  0 disk 
├─sdc1                      8:33   0  502M  0 part 
└─sdc9                      8:41   0    8M  0 part 
sdd                         8:48   0  512M  0 disk 
├─sdd1                      8:49   0  502M  0 part 
└─sdd9                      8:57   0    8M  0 part 
sde                         8:64   0  512M  0 disk 
├─sde1                      8:65   0  502M  0 part 
└─sde9                      8:73   0    8M  0 part 
sdf                         8:80   0  512M  0 disk 
├─sdf1                      8:81   0  502M  0 part 
└─sdf9                      8:89   0    8M  0 part 
sdg                         8:96   0  512M  0 disk 
├─sdg1                      8:97   0  502M  0 part 
└─sdg9                      8:105  0    8M  0 part 
sdh                         8:112  0  512M  0 disk 
├─sdh1                      8:113  0  502M  0 part 
└─sdh9                      8:121  0    8M  0 part 
sdi                         8:128  0  512M  0 disk 
├─sdi1                      8:129  0  502M  0 part 
└─sdi9                      8:137  0    8M  0 part 
```

Информация о пулах:

```sh
root@otus-server:~# zpool list
NAME    SIZE  ALLOC   FREE  CKPOINT  EXPANDSZ   FRAG    CAP  DEDUP    HEALTH  ALTROOT
otus1   480M   112K   480M        -         -     0%     0%  1.00x    ONLINE  -
otus2   480M   116K   480M        -         -     0%     0%  1.00x    ONLINE  -
otus3   480M   116K   480M        -         -     0%     0%  1.00x    ONLINE  -
otus4   480M   122K   480M        -         -     0%     0%  1.00x    ONLINE  -
```

Добавим разные алгоритмы сжатия в каждую файловую систему:
- Алгоритм lzjb:
```sh
root@otus-server:~# zfs set compression=lzjb otus1
```

- Алгоритм lz4:
```sh
root@otus-server:~# zfs set compression=lz4 otus2
```

- Алгоритм gzip:
```sh
root@otus-server:~# zfs set compression=gzip-9 otus3
```

- Алгоритм zle:
```sh
root@otus-server:~# zfs set compression=zle otus4
```

Проверим, что все файловые системы имеют разные методы сжатия:

```sh
root@otus-server:~# zfs get all | grep compression
otus1  compression           lzjb                   local
otus2  compression           lz4                    local
otus3  compression           gzip-9                 local
otus4  compression           zle                    local
```

Сжатие файлов будет работать только с файлами, которые были добавлены после включение настройки сжатия. 
Скачаем один и тот же текстовый файл во все пулы:

```sh
root@otus-server:~# for i in {1..4}; do wget -P /otus$i https://gutenberg.org/cache/epub/2600/pg2600.converter.log; done
```

Проверим, что файл был скачан во все пулы:

```sh
root@otus-server:~# ll /otus*
/otus1:
total 22101
drwxr-xr-x  2 root root        3 Mar 21 09:49 ./
drwxr-xr-x 27 root root     4096 Mar 21 09:41 ../
-rw-r--r--  1 root root 41130189 Mar  2 08:31 pg2600.converter.log

/otus2:
total 18011
drwxr-xr-x  2 root root        3 Mar 21 09:49 ./
drwxr-xr-x 27 root root     4096 Mar 21 09:41 ../
-rw-r--r--  1 root root 41130189 Mar  2 08:31 pg2600.converter.log

/otus3:
total 10970
drwxr-xr-x  2 root root        3 Mar 21 09:49 ./
drwxr-xr-x 27 root root     4096 Mar 21 09:41 ../
-rw-r--r--  1 root root 41130189 Mar  2 08:31 pg2600.converter.log

/otus4:
total 40199
drwxr-xr-x  2 root root        3 Mar 21 09:49 ./
drwxr-xr-x 27 root root     4096 Mar 21 09:41 ../
-rw-r--r--  1 root root 41130189 Mar  2 08:31 pg2600.converter.log
```

На этом этапе видно, что самый оптимальный метод сжатия у нас используется в пуле otus3.
Проверим, сколько места занимает один и тот же файл в разных пулах и проверим степень сжатия файлов:

```sh
root@otus-server:~# zfs list
NAME    USED  AVAIL  REFER  MOUNTPOINT
otus1  21.7M   330M  21.6M  /otus1
otus2  17.7M   334M  17.6M  /otus2
otus3  10.9M   341M  10.7M  /otus3
otus4  39.4M   313M  39.3M  /otus4
root@otus-server:~# zfs get all | grep compressratio | grep -v ref
otus1  compressratio         1.81x                  -
otus2  compressratio         2.23x                  -
otus3  compressratio         3.65x                  -
otus4  compressratio         1.00x                  -
```

Таким образом, у нас получается, что алгоритм gzip-9 самый эффективный по сжатию.

### Определение настроек пула

Скачиваем архив в домашний каталог:

```sh
root@otus-server:~# wget -O archive.tar.gz --no-check-certificate 'https://drive.usercontent.google.com/download?id=1MvrcEp-WgAQe57aDEzxSRalPAwbNN1Bb&export=download'
```

Разархивируем его:

```sh
root@otus-server:~# tar -xzvf archive.tar.gz
zpoolexport/
zpoolexport/filea
zpoolexport/fileb
```

Импортируем данный каталог в пул:

```sh
root@otus-server:~# zpool import -d zpoolexport/
   pool: otus
     id: 6554193320433390805
  state: ONLINE
status: Some supported features are not enabled on the pool.
	(Note that they may be intentionally disabled if the
	'compatibility' property is set.)
 action: The pool can be imported using its name or numeric identifier, though
	some features will not be available without an explicit 'zpool upgrade'.
 config:

	otus                         ONLINE
	  mirror-0                   ONLINE
	    /root/zpoolexport/filea  ONLINE
	    /root/zpoolexport/fileb  ONLINE
```

Данный вывод показывает нам имя пула, тип raid и его состав. 
Сделаем импорт данного пула к нам в ОС:

```sh
root@otus-server:~# zpool import -d zpoolexport/ otus
root@otus-server:~# zpool status
  pool: otus
 state: ONLINE
status: Some supported and requested features are not enabled on the pool.
	The pool can still be used, but some features are unavailable.
action: Enable all features using 'zpool upgrade'. Once this is done,
	the pool may no longer be accessible by software that does not support
	the features. See zpool-features(7) for details.
config:

	NAME                         STATE     READ WRITE CKSUM
	otus                         ONLINE       0     0     0
	  mirror-0                   ONLINE       0     0     0
	    /root/zpoolexport/filea  ONLINE       0     0     0
	    /root/zpoolexport/fileb  ONLINE       0     0     0

errors: No known data errors
```

Команда zpool status выдаст нам информацию о составе импортированного пула.
Если у Вас уже есть пул с именем otus, то можно поменять его имя во время импорта: zpool import -d zpoolexport/ otus newotus
Далее нам нужно определить настройки: zpool get all otus
Запрос сразу всех параметром файловой системы: zfs get all otus

```sh
root@otus-server:~# zfs get all otus
NAME  PROPERTY              VALUE                  SOURCE
otus  type                  filesystem             -
otus  creation              Fri May 15  4:00 2020  -
otus  used                  2.04M                  -
otus  available             350M                   -
otus  referenced            24K                    -
otus  compressratio         1.00x                  -
otus  mounted               yes                    -
otus  quota                 none                   default
otus  reservation           none                   default
otus  recordsize            128K                   local
otus  mountpoint            /otus                  default
otus  sharenfs              off                    default
otus  checksum              sha256                 local
otus  compression           zle                    local
otus  atime                 on                     default
otus  devices               on                     default
otus  exec                  on                     default
otus  setuid                on                     default
otus  readonly              off                    default
otus  zoned                 off                    default
otus  snapdir               hidden                 default
otus  aclmode               discard                default
otus  aclinherit            restricted             default
otus  createtxg             1                      -
otus  canmount              on                     default
otus  xattr                 on                     default
otus  copies                1                      default
otus  version               5                      -
otus  utf8only              off                    -
otus  normalization         none                   -
otus  casesensitivity       sensitive              -
otus  vscan                 off                    default
otus  nbmand                off                    default
otus  sharesmb              off                    default
otus  refquota              none                   default
otus  refreservation        none                   default
otus  guid                  14592242904030363272   -
otus  primarycache          all                    default
otus  secondarycache        all                    default
otus  usedbysnapshots       0B                     -
otus  usedbydataset         24K                    -
otus  usedbychildren        2.01M                  -
otus  usedbyrefreservation  0B                     -
otus  logbias               latency                default
otus  objsetid              54                     -
otus  dedup                 off                    default
otus  mlslabel              none                   default
otus  sync                  standard               default
otus  dnodesize             legacy                 default
otus  refcompressratio      1.00x                  -
otus  written               24K                    -
otus  logicalused           1020K                  -
otus  logicalreferenced     12K                    -
otus  volmode               default                default
otus  filesystem_limit      none                   default
otus  snapshot_limit        none                   default
otus  filesystem_count      none                   default
otus  snapshot_count        none                   default
otus  snapdev               hidden                 default
otus  acltype               off                    default
otus  context               none                   default
otus  fscontext             none                   default
otus  defcontext            none                   default
otus  rootcontext           none                   default
otus  relatime              on                     default
otus  redundant_metadata    all                    default
otus  overlay               on                     default
otus  encryption            off                    default
otus  keylocation           none                   default
otus  keyformat             none                   default
otus  pbkdf2iters           0                      default
otus  special_small_blocks  0                      default
```

C помощью команды get можно уточнить конкретный параметр, например:
- Размер:

```sh
root@otus-server:~# zfs get available otus
NAME  PROPERTY   VALUE  SOURCE
otus  available  350M   -
```

- Тип:

```sh
root@otus-server:~# zfs get readonly otus
NAME  PROPERTY  VALUE   SOURCE
otus  readonly  off     default
```

- Значение recordsize:

```sh
root@otus-server:~# zfs get recordsize otus
NAME  PROPERTY    VALUE    SOURCE
otus  recordsize  128K     local
```

- Тип сжатия (или параметр отключения):

```sh
root@otus-server:~# zfs get compression otus
NAME  PROPERTY     VALUE           SOURCE
otus  compression  zle             local
```

- Тип контрольной суммы:

```sh
root@otus-server:~# zfs get checksum otus
NAME  PROPERTY  VALUE      SOURCE
otus  checksum  sha256     local
```

### Работа со снапшотом, поиск сообщения от преподавателя

Скачаем файл, указанный в задании:

```sh
root@otus-server:~# wget -O otus_task2.file --no-check-certificate https://drive.usercontent.google.com/download?id=1wgxjih8YZ-cqLqaZVa0lA3h3Y029c3oI&export=download
```

Восстановим файловую систему из снапшота:

```sh
root@otus-server:~# zfs receive otus/test@today < otus_task2.file
```

Далее, ищем в каталоге /otus/test файл с именем “secret_message”:

```sh
root@otus-server:~# find /otus/test -name "secret_message"
/otus/test/task1/file_mess/secret_message
```

Смотрим содержимое найденного файла:

```sh
root@otus-server:~# cat /otus/test/task1/file_mess/secret_message
https://otus.ru/lessons/linux-hl/
```