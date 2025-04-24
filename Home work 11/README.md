## Практика с SELinux.
____

### Описание домашнего задания:

1. Запустить Nginx на нестандартном порту 3-мя разными способами:
- переключатели setsebool;
- добавление нестандартного порта в имеющийся тип;
- формирование и установка модуля SELinux.
К сдаче:
- README с описанием каждого решения (скриншоты и демонстрация приветствуются). 

2. Обеспечить работоспособность приложения при включенном selinux.
- развернуть приложенный стенд https://github.com/Nickmob/vagrant_selinux_dns_problems; 
- выяснить причину неработоспособности механизма обновления зоны (см. README);
- предложить решение (или решения) для данной проблемы;
- выбрать одно из решений для реализации, предварительно обосновав выбор;
- реализовать выбранное решение и продемонстрировать его работоспособность.

### Запустить Nginx на нестандартном порту 3-мя разными способами.

Копируем Vagrantfile в дирректорию и запускаем vagrant up.

Проверим, что в ОС отключен файервол:

```sh
[root@SELinux vagrant]# systemctl status firewalld
Unit firewalld.service could not be found.
```

Проверим, что конфигурация nginx настроена без ошибок:

```sh
[root@SELinux vagrant]# nginx -t
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

Проверим режим работы SELinux:

```sh
[root@SELinux vagrant]# getenforce
Enforcing
```

Должен отображаться режим Enforcing. Данный режим означает, что SELinux будет блокировать запрещенную активность.

#### Разрешим в SELinux работу nginx на порту TCP 4881 c помощью переключателей setsebool

Находим в логах (/var/log/audit/audit.log) информацию о блокировании порта

```sh
[root@SELinux vagrant]# cat /var/log/audit/audit.log | grep 4881
type=AVC msg=audit(1745393946.794:713): avc:  denied  { name_bind } for  pid=5804 comm="nginx" src=4881 scontext=system_u:system_r:httpd_t:s0 tcontext=system_u:object_r:unreserved_port_t:s0 tclass=tcp_socket permissive=0
```

Копируем время, в которое был записан этот лог, и, с помощью утилиты audit2why смотрим grep 1745393946.794:713 /var/log/audit/audit.log | audit2why

```sh
[root@SELinux vagrant]# grep 1745393946.794:713 /var/log/audit/audit.log | audit2why
type=AVC msg=audit(1745393946.794:713): avc:  denied  { name_bind } for  pid=5804 comm="nginx" src=4881 scontext=system_u:system_r:httpd_t:s0 tcontext=system_u:object_r:unreserved_port_t:s0 tclass=tcp_socket permissive=0

	Was caused by:
	The boolean nis_enabled was set incorrectly. 
	Description:
	Allow nis to enabled

	Allow access by executing:
	# setsebool -P nis_enabled 1
```

Утилита audit2why покажет почему трафик блокируется. Исходя из вывода утилиты, мы видим, что нам нужно поменять параметр nis_enabled. 

Включим параметр nis_enabled и перезапустим nginx:

```sh
[root@SELinux vagrant]# setsebool -P nis_enabled on
[root@SELinux vagrant]# systemctl restart nginx
[root@SELinux vagrant]# systemctl status nginx
● nginx.service - The nginx HTTP and reverse proxy server
     Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; preset: disabled)
     Active: active (running) since Wed 2025-04-23 10:19:40 UTC; 9s ago
    Process: 6232 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
    Process: 6233 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
    Process: 6234 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
   Main PID: 6235 (nginx)
      Tasks: 3 (limit: 12026)
     Memory: 2.9M
        CPU: 475ms
     CGroup: /system.slice/nginx.service
             ├─6235 "nginx: master process /usr/sbin/nginx"
             ├─6236 "nginx: worker process"
             └─6237 "nginx: worker process"

Apr 23 10:19:40 SELinux systemd[1]: Starting The nginx HTTP and reverse proxy server...
Apr 23 10:19:40 SELinux nginx[6233]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Apr 23 10:19:40 SELinux nginx[6233]: nginx: configuration file /etc/nginx/nginx.conf test is successful
Apr 23 10:19:40 SELinux systemd[1]: Started The nginx HTTP and reverse proxy server.
```

Проверим:

```sh
[root@SELinux vagrant]# ss -ltnp
State       Recv-Q       Send-Q             Local Address:Port             Peer Address:Port      Process                                                                               
LISTEN      0            128                      0.0.0.0:22                    0.0.0.0:*          users:(("sshd",pid=695,fd=3))                                                        
LISTEN      0            4096                     0.0.0.0:111                   0.0.0.0:*          users:(("rpcbind",pid=602,fd=4),("systemd",pid=1,fd=102))                            
LISTEN      0            511                      0.0.0.0:4881                  0.0.0.0:*          users:(("nginx",pid=6237,fd=6),("nginx",pid=6236,fd=6),("nginx",pid=6235,fd=6))      
LISTEN      0            128                         [::]:22                       [::]:*          users:(("sshd",pid=695,fd=4))                                                        
LISTEN      0            4096                        [::]:111                      [::]:*          users:(("rpcbind",pid=602,fd=6),("systemd",pid=1,fd=104))                            
LISTEN      0            511                         [::]:4881                     [::]:*          users:(("nginx",pid=6237,fd=7),("nginx",pid=6236,fd=7),("nginx",pid=6235,fd=7)) 
```

Также можно проверить работу nginx из браузера. Заходим в любой браузер на хосте и переходим по адресу http://127.0.0.1:4881

![image 1](https://github.com/IvanPrivalov/Otus_HomeWork/blob/main/Home%20work%2011/screens/Screenshot_01.png)

Проверить статус параметра можно с помощью команды: ```getsebool -a | grep nis_enabled```

```sh
[root@SELinux vagrant]# getsebool -a | grep nis_enabled
nis_enabled --> on
```

Вернём запрет работы nginx на порту 4881 обратно. Для этого отключим nis_enabled: setsebool -P nis_enabled off
После отключения nis_enabled служба nginx снова не запустится.

```sh
[root@SELinux vagrant]# setsebool -P nis_enabled off
[root@SELinux vagrant]# systemctl restart nginx
Job for nginx.service failed because the control process exited with error code.
See "systemctl status nginx.service" and "journalctl -xeu nginx.service" for details.
[root@SELinux vagrant]# systemctl status nginx
× nginx.service - The nginx HTTP and reverse proxy server
     Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; preset: disabled)
     Active: failed (Result: exit-code) since Wed 2025-04-23 10:31:33 UTC; 4s ago
   Duration: 11min 51.750s
    Process: 6255 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
    Process: 6256 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=1/FAILURE)
        CPU: 228ms

Apr 23 10:31:32 SELinux systemd[1]: Starting The nginx HTTP and reverse proxy server...
Apr 23 10:31:33 SELinux nginx[6256]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Apr 23 10:31:33 SELinux nginx[6256]: nginx: [emerg] bind() to 0.0.0.0:4881 failed (13: Permission denied)
Apr 23 10:31:33 SELinux nginx[6256]: nginx: configuration file /etc/nginx/nginx.conf test failed
Apr 23 10:31:33 SELinux systemd[1]: nginx.service: Control process exited, code=exited, status=1/FAILURE
Apr 23 10:31:33 SELinux systemd[1]: nginx.service: Failed with result 'exit-code'.
Apr 23 10:31:33 SELinux systemd[1]: Failed to start The nginx HTTP and reverse proxy server.
[root@SELinux vagrant]# ss -ltnp
State          Recv-Q         Send-Q                  Local Address:Port                   Peer Address:Port         Process                                                            
LISTEN         0              128                           0.0.0.0:22                          0.0.0.0:*             users:(("sshd",pid=695,fd=3))                                     
LISTEN         0              4096                          0.0.0.0:111                         0.0.0.0:*             users:(("rpcbind",pid=602,fd=4),("systemd",pid=1,fd=102))         
LISTEN         0              128                              [::]:22                             [::]:*             users:(("sshd",pid=695,fd=4))                                     
LISTEN         0              4096                             [::]:111                            [::]:*             users:(("rpcbind",pid=602,fd=6),("systemd",pid=1,fd=104))  
```

#### Разрешим в SELinux работу nginx на порту TCP 4881 c помощью добавления нестандартного порта в имеющийся тип:

Поиск имеющегося типа, для http трафика: ```semanage port -l | grep http```

```sh
[root@SELinux vagrant]# semanage port -l | grep http
http_cache_port_t              tcp      8080, 8118, 8123, 10001-10010
http_cache_port_t              udp      3130
http_port_t                    tcp      80, 81, 443, 488, 8008, 8009, 8443, 9000
pegasus_http_port_t            tcp      5988
pegasus_https_port_t           tcp      5989
```

Добавим порт в тип http_port_t: ```semanage port -a -t http_port_t -p tcp 4881```

```sh
[root@SELinux vagrant]# semanage port -a -t http_port_t -p tcp 4881
[root@SELinux vagrant]# semanage port -l | grep  http_port_t
http_port_t                    tcp      4881, 80, 81, 443, 488, 8008, 8009, 8443, 9000
pegasus_http_port_t            tcp      5988
```

Теперь перезапускаем службу nginx и проверим её работу: ```systemctl restart nginx```

```sh
[root@SELinux vagrant]# systemctl restart nginx
[root@SELinux vagrant]# systemctl status nginx
● nginx.service - The nginx HTTP and reverse proxy server
     Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; preset: disabled)
     Active: active (running) since Wed 2025-04-23 10:41:50 UTC; 3s ago
    Process: 6286 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
    Process: 6287 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
    Process: 6288 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
   Main PID: 6289 (nginx)
      Tasks: 3 (limit: 12026)
     Memory: 2.9M
        CPU: 328ms
     CGroup: /system.slice/nginx.service
             ├─6289 "nginx: master process /usr/sbin/nginx"
             ├─6290 "nginx: worker process"
             └─6291 "nginx: worker process"

Apr 23 10:41:50 SELinux systemd[1]: Starting The nginx HTTP and reverse proxy server...
Apr 23 10:41:50 SELinux nginx[6287]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Apr 23 10:41:50 SELinux nginx[6287]: nginx: configuration file /etc/nginx/nginx.conf test is successful
Apr 23 10:41:50 SELinux systemd[1]: Started The nginx HTTP and reverse proxy server.
[root@SELinux vagrant]# ss -ltnp
State       Recv-Q       Send-Q             Local Address:Port             Peer Address:Port      Process                                                                               
LISTEN      0            128                      0.0.0.0:22                    0.0.0.0:*          users:(("sshd",pid=695,fd=3))                                                        
LISTEN      0            4096                     0.0.0.0:111                   0.0.0.0:*          users:(("rpcbind",pid=602,fd=4),("systemd",pid=1,fd=102))                            
LISTEN      0            511                      0.0.0.0:4881                  0.0.0.0:*          users:(("nginx",pid=6291,fd=6),("nginx",pid=6290,fd=6),("nginx",pid=6289,fd=6))      
LISTEN      0            128                         [::]:22                       [::]:*          users:(("sshd",pid=695,fd=4))                                                        
LISTEN      0            4096                        [::]:111                      [::]:*          users:(("rpcbind",pid=602,fd=6),("systemd",pid=1,fd=104))                            
LISTEN      0            511                         [::]:4881                     [::]:*          users:(("nginx",pid=6291,fd=7),("nginx",pid=6290,fd=7),("nginx",pid=6289,fd=7)) 
```

Также можно проверить работу nginx из браузера. Заходим в любой браузер на хосте и переходим по адресу http://127.0.0.1:4881

![image 1](https://github.com/IvanPrivalov/Otus_HomeWork/blob/main/Home%20work%2011/screens/Screenshot_01.png)

Удалить нестандартный порт из имеющегося типа можно с помощью команды: ```semanage port -d -t http_port_t -p tcp 4881```

```sh
[root@SELinux vagrant]# semanage port -d -t http_port_t -p tcp 4881
[root@SELinux vagrant]# semanage port -l | grep  http_port_t
http_port_t                    tcp      80, 81, 443, 488, 8008, 8009, 8443, 9000
pegasus_http_port_t            tcp      5988
[root@SELinux vagrant]# systemctl restart nginx
Job for nginx.service failed because the control process exited with error code.
See "systemctl status nginx.service" and "journalctl -xeu nginx.service" for details.
[root@SELinux vagrant]# systemctl status nginx
× nginx.service - The nginx HTTP and reverse proxy server
     Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; preset: disabled)
     Active: failed (Result: exit-code) since Wed 2025-04-23 10:44:44 UTC; 3s ago
   Duration: 2min 52.973s
    Process: 6307 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
    Process: 6308 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=1/FAILURE)
        CPU: 216ms

Apr 23 10:44:43 SELinux systemd[1]: Starting The nginx HTTP and reverse proxy server...
Apr 23 10:44:44 SELinux nginx[6308]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Apr 23 10:44:44 SELinux nginx[6308]: nginx: [emerg] bind() to 0.0.0.0:4881 failed (13: Permission denied)
Apr 23 10:44:44 SELinux nginx[6308]: nginx: configuration file /etc/nginx/nginx.conf test failed
Apr 23 10:44:44 SELinux systemd[1]: nginx.service: Control process exited, code=exited, status=1/FAILURE
Apr 23 10:44:44 SELinux systemd[1]: nginx.service: Failed with result 'exit-code'.
Apr 23 10:44:44 SELinux systemd[1]: Failed to start The nginx HTTP and reverse proxy server.
```

#### Разрешим в SELinux работу nginx на порту TCP 4881 c помощью формирования и установки модуля SELinux:

Попробуем снова запустить Nginx: ```systemctl start nginx```

```sh
[root@SELinux vagrant]# systemctl start nginx
Job for nginx.service failed because the control process exited with error code.
See "systemctl status nginx.service" and "journalctl -xeu nginx.service" for details.
```

Nginx не запустится, так как SELinux продолжает его блокировать. Посмотрим логи SELinux, которые относятся к Nginx:

```sh
[root@SELinux vagrant]# grep nginx /var/log/audit/audit.log
...
type=SYSCALL msg=audit(1745412719.701:802): arch=c000003e syscall=49 success=no exit=-13 a0=6 a1=55e64e178ef0 a2=10 a3=7fff5715f0a0 items=0 ppid=1 pid=6375 auid=4294967295 uid=0 gid=0 euid=0 suid=0 fsuid=0 egid=0 sgid=0 fsgid=0 tty=(none) ses=4294967295 comm="nginx" exe="/usr/sbin/nginx" subj=system_u:system_r:httpd_t:s0 key=(null)ARCH=x86_64 SYSCALL=bind AUID="unset" UID="root" GID="root" EUID="root" SUID="root" FSUID="root" EGID="root" SGID="root" FSGID="root"
type=SERVICE_START msg=audit(1745412719.738:803): pid=1 uid=0 auid=4294967295 ses=4294967295 subj=system_u:system_r:init_t:s0 msg='unit=nginx comm="systemd" exe="/usr/lib/systemd/systemd" hostname=? addr=? terminal=? res=failed'UID="root" AUID="unset"
```

Воспользуемся утилитой audit2allow для того, чтобы на основе логов SELinux сделать модуль, разрешающий работу nginx на нестандартном порту: 
```grep nginx /var/log/audit/audit.log | audit2allow -M nginx```

```sh
[root@SELinux vagrant]# grep nginx /var/log/audit/audit.log | audit2allow -M nginx
******************** IMPORTANT ***********************
To make this policy package active, execute:

semodule -i nginx.pp
```

Audit2allow сформировал модуль, и сообщил нам команду, с помощью которой можно применить данный модуль: ```semodule -i nginx.pp```

```sh
[root@SELinux vagrant]# semodule -i nginx.pp
```

Попробуем снова запустить nginx: ```systemctl start nginx```

```sh
[root@SELinux vagrant]# systemctl start nginx
[root@SELinux vagrant]# systemctl status nginx
● nginx.service - The nginx HTTP and reverse proxy server
     Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; preset: disabled)
     Active: active (running) since Wed 2025-04-23 12:56:56 UTC; 2s ago
    Process: 6405 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
    Process: 6406 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
    Process: 6407 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
   Main PID: 6408 (nginx)
      Tasks: 3 (limit: 12026)
     Memory: 2.9M
        CPU: 414ms
     CGroup: /system.slice/nginx.service
             ├─6408 "nginx: master process /usr/sbin/nginx"
             ├─6409 "nginx: worker process"
             └─6410 "nginx: worker process"

Apr 23 12:56:55 SELinux systemd[1]: Starting The nginx HTTP and reverse proxy server...
Apr 23 12:56:55 SELinux nginx[6406]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Apr 23 12:56:55 SELinux nginx[6406]: nginx: configuration file /etc/nginx/nginx.conf test is successful
Apr 23 12:56:56 SELinux systemd[1]: Started The nginx HTTP and reverse proxy server.
[root@SELinux vagrant]# ss -ltnp
State       Recv-Q       Send-Q             Local Address:Port             Peer Address:Port      Process                                                                               
LISTEN      0            128                      0.0.0.0:22                    0.0.0.0:*          users:(("sshd",pid=695,fd=3))                                                        
LISTEN      0            4096                     0.0.0.0:111                   0.0.0.0:*          users:(("rpcbind",pid=602,fd=4),("systemd",pid=1,fd=102))                            
LISTEN      0            511                      0.0.0.0:4881                  0.0.0.0:*          users:(("nginx",pid=6410,fd=6),("nginx",pid=6409,fd=6),("nginx",pid=6408,fd=6))      
LISTEN      0            128                         [::]:22                       [::]:*          users:(("sshd",pid=695,fd=4))                                                        
LISTEN      0            4096                        [::]:111                      [::]:*          users:(("rpcbind",pid=602,fd=6),("systemd",pid=1,fd=104))                            
LISTEN      0            511                         [::]:4881                     [::]:*          users:(("nginx",pid=6410,fd=7),("nginx",pid=6409,fd=7),("nginx",pid=6408,fd=7)) 
```

После добавления модуля nginx запустился без ошибок. При использовании модуля изменения сохранятся после перезагрузки. 
Просмотр всех установленных модулей: ```semodule -l```

Для удаления модуля воспользуемся командой: ```semodule -r nginx```

```sh
[root@SELinux vagrant]# semodule -r nginx
libsemanage.semanage_direct_remove_key: Removing last nginx module (no other nginx module exists at another priority).
[root@SELinux vagrant]# systemctl restart nginx
Job for nginx.service failed because the control process exited with error code.
See "systemctl status nginx.service" and "journalctl -xeu nginx.service" for details.
[root@SELinux vagrant]# systemctl status nginx
× nginx.service - The nginx HTTP and reverse proxy server
     Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; preset: disabled)
     Active: failed (Result: exit-code) since Wed 2025-04-23 12:59:40 UTC; 6s ago
   Duration: 2min 44.220s
    Process: 6425 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
    Process: 6426 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=1/FAILURE)
        CPU: 227ms

Apr 23 12:59:40 SELinux systemd[1]: Starting The nginx HTTP and reverse proxy server...
Apr 23 12:59:40 SELinux nginx[6426]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Apr 23 12:59:40 SELinux nginx[6426]: nginx: [emerg] bind() to 0.0.0.0:4881 failed (13: Permission denied)
Apr 23 12:59:40 SELinux nginx[6426]: nginx: configuration file /etc/nginx/nginx.conf test failed
Apr 23 12:59:40 SELinux systemd[1]: nginx.service: Control process exited, code=exited, status=1/FAILURE
Apr 23 12:59:40 SELinux systemd[1]: nginx.service: Failed with result 'exit-code'.
Apr 23 12:59:40 SELinux systemd[1]: Failed to start The nginx HTTP and reverse proxy server.
[root@SELinux vagrant]# ss -ltnp
State          Recv-Q         Send-Q                  Local Address:Port                   Peer Address:Port         Process                                                            
LISTEN         0              128                           0.0.0.0:22                          0.0.0.0:*             users:(("sshd",pid=695,fd=3))                                     
LISTEN         0              4096                          0.0.0.0:111                         0.0.0.0:*             users:(("rpcbind",pid=602,fd=4),("systemd",pid=1,fd=102))         
LISTEN         0              128                              [::]:22                             [::]:*             users:(("sshd",pid=695,fd=4))                                     
LISTEN         0              4096                             [::]:111                            [::]:*             users:(("rpcbind",pid=602,fd=6),("systemd",pid=1,fd=104)) 
```

### Обеспечение работоспособности приложения при включенном SELinux

Выполним клонирование репозитория:
```git clone https://github.com/Nickmob/vagrant_selinux_dns_problems.git```

```sh
ivan@ivan-Otus:~/Desktop/Otus_HomeWork/Home work 11$ git clone https://github.com/Nickmob/vagrant_selinux_dns_problems.git
Cloning into 'vagrant_selinux_dns_problems'...
remote: Enumerating objects: 32, done.
remote: Counting objects: 100% (32/32), done.
remote: Compressing objects: 100% (21/21), done.
remote: Total 32 (delta 9), reused 29 (delta 9), pack-reused 0 (from 0)
Receiving objects: 100% (32/32), 7.23 KiB | 7.23 MiB/s, done.
Resolving deltas: 100% (9/9), done.
```

Перейдём в каталог со стендом: ```cd vagrant_selinux_dns_problems```

Развернём 2 ВМ с помощью vagrant: ```vagrant up```

После того, как стенд развернется, проверим ВМ с помощью команды: ```vagrant status```

```sh
ivan@ivan-Otus:~/Desktop/Otus_HomeWork/Home work 11/vagrant_selinux_dns_problems$ vagrant status
Current machine states:

ns01                      running (virtualbox)
client                    running (virtualbox)

This environment represents multiple VMs. The VMs are all listed
above with their current state. For more information about a specific
VM, run `vagrant status NAME`.
```

Подключимся к клиенту: ```vagrant ssh client```

Попробуем внести изменения в зону: ```nsupdate -k /etc/named.zonetransfer.key```

```sh
[vagrant@client ~]$ nsupdate -k /etc/named.zonetransfer.key
> server 192.168.50.10
> zone ddns.lab
> update add www.ddns.lab. 60 A 192.168.50.15
> send
update failed: SERVFAIL
> quit
```

Изменения внести не получилось. Давайте посмотрим логи SELinux, чтобы понять в чём может быть проблема.
Для этого воспользуемся утилитой audit2why:

[vagrant@client ~]$ sudo -i
[root@client ~]# cat /var/log/audit/audit.log | audit2why
[root@client ~]#

Тут мы видим, что на клиенте отсутствуют ошибки. 
Не закрывая сессию на клиенте, подключимся к серверу ns01 и проверим логи SELinux:

```sh
ivan@ivan-Otus:~/Desktop/Otus_HomeWork/Home work 11/vagrant_selinux_dns_problems$ vagrant ssh ns01
Last login: Thu Apr 24 09:48:16 2025 from 10.0.2.2
[vagrant@ns01 ~]$ sudo -i
[root@ns01 ~]# cat /var/log/audit/audit.log | audit2why
type=AVC msg=audit(1745488603.466:1682): avc:  denied  { write } for  pid=7036 comm="isc-net-0001" name="dynamic" dev="sda4" ino=33851567 scontext=system_u:system_r:named_t:s0 tcontext=unconfined_u:object_r:named_conf_t:s0 tclass=dir permissive=0

	Was caused by:
		Missing type enforcement (TE) allow rule.

		You can use audit2allow to generate a loadable module to allow this access.
```

В логах мы видим, что ошибка в контексте безопасности. Целевой контекст named_conf_t.
Для сравнения посмотрим существующую зону (localhost) и её контекст:

```sh
[root@ns01 ~]# ls -alZ /var/named/named.localhost
-rw-r-----. 1 root named system_u:object_r:named_zone_t:s0 152 Feb 19 16:04 /var/named/named.localhost
```

У наших конфигов в /etc/named вместо типа named_zone_t используется тип named_conf_t.
Проверим данную проблему в каталоге /etc/named:

```sh
[root@ns01 ~]# ls -laZ /etc/named
total 28
drw-rwx---.  3 root named system_u:object_r:named_conf_t:s0      121 Apr 24 09:47 .
drwxr-xr-x. 87 root root  system_u:object_r:etc_t:s0            8192 Apr 24 09:48 ..
drw-rwx---.  2 root named unconfined_u:object_r:named_conf_t:s0   56 Apr 24 09:47 dynamic
-rw-rw----.  1 root named system_u:object_r:named_conf_t:s0      784 Apr 24 09:47 named.50.168.192.rev
-rw-rw----.  1 root named system_u:object_r:named_conf_t:s0      610 Apr 24 09:47 named.dns.lab
-rw-rw----.  1 root named system_u:object_r:named_conf_t:s0      609 Apr 24 09:47 named.dns.lab.view1
-rw-rw----.  1 root named system_u:object_r:named_conf_t:s0      657 Apr 24 09:47 named.newdns.lab
```

Тут мы также видим, что контекст безопасности неправильный. Проблема заключается в том, что конфигурационные файлы лежат в другом каталоге. Посмотреть в каком каталоги должны лежать, файлы, чтобы на них распространялись правильные политики SELinux можно с помощью команды: ```sudo semanage fcontext -l | grep named```

```sh
[root@ns01 ~]# semanage fcontext -l | grep named
/etc/rndc.*                                        regular file       system_u:object_r:named_conf_t:s0
/var/named(/.*)?                                   all files          system_u:object_r:named_zone_t:s0
```

Изменим тип контекста безопасности для каталога /etc/named: ```sudo chcon -R -t named_zone_t /etc/named```

```sh
[root@ns01 ~]# chcon -R -t named_zone_t /etc/named
[root@ns01 ~]# ls -laZ /etc/named
total 28
drw-rwx---.  3 root named system_u:object_r:named_zone_t:s0      121 Apr 24 09:47 .
drwxr-xr-x. 87 root root  system_u:object_r:etc_t:s0            8192 Apr 24 09:48 ..
drw-rwx---.  2 root named unconfined_u:object_r:named_zone_t:s0   56 Apr 24 09:47 dynamic
-rw-rw----.  1 root named system_u:object_r:named_zone_t:s0      784 Apr 24 09:47 named.50.168.192.rev
-rw-rw----.  1 root named system_u:object_r:named_zone_t:s0      610 Apr 24 09:47 named.dns.lab
-rw-rw----.  1 root named system_u:object_r:named_zone_t:s0      609 Apr 24 09:47 named.dns.lab.view1
-rw-rw----.  1 root named system_u:object_r:named_zone_t:s0      657 Apr 24 09:47 named.newdns.lab
```

Попробуем снова внести изменения с клиента: 

```sh
[root@client ~]# nsupdate -k /etc/named.zonetransfer.key
> server 192.168.50.10
> zone ddns.lab
> update add www.ddns.lab. 60 A 192.168.50.15
> send
> quit

[root@client ~]# dig www.ddns.lab

; <<>> DiG 9.16.23-RH <<>> www.ddns.lab
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 9498
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1232
; COOKIE: 068564983e74b47f01000000680a0e217bdcbe40bc389aaa (good)
;; QUESTION SECTION:
;www.ddns.lab.			IN	A

;; ANSWER SECTION:
www.ddns.lab.		60	IN	A	192.168.50.15

;; Query time: 1 msec
;; SERVER: 192.168.50.10#53(192.168.50.10)
;; WHEN: Thu Apr 24 10:10:41 UTC 2025
;; MSG SIZE  rcvd: 85
```

Видим, что изменения применились. Попробуем перезагрузить хосты и ещё раз сделать запрос с помощью dig:

```sh
[vagrant@client ~]$ dig www.ddns.lab

; <<>> DiG 9.16.23-RH <<>> www.ddns.lab
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 39110
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1232
; COOKIE: 6345603bb611af3a01000000680a0e74e1143bd9e5db1f36 (good)
;; QUESTION SECTION:
;www.ddns.lab.			IN	A

;; ANSWER SECTION:
www.ddns.lab.		60	IN	A	192.168.50.15

;; Query time: 1 msec
;; SERVER: 192.168.50.10#53(192.168.50.10)
;; WHEN: Thu Apr 24 10:12:04 UTC 2025
;; MSG SIZE  rcvd: 85
```

Всё правильно. После перезагрузки настройки сохранились. 
Важно, что мы не добавили новые правила в политику для назначения этого контекста в каталоге. Значит, что при перемаркировке файлов контекст вернётся на тот, который прописан в файле политики.
Для того, чтобы вернуть правила обратно, можно ввести команду: ```restorecon -v -R /etc/named```

```sh
[root@ns01 ~]# restorecon -v -R /etc/named
Relabeled /etc/named from system_u:object_r:named_zone_t:s0 to system_u:object_r:named_conf_t:s0
Relabeled /etc/named/named.dns.lab from system_u:object_r:named_zone_t:s0 to system_u:object_r:named_conf_t:s0
Relabeled /etc/named/named.dns.lab.view1 from system_u:object_r:named_zone_t:s0 to system_u:object_r:named_conf_t:s0
Relabeled /etc/named/dynamic from unconfined_u:object_r:named_zone_t:s0 to unconfined_u:object_r:named_conf_t:s0
Relabeled /etc/named/dynamic/named.ddns.lab from system_u:object_r:named_zone_t:s0 to system_u:object_r:named_conf_t:s0
Relabeled /etc/named/dynamic/named.ddns.lab.view1 from system_u:object_r:named_zone_t:s0 to system_u:object_r:named_conf_t:s0
Relabeled /etc/named/dynamic/named.ddns.lab.view1.jnl from system_u:object_r:named_zone_t:s0 to system_u:object_r:named_conf_t:s0
Relabeled /etc/named/named.newdns.lab from system_u:object_r:named_zone_t:s0 to system_u:object_r:named_conf_t:s0
Relabeled /etc/named/named.50.168.192.rev from system_u:object_r:named_zone_t:s0 to system_u:object_r:named_conf_t:s0
```
