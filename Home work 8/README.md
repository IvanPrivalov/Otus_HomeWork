## Инициализация системы. Systemd.
____

### Задание:

1. Написать service, который будет раз в 30 секунд мониторить лог на предмет наличия ключевого слова (файл лога и ключевое слово должны задаваться в /etc/default).
2. Установить spawn-fcgi и создать unit-файл (spawn-fcgi.sevice) с помощью переделки init-скрипта (https://gist.github.com/cea2k/1318020).
3. Доработать unit-файл Nginx (nginx.service) для запуска нескольких инстансов сервера с разными конфигурационными файлами одновременно.

### Написать service, который будет раз в 30 секунд мониторить лог на предмет наличия ключевого слова.

#### Создаём файл с конфигурацией для сервиса в директории /etc/default - из неё сервис будет брать необходимые переменные.

```sh
root@Systemd:~# vi /etc/default/watchlog
root@Systemd:~# cat /etc/default/watchlog
# Configuration file for my watchlog service
# Place it to /etc/default

# File and word in that file that we will be monit
WORD="ALERT"
LOG=/var/log/watchlog.log
```

Создаем /var/log/watchlog.log и пишем туда строки на своё усмотрение, плюс ключевое слово ‘ALERT’

```sh
root@Systemd:~# touch /var/log/watchlog.log
root@Systemd:~# ll /var/log/
total 380
drwxrwxr-x   8 root      syslog            4096 Apr  2 12:16 ./
drwxr-xr-x  13 root      root              4096 May 10  2023 ../
drwxr-xr-x   2 root      root              4096 May 10  2023 apt/
-rw-r-----   1 syslog    adm               7657 Apr  2 12:17 auth.log
-rw-rw----   1 root      utmp                 0 May 10  2023 btmp
-rw-r-----   1 root      adm               4825 Apr  2 12:13 cloud-init-output.log
-rw-r-----   1 syslog    adm             101057 Apr  2 12:13 cloud-init.log
drwxr-xr-x   2 root      root              4096 Feb 10  2023 dist-upgrade/
-rw-r-----   1 root      adm              45214 Apr  2 12:13 dmesg
-rw-r--r--   1 root      root              2678 May 10  2023 dpkg.log
drwxr-sr-x+  3 root      systemd-journal   4096 Apr  2 12:12 journal/
-rw-r-----   1 syslog    adm              56447 Apr  2 12:13 kern.log
drwxr-xr-x   2 landscape landscape         4096 Mar 30  2022 landscape/
-rw-rw-r--   1 root      utmp            292584 Apr  2 12:14 lastlog
drwx------   2 root      root              4096 Apr  2 12:12 private/
-rw-r-----   1 syslog    adm             114744 Apr  2 12:17 syslog
drwxr-x---   2 root      adm               4096 Apr  2 12:13 unattended-upgrades/
-rw-r--r--   1 root      root                 0 Apr  2 12:16 watchlog.log
-rw-rw-r--   1 root      utmp              2688 Apr  2 12:14 wtmp
```

#### Создадим скрипт:

```sh
root@Systemd:~# vi /opt/watchlog.sh
root@Systemd:~# cat /opt/watchlog.sh
#!/bin/bash

WORD=$1
LOG=$2
DATE=`date`

if grep $WORD $LOG &> /dev/null
then
logger "$DATE: I found word, Master!"
else
exit 0
fi
```

Добавим права на запуск файла:

```sh
root@Systemd:~# chmod +x /opt/watchlog.sh
```

#### Создадим юнит для сервиса:

```sh
root@Systemd:~# vi /etc/systemd/system/watchlog.service
root@Systemd:~# cat /etc/systemd/system/watchlog.service
[Unit]
Description=My watchlog service

[Service]
Type=oneshot
EnvironmentFile=/etc/default/watchlog
ExecStart=/opt/watchlog.sh $WORD $LOG
```

#### Создадим юнит для таймера:

```sh
root@Systemd:~# vi /etc/systemd/system/watchlog.timer
root@Systemd:~# cat /etc/systemd/system/watchlog.timer
[Unit]
Description=Run watchlog script every 30 second

[Timer]
# Run every 30 second
OnUnitActiveSec=30
Unit=watchlog.service

[Install]
WantedBy=multi-user.target
```

Затем достаточно только запустить timer:

```sh
root@Systemd:~# systemctl start watchlog.
watchlog.service  watchlog.timer    
root@Systemd:~# systemctl start watchlog.timer 
root@Systemd:~# systemctl status watchlog.timer 
● watchlog.timer - Run watchlog script every 30 second
     Loaded: loaded (/etc/systemd/system/watchlog.timer; disabled; vendor preset: enabled)
     Active: active (elapsed) since Wed 2025-04-02 12:24:26 UTC; 6s ago
    Trigger: n/a
   Triggers: ● watchlog.service

Apr 02 12:24:26 Systemd systemd[1]: Started Run watchlog script every 30 second.
```

И убедиться в результате:

```sh
root@Systemd:~# echo "ALERT" >> /var/log/watchlog.log
root@Systemd:~# systemctl status watchlog.timer
● watchlog.timer - Run watchlog script every 30 second
     Loaded: loaded (/etc/systemd/system/watchlog.timer; disabled; vendor preset: enabled)
     Active: active (running) since Wed 2025-04-02 12:28:35 UTC; 4min 29s ago
    Trigger: n/a
   Triggers: ● watchlog.service

Apr 02 12:28:35 Systemd systemd[1]: Started Run watchlog script every 30 second.
root@Systemd:~# tail -n 1000 /var/log/syslog | grep word
Apr  2 12:13:15 ubuntu-jammy kernel: [   15.288711] systemd[1]: Started Forward Password Requests to Wall Directory Watch.
Apr  2 12:33:04 ubuntu-jammy root: Wed Apr  2 12:33:04 UTC 2025: I found word, Master!
root@Systemd:~# echo "ALERT" >> /var/log/watchlog.log
root@Systemd:~# tail -n 1000 /var/log/syslog | grep word
Apr  2 12:13:15 ubuntu-jammy kernel: [   15.288711] systemd[1]: Started Forward Password Requests to Wall Directory Watch.
Apr  2 12:33:04 ubuntu-jammy root: Wed Apr  2 12:33:04 UTC 2025: I found word, Master!
Apr  2 12:33:49 ubuntu-jammy root: Wed Apr  2 12:33:49 UTC 2025: I found word, Master!
Apr  2 12:34:39 ubuntu-jammy root: Wed Apr  2 12:34:39 UTC 2025: I found word, Master!
```

### Установить spawn-fcgi и создать unit-файл (spawn-fcgi.sevice) с помощью переделки init-скрипта

Устанавливаем spawn-fcgi и необходимые для него пакеты:

```sh
root@Systemd:~# apt install spawn-fcgi php php-cgi php-cli apache2 libapache2-mod-fcgid -y
```

Создам файл с настройками для будущего сервиса в файле /etc/spawn-fcgi/fcgi.conf:

```sh
root@Systemd:~# vi /etc/spawn-fcgi/fcgi.conf
root@Systemd:~# cat /etc/spawn-fcgi/fcgi.conf
# You must set some working options before the "spawn-fcgi" service will work.
# If SOCKET points to a file, then this file is cleaned up by the init script.
#
# See spawn-fcgi(1) for all possible options.
#
# Example :
SOCKET=/var/run/php-fcgi.sock
OPTIONS="-u www-data -g www-data -s $SOCKET -S -M 0600 -C 32 -F 1 -- /usr/bin/php-cgi"
```

А сам юнит-файл будет примерно следующего вида:

```sh
root@Systemd:~# vi /etc/systemd/system/spawn-fcgi.service
root@Systemd:~# cat /etc/systemd/system/spawn-fcgi.service
[Unit]
Description=Spawn-fcgi startup service by Otus
After=network.target

[Service]
Type=simple
PIDFile=/var/run/spawn-fcgi.pid
EnvironmentFile=/etc/spawn-fcgi/fcgi.conf
ExecStart=/usr/bin/spawn-fcgi -n $OPTIONS
KillMode=process

[Install]
WantedBy=multi-user.target
```

Убеждаемся, что все успешно работает:

```sh
root@Systemd:~# systemctl start spawn-fcgi
root@Systemd:~# systemctl status spawn-fcgi
● spawn-fcgi.service - Spawn-fcgi startup service by Otus
     Loaded: loaded (/etc/systemd/system/spawn-fcgi.service; disabled; vendor preset: enabled)
     Active: active (running) since Wed 2025-04-02 13:02:58 UTC; 5s ago
   Main PID: 12506 (php-cgi)
● spawn-fcgi.service - Spawn-fcgi startup service by Otus
     Loaded: loaded (/etc/systemd/system/spawn-fcgi.service; disabled; vendor preset: enabled)
     Active: active (running) since Wed 2025-04-02 13:02:58 UTC; 5s ago
   Main PID: 12506 (php-cgi)
      Tasks: 33 (limit: 1115)
     Memory: 20.0M
        CPU: 376ms
     CGroup: /system.slice/spawn-fcgi.service
             ├─12506 /usr/bin/php-cgi
             ├─12507 /usr/bin/php-cgi
             ├─12508 /usr/bin/php-cgi
             ├─12509 /usr/bin/php-cgi
             ├─12510 /usr/bin/php-cgi
             ├─12511 /usr/bin/php-cgi
             ├─12512 /usr/bin/php-cgi
             ├─12513 /usr/bin/php-cgi
             ├─12514 /usr/bin/php-cgi
             ├─12515 /usr/bin/php-cgi
             ├─12516 /usr/bin/php-cgi
             ├─12517 /usr/bin/php-cgi
             ├─12518 /usr/bin/php-cgi
             ├─12519 /usr/bin/php-cgi
             ├─12520 /usr/bin/php-cgi
             ├─12521 /usr/bin/php-cgi
             ├─12522 /usr/bin/php-cgi
             ├─12523 /usr/bin/php-cgi
             ├─12524 /usr/bin/php-cgi
             ├─12525 /usr/bin/php-cgi
             ├─12526 /usr/bin/php-cgi
             ├─12527 /usr/bin/php-cgi
             ├─12528 /usr/bin/php-cgi
             ├─12529 /usr/bin/php-cgi
             ├─12530 /usr/bin/php-cgi
             ├─12531 /usr/bin/php-cgi
             ├─12532 /usr/bin/php-cgi
             ├─12533 /usr/bin/php-cgi
             ├─12534 /usr/bin/php-cgi
             ├─12535 /usr/bin/php-cgi
             ├─12536 /usr/bin/php-cgi
             ├─12537 /usr/bin/php-cgi
             └─12538 /usr/bin/php-cgi

Apr 02 13:02:58 Systemd systemd[1]: Started Spawn-fcgi startup service by Otus.
```

### Доработать unit-файл Nginx (nginx.service) для запуска нескольких инстансов сервера с разными конфигурационными файлами одновременно

Установим Nginx из стандартного репозитория:

```sh
root@Systemd:~# apt install nginx -y
```

Для запуска нескольких экземпляров сервиса модифицируем исходный service для использования различной конфигурации, а также PID-файлов. Для этого создадим новый Unit для работы с шаблонами (/etc/systemd/system/nginx@.service):

```sh
root@Systemd:~# vi /etc/systemd/system/nginx@.service
root@Systemd:~# cat /etc/systemd/system/nginx@.service
# Stop dance for nginx
# =======================
#
# ExecStop sends SIGSTOP (graceful stop) to the nginx process.
# If, after 5s (--retry QUIT/5) nginx is still running, systemd takes control
# and sends SIGTERM (fast shutdown) to the main process.
# After another 5s (TimeoutStopSec=5), and if nginx is alive, systemd sends
# SIGKILL to all the remaining processes in the process group (KillMode=mixed).
#
# nginx signals reference doc:
# http://nginx.org/en/docs/control.html
#
[Unit]
Description=A high performance web server and a reverse proxy server
Documentation=man:nginx(8)
After=network.target nss-lookup.target

[Service]
Type=forking
PIDFile=/run/nginx-%I.pid
ExecStartPre=/usr/sbin/nginx -t -c /etc/nginx/nginx-%I.conf -q -g 'daemon on; master_process on;'
ExecStart=/usr/sbin/nginx -c /etc/nginx/nginx-%I.conf -g 'daemon on; master_process on;'
ExecReload=/usr/sbin/nginx -c /etc/nginx/nginx-%I.conf -g 'daemon on; master_process on;' -s reload
ExecStop=-/sbin/start-stop-daemon --quiet --stop --retry QUIT/5 --pidfile /run/nginx-%I.pid
TimeoutStopSec=5
KillMode=mixed

[Install]
WantedBy=multi-user.target
```

Далее необходимо создать два файла конфигурации (/etc/nginx/nginx-first.conf, /etc/nginx/nginx-second.conf). Их можно сформировать из стандартного конфига /etc/nginx/nginx.conf, с модификацией путей до PID-файлов и разделением по портам:

```sh
root@Systemd:~# cat /etc/nginx/nginx-first.conf
user www-data;
worker_processes auto;
pid /run/nginx-first.pid;
include /etc/nginx/modules-enabled/*.conf;

events {
	worker_connections 768;
	# multi_accept on;
}

http {

	##
	# Basic Settings
	##

	sendfile on;
	tcp_nopush on;
	types_hash_max_size 2048;
	# server_tokens off;

	# server_names_hash_bucket_size 64;
	# server_name_in_redirect off;
	include /etc/nginx/mime.types;
	default_type application/octet-stream;

	##
	# SSL Settings
	##

	ssl_protocols TLSv1 TLSv1.1 TLSv1.2 TLSv1.3; # Dropping SSLv3, ref: POODLE
	ssl_prefer_server_ciphers on;

	##
	# Logging Settings
	##

	access_log /var/log/nginx/access.log;
	error_log /var/log/nginx/error.log;

	##
	# Gzip Settings
	##

	gzip on;

	# gzip_vary on;
	# gzip_proxied any;
	# gzip_comp_level 6;
	# gzip_buffers 16 8k;
	# gzip_http_version 1.1;
	# gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;

	##
	# Virtual Host Configs
	##
	server {
                listen 9001;
                }

	include /etc/nginx/conf.d/*.conf;
	#include /etc/nginx/sites-enabled/*;
}
```

```sh
root@Systemd:~# cat /etc/nginx/nginx-second.conf
user www-data;
worker_processes auto;
pid /run/nginx-second.pid;
include /etc/nginx/modules-enabled/*.conf;

events {
	worker_connections 768;
	# multi_accept on;
}

http {

	##
	# Basic Settings
	##

	sendfile on;
	tcp_nopush on;
	types_hash_max_size 2048;
	# server_tokens off;

	# server_names_hash_bucket_size 64;
	# server_name_in_redirect off;

	include /etc/nginx/mime.types;
	default_type application/octet-stream;

	##
	# SSL Settings
	##

	ssl_protocols TLSv1 TLSv1.1 TLSv1.2 TLSv1.3; # Dropping SSLv3, ref: POODLE
	ssl_prefer_server_ciphers on;

	##
	# Logging Settings
	##

	access_log /var/log/nginx/access.log;
	error_log /var/log/nginx/error.log;

	##
	# Gzip Settings
	##

	gzip on;

	# gzip_vary on;
	# gzip_proxied any;
	# gzip_comp_level 6;
	# gzip_buffers 16 8k;
	# gzip_http_version 1.1;
	# gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;

	##
	# Virtual Host Configs
	##
	server {
		listen 9002;
		}
	include /etc/nginx/conf.d/*.conf;
	#include /etc/nginx/sites-enabled/*;
}
```

#### Проверим работу:

```sh
root@Systemd:~# systemctl start nginx@first
root@Systemd:~# systemctl start nginx@second
root@Systemd:~# systemctl status nginx@second
● nginx@second.service - A high performance web server and a reverse proxy server
     Loaded: loaded (/etc/systemd/system/nginx@.service; disabled; vendor preset: enabled)
     Active: active (running) since Thu 2025-04-03 06:59:58 UTC; 12s ago
       Docs: man:nginx(8)
    Process: 2294 ExecStartPre=/usr/sbin/nginx -t -c /etc/nginx/nginx-second.conf -q -g daemon on; master_process on; (code=exited, status=0/SUCCESS)
    Process: 2295 ExecStart=/usr/sbin/nginx -c /etc/nginx/nginx-second.conf -g daemon on; master_process on; (code=exited, status=0/SUCCESS)
   Main PID: 2296 (nginx)
      Tasks: 3 (limit: 1115)
     Memory: 3.2M
        CPU: 337ms
     CGroup: /system.slice/system-nginx.slice/nginx@second.service
             ├─2296 "nginx: master process /usr/sbin/nginx -c /etc/nginx/nginx-second.conf -g daemon on; master_process on;"
             ├─2297 "nginx: worker process" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" ">
             └─2298 "nginx: worker process" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" ">

Apr 03 06:59:58 Systemd systemd[1]: Starting A high performance web server and a reverse proxy server...
Apr 03 06:59:58 Systemd systemd[1]: Started A high performance web server and a reverse proxy server.

root@Systemd:~# ss -tnulp | grep nginx
tcp   LISTEN 0      511             0.0.0.0:9001      0.0.0.0:*    users:(("nginx",pid=2275,fd=6),("nginx",pid=2274,fd=6),("nginx",pid=2273,fd=6))                                                                                                       
tcp   LISTEN 0      511             0.0.0.0:9002      0.0.0.0:*    users:(("nginx",pid=2298,fd=6),("nginx",pid=2297,fd=6),("nginx",pid=2296,fd=6)) 

root@Systemd:~# ps afx | grep nginx
   2310 pts/1    S+     0:00                          \_ grep --color=auto nginx
   2273 ?        Ss     0:00 nginx: master process /usr/sbin/nginx -c /etc/nginx/nginx-first.conf -g daemon on; master_process on;
   2274 ?        S      0:00  \_ nginx: worker process
   2275 ?        S      0:00  \_ nginx: worker process
   2296 ?        Ss     0:00 nginx: master process /usr/sbin/nginx -c /etc/nginx/nginx-second.conf -g daemon on; master_process on;
   2297 ?        S      0:00  \_ nginx: worker process
   2298 ?        S      0:00  \_ nginx: worker process
```