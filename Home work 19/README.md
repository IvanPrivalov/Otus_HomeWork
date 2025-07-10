## Vagrant-стенд c сетевой лабораторией
____

### Цель домашнего задания:

Научится менять базовые сетевые настройки в Linux-based системах.

### Описание домашнего задания:

1. Скачать и развернуть Vagrant-стенд https://github.com/erlong15/otus-linux/tree/network
2. Построить следующую сетевую архитектуру:
Сеть office1
- 192.168.2.0/26      - dev
- 192.168.2.64/26     - test servers
- 192.168.2.128/26    - managers
- 192.168.2.192/26    - office hardware

Сеть office2
- 192.168.1.0/25      - dev
- 192.168.1.128/26    - test servers
- 192.168.1.192/26    - office hardware

Сеть central
- 192.168.0.0/28     - directors
- 192.168.0.32/28    - office hardware
- 192.168.0.64/26    - wifi

#### Итого должны получиться следующие сервера:

- inetRouter
- centralRouter
- office1Router
- office2Router
- centralServer
- office1Server
- office2Server

Задание состоит из 2-х частей: теоретической и практической.

#### В теоретической части требуется: 

- Найти свободные подсети
- Посчитать количество узлов в каждой подсети, включая свободные
- Указать Broadcast-адрес для каждой подсети
- Проверить, нет ли ошибок при разбиении

#### В практической части требуется: 

- Соединить офисы в сеть согласно логической схеме и настроить роутинг
- Интернет-трафик со всех серверов должен ходить через inetRouter
- Все сервера должны видеть друг друга (должен проходить ping)
- У всех новых серверов отключить дефолт на NAT (eth0), который vagrant поднимает для связи
- Добавить дополнительные сетевые интерфейсы, если потребуется

## Выполнение ДЗ
____

### Central network

| subnet | network address | min address | max address | total hosts | broadcast |
|:----:|:----:|:----:|:----:|:----:|:----:|
| directors | 192.168.0.0/28 | 192.168.0.1 | 192.168.0.14 | 14 | 192.168.0.15 |
| office hardware | 192.168.0.32/28 | 192.168.0.33 | 192.168.0.46 | 14 | 192.168.0.47 |
| wifi | 192.168.0.64/26 | 192.168.0.65 | 192.168.0.126 | 62 | 192.168.0.127 |
| Free network | 192.168.0.16/28 | 192.168.0.17 | 192.168.0.30 | 14 | 192.168.0.31 |
| Free network | 192.168.0.48/28 | 192.168.0.49 | 192.168.0.62 | 14 | 192.168.0.63 |
| Free network | 192.168.0.128/25 | 192.168.0.129 | 192.168.0.254 | 126 | 192.168.0.255 |

### Office 1 network
| subnet | network address | min address | max address | total hosts | broadcast |
|:----:|:----:|:----:|:----:|:----:|:----:|
| dev | 192.168.2.0/26 | 192.168.2.1 | 192.168.2.62 | 62 | 192.168.2.63 |
| test servers | 192.168.2.64/26 | 192.168.2.65 | 192.168.2.126 | 62 | 192.168.2.127 |
| managers | 192.168.2.128/26 | 192.168.2.129 | 192.168.2.190 | 62 | 192.168.2.191 |
| office hardware | 192.168.2.192/26 | 192.168.2.193 | 192.168.2.254 | 62 | 192.168.2.255 |

### Office 2 network
| subnet | network address | min address | max address | total hosts | broadcast |
|:----:|:----:|:----:|:----:|:----:|:----:|
| dev | 192.168.1.0/25 | 192.168.1.1 | 192.168.1.126 | 126 | 192.168.2.127 |
| test servers | 192.168.1.128/26 | 192.168.1.129 | 192.168.1.190 | 62 | 192.168.2.191 |
| office hardware | 192.168.1.192/26 | 192.168.1.193 | 192.168.1.254 | 62 | 192.168.2.255 |

Установка traceroute: 

```sh
sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*
yum install -y traceroute
```

Пример проверки выхода в Интернет через сервер inetRouter c хоста office1Server и office2Server:

```sh
[root@office1Server ~]# traceroute 8.8.8.8
traceroute to 8.8.8.8 (8.8.8.8), 30 hops max, 60 byte packets
 1  gateway (192.168.2.1)  2.056 ms  0.493 ms  0.715 ms
 2  RT (192.168.0.1)  2.790 ms  2.751 ms  2.112 ms
 3  192.168.255.1 (192.168.255.1)  3.246 ms  11.118 ms  10.026 ms
 4  * * *
 5  * * *
 6  * * *
 7  * * *
 8  92.242.30.61 (92.242.30.61)  14.124 ms  14.134 ms  17.340 ms
 9  5.140.215.238 (5.140.215.238)  14.815 ms  12.771 ms  12.509 ms
10  5.140.215.237 (5.140.215.237)  14.724 ms  12.690 ms  15.086 ms
11  * * *
12  * * *
13  dns.google (8.8.8.8)  53.225 ms  56.219 ms  52.580 ms
```

```sh
[root@office2Server ~]# traceroute 8.8.8.8
traceroute to 8.8.8.8 (8.8.8.8), 30 hops max, 60 byte packets
 1  gateway (192.168.1.1)  1.981 ms  1.124 ms  3.135 ms
 2  RT (192.168.0.1)  5.936 ms  4.908 ms  4.838 ms
 3  192.168.255.1 (192.168.255.1)  11.799 ms  12.722 ms  11.889 ms
 4  * * *
 5  * * *
 6  * * *
 7  * * *
 8  92.242.30.61 (92.242.30.61)  37.036 ms  35.185 ms  26.686 ms
 9  5.140.215.238 (5.140.215.238)  26.652 ms  25.758 ms  16.997 ms
10  5.140.215.237 (5.140.215.237)  17.681 ms  17.378 ms  16.624 ms
11  * * *
12  72.14.197.6 (72.14.197.6)  71.034 ms * *
13  dns.google (8.8.8.8)  63.484 ms  66.478 ms  66.156 ms
```

Проверка выхода в Интернет через сервер inetRouter c хоста centralServer:

```sh
[root@centralServer ~]# traceroute 8.8.8.8
traceroute to 8.8.8.8 (8.8.8.8), 30 hops max, 60 byte packets
 1  RT (192.168.0.1)  0.846 ms  0.549 ms  0.730 ms
 2  192.168.255.1 (192.168.255.1)  1.264 ms  1.228 ms  1.437 ms
 3  * * *
 4  * * *
 5  * * *
 6  be3-4010.sr32-27.ekb.ru.mirasystem.net (92.242.30.62)  7.796 ms  9.850 ms  9.765 ms
 7  92.242.30.61 (92.242.30.61)  9.056 ms  9.007 ms  8.469 ms
 8  5.140.215.238 (5.140.215.238)  16.150 ms  14.029 ms  11.208 ms
 9  5.140.215.237 (5.140.215.237)  9.098 ms  10.931 ms  9.882 ms
10  * * *
11  * * *
12  dns.google (8.8.8.8)  53.890 ms  60.306 ms  50.115 ms
```

Проверка доступности между серверами:

```sh
[root@office1Server ~]# ping 192.168.0.2
PING 192.168.0.2 (192.168.0.2) 56(84) bytes of data.
64 bytes from 192.168.0.2: icmp_seq=1 ttl=63 time=2.09 ms
64 bytes from 192.168.0.2: icmp_seq=2 ttl=63 time=1.72 ms
64 bytes from 192.168.0.2: icmp_seq=3 ttl=63 time=1.40 ms
64 bytes from 192.168.0.2: icmp_seq=4 ttl=63 time=1.51 ms
^C
--- 192.168.0.2 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3006ms
rtt min/avg/max/mdev = 1.407/1.684/2.092/0.265 ms

[vagrant@office2Server ~]$ ping 192.168.0.2
PING 192.168.0.2 (192.168.0.2) 56(84) bytes of data.
64 bytes from 192.168.0.2: icmp_seq=1 ttl=63 time=8.07 ms
64 bytes from 192.168.0.2: icmp_seq=2 ttl=63 time=1.60 ms
64 bytes from 192.168.0.2: icmp_seq=3 ttl=63 time=1.42 ms
^C
--- 192.168.0.2 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2005ms
rtt min/avg/max/mdev = 1.422/3.701/8.076/3.094 ms

[root@centralServer ~]# ping 192.168.1.2
PING 192.168.1.2 (192.168.1.2) 56(84) bytes of data.
64 bytes from 192.168.1.2: icmp_seq=1 ttl=63 time=1.98 ms
64 bytes from 192.168.1.2: icmp_seq=2 ttl=63 time=4.06 ms
64 bytes from 192.168.1.2: icmp_seq=3 ttl=63 time=2.07 ms
64 bytes from 192.168.1.2: icmp_seq=4 ttl=63 time=0.958 ms
^C
--- 192.168.1.2 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3011ms
rtt min/avg/max/mdev = 0.958/2.270/4.063/1.124 ms

[root@centralServer ~]# ping 192.168.2.2
PING 192.168.2.2 (192.168.2.2) 56(84) bytes of data.
64 bytes from 192.168.2.2: icmp_seq=1 ttl=63 time=2.20 ms
64 bytes from 192.168.2.2: icmp_seq=2 ttl=63 time=1.88 ms
64 bytes from 192.168.2.2: icmp_seq=3 ttl=63 time=2.16 ms
64 bytes from 192.168.2.2: icmp_seq=4 ttl=63 time=1.89 ms
^C
--- 192.168.2.2 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3007ms
rtt min/avg/max/mdev = 1.886/2.039/2.208/0.155 ms
```