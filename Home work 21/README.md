## Сценарии iptables
____

### Цель домашнего задания:

Написать сценарии iptables.

### Описание домашнего задания:

1. реализовать knocking port
 centralRouter может попасть на ssh inetrRouter через knock скрипт пример в материалах
2. добавить inetRouter2, который виден(маршрутизируется (host-only тип сети для виртуалки)) с хоста или форвардится порт через локалхост
3. запустить nginx на centralServer
4. пробросить 80й порт на inetRouter2 8080
5. дефолт в инет оставить через inetRouter

* реализовать проход на 80й порт без маскарадинга

## Выполнение ДЗ

Копируем файлы в каталог и запускаем Vagrantfile:

```shell
vagrant up
```

### 1. Реализовать knocking port. centralRouter может попасть на ssh inetrRouter через knock скрипт

Правила iptables на сервере inetRouter будут выглядеть следующим образом:

```shell
[root@inetRouter ~]# iptables-save 
*filter
:INPUT DROP [0:0]
:FORWARD DROP [0:0]
:OUTPUT ACCEPT [6:472]
:SSH-INPUT - [0:0]
:SSH-INPUTTWO - [0:0]
:TRAFFIC - [0:0]
-A INPUT -j TRAFFIC
-A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
-A FORWARD -i eth1 -j ACCEPT
-A SSH-INPUT -m recent --set --name SSH1 --mask 255.255.255.255 --rsource -j DROP
-A SSH-INPUTTWO -m recent --set --name SSH2 --mask 255.255.255.255 --rsource -j DROP
-A TRAFFIC -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
-A TRAFFIC -p tcp -m conntrack --ctstate NEW -m tcp --dport 22 -m recent --rcheck --seconds 30 --name SSH2 --mask 255.255.255.255 --rsource -j ACCEPT
-A TRAFFIC -p tcp -m conntrack --ctstate NEW -m tcp -m recent --remove --name SSH2 --mask 255.255.255.255 --rsource -j DROP
-A TRAFFIC -p tcp -m conntrack --ctstate NEW -m tcp --dport 9992 -m recent --rcheck --name SSH1 --mask 255.255.255.255 --rsource -j SSH-INPUTTWO
-A TRAFFIC -p tcp -m conntrack --ctstate NEW -m tcp -m recent --remove --name SSH1 --mask 255.255.255.255 --rsource -j DROP
-A TRAFFIC -p tcp -m conntrack --ctstate NEW -m tcp --dport 7772 -m recent --rcheck --name SSH0 --mask 255.255.255.255 --rsource -j SSH-INPUT
-A TRAFFIC -p tcp -m conntrack --ctstate NEW -m tcp -m recent --remove --name SSH0 --mask 255.255.255.255 --rsource -j DROP
-A TRAFFIC -p tcp -m conntrack --ctstate NEW -m tcp --dport 8882 -m recent --set --name SSH0 --mask 255.255.255.255 --rsource -j DROP
-A TRAFFIC -j DROP
COMMIT
*nat
:PREROUTING ACCEPT [507:39436]
:INPUT ACCEPT [6:812]
:OUTPUT ACCEPT [396:30152]
:POSTROUTING ACCEPT [1:35]
-A POSTROUTING -o eth0 -j MASQUERADE
COMMIT
```

Для автоматизации процедуры Port knocking создадим скрипт knock.sh на centralRouter:

```shell
[root@centralRouter ~]# cat /opt/knock.sh
#!/bin/bash
HOST=$1
shift
for PORT in "$@"
do
	nmap -Pn --max-retries 0 -p $PORT $HOST
done
[root@centralRouter ~]# chmod +x /opt/knock.sh
```

Проверка:

```shell
[root@centralRouter ~]# /opt/knock.sh 10.1.1.1 8882 7772 9992

Starting Nmap 6.40 ( http://nmap.org ) at 2025-07-16 13:14 UTC
Warning: 10.1.1.1 giving up on port because retransmission cap hit (0).
Nmap scan report for 10.1.1.1
Host is up (0.00075s latency).
PORT     STATE    SERVICE
8882/tcp filtered unknown
MAC Address: 08:00:27:D3:F1:67 (Cadmus Computer Systems)

Nmap done: 1 IP address (1 host up) scanned in 1.13 seconds

Starting Nmap 6.40 ( http://nmap.org ) at 2025-07-16 13:14 UTC
Warning: 10.1.1.1 giving up on port because retransmission cap hit (0).
Nmap scan report for 10.1.1.1
Host is up (0.0010s latency).
PORT     STATE    SERVICE
7772/tcp filtered unknown
MAC Address: 08:00:27:D3:F1:67 (Cadmus Computer Systems)

Nmap done: 1 IP address (1 host up) scanned in 0.50 seconds

Starting Nmap 6.40 ( http://nmap.org ) at 2025-07-16 13:14 UTC
Warning: 10.1.1.1 giving up on port because retransmission cap hit (0).
Nmap scan report for 10.1.1.1
Host is up (0.00072s latency).
PORT     STATE    SERVICE
9992/tcp filtered issc
MAC Address: 08:00:27:D3:F1:67 (Cadmus Computer Systems)

Nmap done: 1 IP address (1 host up) scanned in 0.48 seconds

[root@centralRouter ~]# ssh user1@10.1.1.1
The authenticity of host '10.1.1.1 (10.1.1.1)' can't be established.
ECDSA key fingerprint is SHA256:FlvghgHaBaqo3B0qS2LPpoi8o+rw5z/ykCHm+Ae2qko.
ECDSA key fingerprint is MD5:e2:96:4d:36:4e:9d:20:96:ec:ac:02:58:e7:6f:1c:36.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added '10.1.1.1' (ECDSA) to the list of known hosts.
user1@10.1.1.1's password: 
[user1@inetRouter ~]$ hostname
inetRouter
```

### 2. добавить inetRouter2, который виден(маршрутизируется (host-only тип сети для виртуалки)) с хоста или форвардится порт через локалхост
### 3. запустить nginx на centralServer
### 4. пробросить 80й порт на inetRouter2 8080
### 5. дефолт в инет оставить через inetRouter

Установим и запустим nginx на centralServer:

```shell
[root@centralServer ~]# yum install -y epel-release
[root@centralServer ~]# yum install -y nginx
[root@centralServer ~]# systemctl enable --now nginx
```

Установим iptables-services:

```shell
[root@inetRouter2 ~]# yum install -y iptables-services
[root@inetRouter2 ~]# systemctl enable --now iptables
```

Добавим следующее правило:

```shell
[root@inetRouter2 ~]# iptables -t nat -A PREROUTING -i eth2 -p tcp --dport 8080 -j DNAT --to 192.168.0.40:80
[root@inetRouter2 ~]# iptables -F
```

При загрузке сервера iptables.service будет считывать содержимое файла /etc/sysconfig/iptables. Для сохранения в этот файл настроенного выше правила nat воспользуемся утилитой iptables-save:

```shell
[root@inetRouter2 ~]# service iptables save
iptables: Saving firewall rules to /etc/sysconfig/iptables:[  OK  ]
```

Проверим:

![image 1](https://github.com/IvanPrivalov/Otus_HomeWork/blob/main/Home%20work%2021/screens/Screenshot_01.png)

При этом дефолтом в инет является 10.1.1.1 (inetRouter):

```shell
[root@centralServer ~]# traceroute ya.ru
traceroute to ya.ru (87.250.250.242), 30 hops max, 60 byte packets
 1  gateway (192.168.0.33)  0.765 ms  0.692 ms  0.431 ms
 2  10.1.1.1 (10.1.1.1)  1.593 ms  1.147 ms  0.869 ms
 3  * * *
 4  * * *
 5  * * *
 6  192.168.0.1 (192.168.0.1)  15.859 ms  4.261 ms  5.377 ms
 7  90.150.237.1 (90.150.237.1)  15.587 ms  15.300 ms  15.032 ms
 8  79.133.87.230 (79.133.87.230)  7.239 ms  13.709 ms  9.074 ms
 9  79.133.87.171 (79.133.87.171)  10.048 ms  8.103 ms 79.133.87.169 (79.133.87.169)  10.775 ms
10  87.226.183.89 (87.226.183.89)  32.800 ms 87.226.181.89 (87.226.181.89)  42.855 ms 87.226.183.89 (87.226.183.89)  35.145 ms
11  5.143.250.94 (5.143.250.94)  34.269 ms  33.842 ms  33.098 ms
12  * ya.ru (87.250.250.242)  43.881 ms  39.566 ms
```

### Проверка задания

1. Выполнить vagrant up.
2. Зайти на centralRouter с помощью vagrant ssh centralRouter. Выполнить /opt/knock.sh 10.1.1.1 8882 7772 9992, затем ssh user1@10.1.1.1 и ввести пароль user. Тем самым попадем на сервер inetRouter.
3. В консоли или браузере на локалхосте зайти по адресу http://192.168.12.12:8080.
