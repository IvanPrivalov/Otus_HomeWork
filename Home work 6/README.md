## Домашнее задание: Управление пакетами. Дистрибьюция софта. Размещаем свой RPM в своем репозитории.
____

### Задание:

1. Создать свой RPM пакет (можно взять свое приложение, либо собрать, например,
Apache с определенными опциями).
2. Создать свой репозиторий и разместить там ранее собранный RPM.

Реализовать это все либо в Vagrant, либо развернуть у себя через Nginx и дать ссылку на репозиторий.

### Создать свой RPM пакет

Нам понадобятся следующие установленные пакеты:

```sh
[root@RPM ~]# yum install -y wget rpmdevtools rpm-build createrepo yum-utils cmake gcc git nano
```

Для примера возьмем пакет Nginx и соберем его с дополнительным модулем ngx_broli

Загрузим SRPM пакет Nginx для дальнейшей работы над ним:

```sh
[root@RPM ~]# mkdir rpm && cd rpm

[root@RPM rpm]# yumdownloader --source nginx
enabling appstream-source repository
enabling baseos-source repository
enabling extras-source repository
AlmaLinux 9 - AppStream - Source                                                                                                                        440 kB/s | 856 kB     00:01    
AlmaLinux 9 - BaseOS - Source                                                                                                                           171 kB/s | 312 kB     00:01    
AlmaLinux 9 - Extras - Source                                                                                                                           5.5 kB/s | 8.2 kB     00:01    
nginx-1.20.1-20.el9.alma.1.src.rpm                                                                                                                      1.3 MB/s | 1.1 MB     00:00

[root@RPM rpm]# ll
total 1084
-rw-r--r--. 1 root root 1109119 Mar 26 06:53 nginx-1.20.1-20.el9.alma.1.src.rpm
```

При установке такого пакета в домашней директории создается дерево каталогов для сборки, далее поставим все зависимости для сборки пакета Nginx:

```sh
[root@RPM rpm]# rpm -Uvh nginx*.src.rpm
[root@RPM rpm]# yum-builddep nginx -y
```

Нужно скачать исходный код модуля ngx_brotli — он потребуется при сборке:

```sh
[root@RPM rpm]# cd /root

[root@RPM ~]# git clone --recurse-submodules -j8 https://github.com/google/ngx_brotli
Cloning into 'ngx_brotli'...
remote: Enumerating objects: 237, done.
remote: Counting objects: 100% (37/37), done.
remote: Compressing objects: 100% (16/16), done.
remote: Total 237 (delta 24), reused 21 (delta 21), pack-reused 200 (from 1)
Receiving objects: 100% (237/237), 79.51 KiB | 646.00 KiB/s, done.
Resolving deltas: 100% (114/114), done.
Submodule 'deps/brotli' (https://github.com/google/brotli.git) registered for path 'deps/brotli'
Cloning into '/root/ngx_brotli/deps/brotli'...
remote: Enumerating objects: 7810, done.        
remote: Counting objects: 100% (18/18), done.        
remote: Compressing objects: 100% (17/17), done.        
remote: Total 7810 (delta 6), reused 1 (delta 1), pack-reused 7792 (from 2)        
Receiving objects: 100% (7810/7810), 40.62 MiB | 3.70 MiB/s, done.
Resolving deltas: 100% (5067/5067), done.
Submodule path 'deps/brotli': checked out 'ed738e842d2fbdf2d6459e39267a633c4a9b2f5d'

[root@RPM ~]# ll
total 0
drwxr-xr-x. 7 root root 179 Mar 26 07:18 ngx_brotli
drwxr-xr-x. 2 root root  48 Mar 26 07:12 rpm
drwxr-xr-x. 4 root root  34 Mar 26 07:06 rpmbuild

[root@RPM ~]# cd ngx_brotli/deps/brotli
[root@RPM brotli]# mkdir out && cd out
```

Собираем модуль ngx_brotli:

```sh
[root@RPM out]# cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF -DCMAKE_C_FLAGS="-Ofast -m64 -march=native -mtune=native -flto -funroll-loops -ffunction-sections -fdata-sections -Wl,--gc-sections" -DCMAKE_CXX_FLAGS="-Ofast -m64 -march=native -mtune=native -flto -funroll-loops -ffunction-sections -fdata-sections -Wl,--gc-sections" -DCMAKE_INSTALL_PREFIX=./installed ..
-- The C compiler identification is GNU 11.5.0
-- Detecting C compiler ABI info
-- Detecting C compiler ABI info - done
-- Check for working C compiler: /bin/cc - skipped
-- Detecting C compile features
-- Detecting C compile features - done
-- Build type is 'Release'
-- Performing Test BROTLI_EMSCRIPTEN
-- Performing Test BROTLI_EMSCRIPTEN - Failed
-- Compiler is not EMSCRIPTEN
-- Looking for log2
-- Looking for log2 - not found
-- Looking for log2
-- Looking for log2 - found
-- Configuring done (7.3s)
-- Generating done (0.1s)
CMake Warning:
  Manually-specified variables were not used by the project:

    CMAKE_CXX_FLAGS

-- Build files have been written to: /root/ngx_brotli/deps/brotli/out

[root@RPM out]# ll
total 136
-rw-r--r--.  1 root root 17864 Mar 26 07:26 CMakeCache.txt
drwxr-xr-x. 37 root root  4096 Mar 26 07:26 CMakeFiles
-rw-r--r--.  1 root root  4006 Mar 26 07:26 cmake_install.cmake
-rw-r--r--.  1 root root 39592 Mar 26 07:26 CTestTestfile.cmake
-rw-r--r--.  1 root root  2464 Mar 26 07:26 DartConfiguration.tcl
-rw-r--r--.  1 root root   336 Mar 26 07:26 libbrotlicommon.pc
-rw-r--r--.  1 root root   363 Mar 26 07:26 libbrotlidec.pc
-rw-r--r--.  1 root root   363 Mar 26 07:26 libbrotlienc.pc
-rw-r--r--.  1 root root 52425 Mar 26 07:26 Makefile
drwxr-xr-x.  3 root root    23 Mar 26 07:26 Testing

[root@RPM out]# cmake --build . --config Release -j 2 --target brotlienc
[  6%] Building C object CMakeFiles/brotlicommon.dir/c/common/context.c.o
[  6%] Building C object CMakeFiles/brotlicommon.dir/c/common/constants.c.o
[ 10%] Building C object CMakeFiles/brotlicommon.dir/c/common/dictionary.c.o
[ 13%] Building C object CMakeFiles/brotlicommon.dir/c/common/platform.c.o
[ 17%] Building C object CMakeFiles/brotlicommon.dir/c/common/shared_dictionary.c.o
[ 20%] Building C object CMakeFiles/brotlicommon.dir/c/common/transform.c.o
[ 24%] Linking C static library libbrotlicommon.a
[ 24%] Built target brotlicommon
[ 27%] Building C object CMakeFiles/brotlienc.dir/c/enc/backward_references_hq.c.o
[ 31%] Building C object CMakeFiles/brotlienc.dir/c/enc/backward_references.c.o
[ 34%] Building C object CMakeFiles/brotlienc.dir/c/enc/bit_cost.c.o
[ 37%] Building C object CMakeFiles/brotlienc.dir/c/enc/block_splitter.c.o
[ 41%] Building C object CMakeFiles/brotlienc.dir/c/enc/brotli_bit_stream.c.o
[ 44%] Building C object CMakeFiles/brotlienc.dir/c/enc/cluster.c.o
[ 48%] Building C object CMakeFiles/brotlienc.dir/c/enc/command.c.o
[ 51%] Building C object CMakeFiles/brotlienc.dir/c/enc/compound_dictionary.c.o
[ 55%] Building C object CMakeFiles/brotlienc.dir/c/enc/compress_fragment.c.o
[ 58%] Building C object CMakeFiles/brotlienc.dir/c/enc/compress_fragment_two_pass.c.o
[ 62%] Building C object CMakeFiles/brotlienc.dir/c/enc/dictionary_hash.c.o
[ 65%] Building C object CMakeFiles/brotlienc.dir/c/enc/encode.c.o
[ 68%] Building C object CMakeFiles/brotlienc.dir/c/enc/encoder_dict.c.o
[ 72%] Building C object CMakeFiles/brotlienc.dir/c/enc/entropy_encode.c.o
[ 75%] Building C object CMakeFiles/brotlienc.dir/c/enc/fast_log.c.o
[ 79%] Building C object CMakeFiles/brotlienc.dir/c/enc/histogram.c.o
[ 82%] Building C object CMakeFiles/brotlienc.dir/c/enc/literal_cost.c.o
[ 86%] Building C object CMakeFiles/brotlienc.dir/c/enc/memory.c.o
[ 89%] Building C object CMakeFiles/brotlienc.dir/c/enc/metablock.c.o
[ 93%] Building C object CMakeFiles/brotlienc.dir/c/enc/static_dict.c.o
[ 96%] Building C object CMakeFiles/brotlienc.dir/c/enc/utf8_util.c.o
[100%] Linking C static library libbrotlienc.a
[100%] Built target brotlienc

[root@RPM out]# cd ../../../..
```

Поправим spec файл, чтобы Nginx собирался с необходимыми нам опциями: находим секцию с параметрами configure (до условий if) и добавляем указание на модуль (не забудьте указать завершающий обратный слэш):

```sh
[root@RPM ~]# sed -i '/configure \\/a \    --add-module=/root/ngx_brotli \\' /root/rpmbuild/SPECS/nginx.spec
```

Можно приступить к сборке RPM пакета:

```sh
[root@RPM ~]# cd ~/rpmbuild/SPECS/

[root@RPM SPECS]# rpmbuild -ba nginx.spec -D 'debug_package %{nil}'
Executing(%clean): /bin/sh -e /var/tmp/rpm-tmp.xLjl8Y
+ umask 022
+ cd /root/rpmbuild/BUILD
+ cd nginx-1.20.1
+ /usr/bin/rm -rf /root/rpmbuild/BUILDROOT/nginx-1.20.1-20.el9.alma.1.x86_64
+ RPM_EC=0
++ jobs -p
+ exit 0
```

Убедимся, что пакеты создались:

```sh
[root@RPM ~]# ll rpmbuild/RPMS/x86_64/
total 2000
-rw-r--r--. 1 root root   36229 Mar 26 11:45 nginx-1.20.1-20.el9.alma.1.x86_64.rpm
-rw-r--r--. 1 root root 1034673 Mar 26 11:45 nginx-core-1.20.1-20.el9.alma.1.x86_64.rpm
-rw-r--r--. 1 root root  759952 Mar 26 11:45 nginx-mod-devel-1.20.1-20.el9.alma.1.x86_64.rpm
-rw-r--r--. 1 root root   19352 Mar 26 11:45 nginx-mod-http-image-filter-1.20.1-20.el9.alma.1.x86_64.rpm
-rw-r--r--. 1 root root   30865 Mar 26 11:45 nginx-mod-http-perl-1.20.1-20.el9.alma.1.x86_64.rpm
-rw-r--r--. 1 root root   18157 Mar 26 11:45 nginx-mod-http-xslt-filter-1.20.1-20.el9.alma.1.x86_64.rpm
-rw-r--r--. 1 root root   53762 Mar 26 11:45 nginx-mod-mail-1.20.1-20.el9.alma.1.x86_64.rpm
-rw-r--r--. 1 root root   80435 Mar 26 11:45 nginx-mod-stream-1.20.1-20.el9.alma.1.x86_64.rpm
```

Копируем пакеты в общий каталог:

```sh
[root@RPM ~]# cp ~/rpmbuild/RPMS/noarch/* ~/rpmbuild/RPMS/x86_64/
[root@RPM ~]# cd ~/rpmbuild/RPMS/x86_64
[root@RPM x86_64]# ll
total 2020
-rw-r--r--. 1 root root   36229 Mar 26 11:45 nginx-1.20.1-20.el9.alma.1.x86_64.rpm
-rw-r--r--. 1 root root    7341 Mar 26 11:49 nginx-all-modules-1.20.1-20.el9.alma.1.noarch.rpm
-rw-r--r--. 1 root root 1034673 Mar 26 11:45 nginx-core-1.20.1-20.el9.alma.1.x86_64.rpm
-rw-r--r--. 1 root root    8424 Mar 26 11:49 nginx-filesystem-1.20.1-20.el9.alma.1.noarch.rpm
-rw-r--r--. 1 root root  759952 Mar 26 11:45 nginx-mod-devel-1.20.1-20.el9.alma.1.x86_64.rpm
-rw-r--r--. 1 root root   19352 Mar 26 11:45 nginx-mod-http-image-filter-1.20.1-20.el9.alma.1.x86_64.rpm
-rw-r--r--. 1 root root   30865 Mar 26 11:45 nginx-mod-http-perl-1.20.1-20.el9.alma.1.x86_64.rpm
-rw-r--r--. 1 root root   18157 Mar 26 11:45 nginx-mod-http-xslt-filter-1.20.1-20.el9.alma.1.x86_64.rpm
-rw-r--r--. 1 root root   53762 Mar 26 11:45 nginx-mod-mail-1.20.1-20.el9.alma.1.x86_64.rpm
-rw-r--r--. 1 root root   80435 Mar 26 11:45 nginx-mod-stream-1.20.1-20.el9.alma.1.x86_64.rpm
```

Теперь можно установить наш пакет и убедиться, что nginx работает:

```sh
[root@RPM x86_64]# yum localinstall *.rpm
[root@RPM x86_64]# systemctl start nginx
[root@RPM x86_64]# systemctl status nginx
● nginx.service - The nginx HTTP and reverse proxy server
     Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; preset: disabled)
     Active: active (running) since Wed 2025-03-26 11:52:12 UTC; 9s ago
    Process: 35123 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
    Process: 35126 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
    Process: 35142 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
   Main PID: 35150 (nginx)
      Tasks: 3 (limit: 5584)
     Memory: 10.9M
        CPU: 772ms
     CGroup: /system.slice/nginx.service
             ├─35150 "nginx: master process /usr/sbin/nginx"
             ├─35151 "nginx: worker process"
             └─35152 "nginx: worker process"

Mar 26 11:52:11 RPM systemd[1]: Starting The nginx HTTP and reverse proxy server...
Mar 26 11:52:12 RPM nginx[35126]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Mar 26 11:52:12 RPM nginx[35126]: nginx: configuration file /etc/nginx/nginx.conf test is successful
Mar 26 11:52:12 RPM systemd[1]: Started The nginx HTTP and reverse proxy server.
```

### Создать свой репозиторий и разместить там ранее собранный RPM

Приступим к созданию своего репозитория. Директория для статики у Nginx по умолчанию /usr/share/nginx/html. Создадим там каталог repo:

```sh
[root@RPM x86_64]# mkdir /usr/share/nginx/html/repo
```

Копируем туда наши собранные RPM-пакеты:

```sh
[root@RPM x86_64]# cp ~/rpmbuild/RPMS/x86_64/*.rpm /usr/share/nginx/html/repo/
[root@RPM x86_64]# ll /usr/share/nginx/html/repo/
total 2020
-rw-r--r--. 1 root root   36229 Mar 26 11:57 nginx-1.20.1-20.el9.alma.1.x86_64.rpm
-rw-r--r--. 1 root root    7341 Mar 26 11:57 nginx-all-modules-1.20.1-20.el9.alma.1.noarch.rpm
-rw-r--r--. 1 root root 1034673 Mar 26 11:57 nginx-core-1.20.1-20.el9.alma.1.x86_64.rpm
-rw-r--r--. 1 root root    8424 Mar 26 11:57 nginx-filesystem-1.20.1-20.el9.alma.1.noarch.rpm
-rw-r--r--. 1 root root  759952 Mar 26 11:57 nginx-mod-devel-1.20.1-20.el9.alma.1.x86_64.rpm
-rw-r--r--. 1 root root   19352 Mar 26 11:57 nginx-mod-http-image-filter-1.20.1-20.el9.alma.1.x86_64.rpm
-rw-r--r--. 1 root root   30865 Mar 26 11:57 nginx-mod-http-perl-1.20.1-20.el9.alma.1.x86_64.rpm
-rw-r--r--. 1 root root   18157 Mar 26 11:57 nginx-mod-http-xslt-filter-1.20.1-20.el9.alma.1.x86_64.rpm
-rw-r--r--. 1 root root   53762 Mar 26 11:57 nginx-mod-mail-1.20.1-20.el9.alma.1.x86_64.rpm
-rw-r--r--. 1 root root   80435 Mar 26 11:57 nginx-mod-stream-1.20.1-20.el9.alma.1.x86_64.rpm
```

Инициализируем репозиторий командой:

```sh
[root@RPM x86_64]# createrepo /usr/share/nginx/html/repo/
Directory walk started
Directory walk done - 10 packages
Temporary output repo path: /usr/share/nginx/html/repo/.repodata/
Preparing sqlite DBs
Pool started (with 5 workers)
Pool finished
```

Для прозрачности настроим в NGINX доступ к листингу каталога. В файле /etc/nginx/nginx.conf в блоке server добавим следующие директивы:

```sh
sed -i '/server {/a \         index index.html index.htm;' /etc/nginx/nginx.conf
sed -i '/server {/a \         autoindex on;' /etc/nginx/nginx.conf
```

Проверяем синтаксис и перезапускаем NGINX:

```sh
[root@RPM x86_64]# nginx -t
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful

[root@RPM x86_64]# nginx -s reload
```

Теперь ради интереса можно посмотреть в браузере или с помощью curl:

```sh
[root@RPM x86_64]# curl -a http://localhost/repo/
<html>
<head><title>Index of /repo/</title></head>
<body>
<h1>Index of /repo/</h1><hr><pre><a href="../">../</a>
<a href="repodata/">repodata/</a>                                          26-Mar-2025 11:58                   -
<a href="nginx-1.20.1-20.el9.alma.1.x86_64.rpm">nginx-1.20.1-20.el9.alma.1.x86_64.rpm</a>              26-Mar-2025 11:57               36229
<a href="nginx-all-modules-1.20.1-20.el9.alma.1.noarch.rpm">nginx-all-modules-1.20.1-20.el9.alma.1.noarch.rpm</a>  26-Mar-2025 11:57                7341
<a href="nginx-core-1.20.1-20.el9.alma.1.x86_64.rpm">nginx-core-1.20.1-20.el9.alma.1.x86_64.rpm</a>         26-Mar-2025 11:57             1034673
<a href="nginx-filesystem-1.20.1-20.el9.alma.1.noarch.rpm">nginx-filesystem-1.20.1-20.el9.alma.1.noarch.rpm</a>   26-Mar-2025 11:57                8424
<a href="nginx-mod-devel-1.20.1-20.el9.alma.1.x86_64.rpm">nginx-mod-devel-1.20.1-20.el9.alma.1.x86_64.rpm</a>    26-Mar-2025 11:57              759952
<a href="nginx-mod-http-image-filter-1.20.1-20.el9.alma.1.x86_64.rpm">nginx-mod-http-image-filter-1.20.1-20.el9.alma...&gt;</a> 26-Mar-2025 11:57               19352
<a href="nginx-mod-http-perl-1.20.1-20.el9.alma.1.x86_64.rpm">nginx-mod-http-perl-1.20.1-20.el9.alma.1.x86_64..&gt;</a> 26-Mar-2025 11:57               30865
<a href="nginx-mod-http-xslt-filter-1.20.1-20.el9.alma.1.x86_64.rpm">nginx-mod-http-xslt-filter-1.20.1-20.el9.alma.1..&gt;</a> 26-Mar-2025 11:57               18157
<a href="nginx-mod-mail-1.20.1-20.el9.alma.1.x86_64.rpm">nginx-mod-mail-1.20.1-20.el9.alma.1.x86_64.rpm</a>     26-Mar-2025 11:57               53762
<a href="nginx-mod-stream-1.20.1-20.el9.alma.1.x86_64.rpm">nginx-mod-stream-1.20.1-20.el9.alma.1.x86_64.rpm</a>   26-Mar-2025 11:57               80435
</pre><hr></body>
</html>
```

Все готово для того, чтобы протестировать репозиторий.

Добавим его в /etc/yum.repos.d:

```sh
[root@RPM x86_64]# cat >> /etc/yum.repos.d/otus.repo << EOF
[otus]
name=otus-linux
baseurl=http://localhost/repo
gpgcheck=0
enabled=1
EOF
```

Убедимся, что репозиторий подключился и посмотрим, что в нем есть:

```sh
[root@RPM x86_64]# yum repolist enabled | grep otus
otus                             otus-linux
```

Добавим пакет в наш репозиторий:

```sh
[root@RPM x86_64]# cd /usr/share/nginx/html/repo/
 
[root@RPM repo]# wget https://repo.percona.com/yum/percona-release-latest.noarch.rpm
--2025-03-26 12:12:55--  https://repo.percona.com/yum/percona-release-latest.noarch.rpm
Resolving repo.percona.com (repo.percona.com)... 49.12.125.205, 2a01:4f8:242:5792::2
Connecting to repo.percona.com (repo.percona.com)|49.12.125.205|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 28300 (28K) [application/x-redhat-package-manager]
Saving to: ‘percona-release-latest.noarch.rpm’

percona-release-latest.noarch.rpm             100%[=================================================================================================>]  27.64K  --.-KB/s    in 0.001s  

2025-03-26 12:12:56 (35.7 MB/s) - ‘percona-release-latest.noarch.rpm’ saved [28300/28300]

[root@RPM repo]# ll
total 2052
-rw-r--r--. 1 root root   36229 Mar 26 11:57 nginx-1.20.1-20.el9.alma.1.x86_64.rpm
-rw-r--r--. 1 root root    7341 Mar 26 11:57 nginx-all-modules-1.20.1-20.el9.alma.1.noarch.rpm
-rw-r--r--. 1 root root 1034673 Mar 26 11:57 nginx-core-1.20.1-20.el9.alma.1.x86_64.rpm
-rw-r--r--. 1 root root    8424 Mar 26 11:57 nginx-filesystem-1.20.1-20.el9.alma.1.noarch.rpm
-rw-r--r--. 1 root root  759952 Mar 26 11:57 nginx-mod-devel-1.20.1-20.el9.alma.1.x86_64.rpm
-rw-r--r--. 1 root root   19352 Mar 26 11:57 nginx-mod-http-image-filter-1.20.1-20.el9.alma.1.x86_64.rpm
-rw-r--r--. 1 root root   30865 Mar 26 11:57 nginx-mod-http-perl-1.20.1-20.el9.alma.1.x86_64.rpm
-rw-r--r--. 1 root root   18157 Mar 26 11:57 nginx-mod-http-xslt-filter-1.20.1-20.el9.alma.1.x86_64.rpm
-rw-r--r--. 1 root root   53762 Mar 26 11:57 nginx-mod-mail-1.20.1-20.el9.alma.1.x86_64.rpm
-rw-r--r--. 1 root root   80435 Mar 26 11:57 nginx-mod-stream-1.20.1-20.el9.alma.1.x86_64.rpm
-rw-r--r--. 1 root root   28300 Feb 12 14:02 percona-release-latest.noarch.rpm
drwxr-xr-x. 2 root root    4096 Mar 26 11:58 repodata
```

Обновим список пакетов в репозитории:

```sh
[root@RPM repo]# createrepo /usr/share/nginx/html/repo/
Directory walk started
Directory walk done - 11 packages
Temporary output repo path: /usr/share/nginx/html/repo/.repodata/
Preparing sqlite DBs
Pool started (with 5 workers)
Pool finished

[root@RPM repo]# yum makecache
AlmaLinux 9 - AppStream                                                                                                                                 6.6 kB/s | 4.2 kB     00:00    
AlmaLinux 9 - BaseOS                                                                                                                                    6.4 kB/s | 3.8 kB     00:00    
AlmaLinux 9 - Extras                                                                                                                                    5.4 kB/s | 3.3 kB     00:00    
otus-linux                                                                                                                                              483 kB/s | 7.2 kB     00:00    
Metadata cache created.

[root@RPM repo]# yum list | grep otus
percona-release.noarch                               1.0-30                              otus 
```

Так как Nginx у нас уже стоит, установим репозиторий percona-release:

```sh
[root@RPM repo]# yum install -y percona-release.noarch
Installed:
  percona-release-1.0-30.noarch                                                                                                                                                         

Complete!
```

Все прошло успешно. В случае, если вам потребуется обновить репозиторий (а это
делается при каждом добавлении файлов) снова, то выполните команду
createrepo /usr/share/nginx/html/repo/.

## Автоматизация сборки RPM и создание своего репозитория

Копируем Vagrantfile и каталог script в директорию на компьютере.

#### Открываем консоль, переходим в директорию с проектом и выполняем:

```sh
ivan@ivan-Otus:~/Desktop/Otus_HomeWork/Home work 6$ vagrant up

ivan@ivan-Otus:~/Desktop/Otus_HomeWork/Home work 6$ vagrant ssh

[vagrant@RPM ~]$ sudo -i

[root@RPM ~]# ./rpm.sh
```

Автоматически собирется RPM пакет nginx и создастся репозиторий. 

#### Выполним проверку:

Убедимся, что пакеты создались:

```sh
[root@RPM ~]# ll rpmbuild/RPMS/x86_64/
total 2020
-rw-r--r--. 1 root root   36231 Mar 27 11:00 nginx-1.20.1-20.el9.alma.1.x86_64.rpm
-rw-r--r--. 1 root root    7341 Mar 27 11:00 nginx-all-modules-1.20.1-20.el9.alma.1.noarch.rpm
-rw-r--r--. 1 root root 1034472 Mar 27 11:00 nginx-core-1.20.1-20.el9.alma.1.x86_64.rpm
-rw-r--r--. 1 root root    8428 Mar 27 11:00 nginx-filesystem-1.20.1-20.el9.alma.1.noarch.rpm
-rw-r--r--. 1 root root  759891 Mar 27 11:00 nginx-mod-devel-1.20.1-20.el9.alma.1.x86_64.rpm
-rw-r--r--. 1 root root   19353 Mar 27 11:00 nginx-mod-http-image-filter-1.20.1-20.el9.alma.1.x86_64.rpm
-rw-r--r--. 1 root root   30997 Mar 27 11:00 nginx-mod-http-perl-1.20.1-20.el9.alma.1.x86_64.rpm
-rw-r--r--. 1 root root   18158 Mar 27 11:00 nginx-mod-http-xslt-filter-1.20.1-20.el9.alma.1.x86_64.rpm
-rw-r--r--. 1 root root   53786 Mar 27 11:00 nginx-mod-mail-1.20.1-20.el9.alma.1.x86_64.rpm
-rw-r--r--. 1 root root   80435 Mar 27 11:00 nginx-mod-stream-1.20.1-20.el9.alma.1.x86_64.rpm
```

Проверка репозитория:

```sh
[root@RPM ~]# curl -a http://localhost/repo/
<html>
<head><title>Index of /repo/</title></head>
<body>
<h1>Index of /repo/</h1><hr><pre><a href="../">../</a>
<a href="repodata/">repodata/</a>                                          27-Mar-2025 11:00                   -
<a href="nginx-1.20.1-20.el9.alma.1.x86_64.rpm">nginx-1.20.1-20.el9.alma.1.x86_64.rpm</a>              27-Mar-2025 11:00               36231
<a href="nginx-all-modules-1.20.1-20.el9.alma.1.noarch.rpm">nginx-all-modules-1.20.1-20.el9.alma.1.noarch.rpm</a>  27-Mar-2025 11:00                7341
<a href="nginx-core-1.20.1-20.el9.alma.1.x86_64.rpm">nginx-core-1.20.1-20.el9.alma.1.x86_64.rpm</a>         27-Mar-2025 11:00             1034472
<a href="nginx-filesystem-1.20.1-20.el9.alma.1.noarch.rpm">nginx-filesystem-1.20.1-20.el9.alma.1.noarch.rpm</a>   27-Mar-2025 11:00                8428
<a href="nginx-mod-devel-1.20.1-20.el9.alma.1.x86_64.rpm">nginx-mod-devel-1.20.1-20.el9.alma.1.x86_64.rpm</a>    27-Mar-2025 11:00              759891
<a href="nginx-mod-http-image-filter-1.20.1-20.el9.alma.1.x86_64.rpm">nginx-mod-http-image-filter-1.20.1-20.el9.alma...&gt;</a> 27-Mar-2025 11:00               19353
<a href="nginx-mod-http-perl-1.20.1-20.el9.alma.1.x86_64.rpm">nginx-mod-http-perl-1.20.1-20.el9.alma.1.x86_64..&gt;</a> 27-Mar-2025 11:00               30997
<a href="nginx-mod-http-xslt-filter-1.20.1-20.el9.alma.1.x86_64.rpm">nginx-mod-http-xslt-filter-1.20.1-20.el9.alma.1..&gt;</a> 27-Mar-2025 11:00               18158
<a href="nginx-mod-mail-1.20.1-20.el9.alma.1.x86_64.rpm">nginx-mod-mail-1.20.1-20.el9.alma.1.x86_64.rpm</a>     27-Mar-2025 11:00               53786
<a href="nginx-mod-stream-1.20.1-20.el9.alma.1.x86_64.rpm">nginx-mod-stream-1.20.1-20.el9.alma.1.x86_64.rpm</a>   27-Mar-2025 11:00               80435
<a href="percona-release-latest.noarch.rpm">percona-release-latest.noarch.rpm</a>                  12-Feb-2025 14:02               28300
</pre><hr></body>
</html>
```

Убедимся, что репозиторий подключился и посмотрим, что в нем есть:

```sh
[root@RPM ~]# yum repolist enabled | grep otus
otus                          otus-linux
```

Список пакетов в репозитории:

```sh
[root@RPM ~]# yum list | grep otus
percona-release.noarch                               1.0-30                              @otus   
```