# Vagrant-стенд c OSPF
____

## Цель домашнего задания

Создать домашнюю сетевую лабораторию. Научится настраивать протокол OSPF в Linux-based системах.

## Задание

Задание

- Поднять три виртуалки
- Объединить их разными vlan
- Поднять OSPF между машинами на базе Quagga
- Изобразить ассиметричный роутинг
- Сделать один из линков "дорогим", но чтобы при этом роутинг был симметричным

## Выполнение ДЗ

Копируем файлы в каталог и запускаем Vagrantfile:

```shell
vagrant up
```

## Проверим, что по протоколу OSPF прилетели все нужные нам маршруты:

### Router r1:

```shell
[root@r1 ~]# ip r
default via 10.0.2.2 dev eth0 proto dhcp metric 100 
10.0.0.0/24 dev eth1 proto kernel scope link src 10.0.0.1 metric 101 
10.0.2.0/24 dev eth0 proto kernel scope link src 10.0.2.15 metric 100 
10.10.0.0/24 dev eth2 proto kernel scope link src 10.10.0.1 metric 102 
10.10.10.0/24 dev eth3 proto kernel scope link src 10.10.10.11 metric 103 
10.20.0.0/24 proto zebra metric 20 
	nexthop via 10.0.0.2 dev eth1 weight 1 
	nexthop via 10.10.0.2 dev eth2 weight 1 
127.0.0.2 via 10.0.0.2 dev eth1 proto zebra metric 20 
127.0.0.3 via 10.10.0.2 dev eth2 proto zebra metric 20 
```

### Router r2:

```shell
[root@r2 ~]# ip r
default via 10.0.0.1 dev eth1 proto zebra metric 10 
10.0.0.0/24 dev eth1 proto kernel scope link src 10.0.0.2 metric 101 
10.0.2.0/24 dev eth0 proto kernel scope link src 10.0.2.15 metric 100 
10.10.0.0/24 proto zebra metric 20 
	nexthop via 10.0.0.1 dev eth1 weight 1 
	nexthop via 10.20.0.1 dev eth2 weight 1 
10.10.10.0/24 dev eth3 proto kernel scope link src 10.10.10.12 metric 103 
10.20.0.0/24 dev eth2 proto kernel scope link src 10.20.0.2 metric 102 
127.0.0.1 via 10.0.0.1 dev eth1 proto zebra metric 20 
127.0.0.3 via 10.20.0.1 dev eth2 proto zebra metric 20 
```

### Router r3:

```shell
[root@r3 ~]# ip r
default via 10.10.0.1 dev eth1 proto zebra metric 10 
10.0.0.0/24 proto zebra metric 20 
	nexthop via 10.10.0.1 dev eth1 weight 1 
	nexthop via 10.20.0.2 dev eth2 weight 1 
10.0.2.0/24 dev eth0 proto kernel scope link src 10.0.2.15 metric 100 
10.10.0.0/24 dev eth1 proto kernel scope link src 10.10.0.2 metric 101 
10.10.10.0/24 dev eth3 proto kernel scope link src 10.10.10.13 metric 103 
10.20.0.0/24 dev eth2 proto kernel scope link src 10.20.0.1 metric 102 
127.0.0.1 via 10.10.0.1 dev eth1 proto zebra metric 20 
127.0.0.2 via 10.20.0.2 dev eth2 proto zebra metric 20 
```

Проверим OSPF соседей на роутере:

```shell
r1# sh ip ospf  neighbor  

    Neighbor ID Pri State           Dead Time Address         Interface            RXmtL RqstL DBsmL
127.0.0.2         1 Full/Backup       34.537s 10.0.0.2        eth1:10.0.0.1            0     0     0
127.0.0.3         1 Full/Backup       37.558s 10.10.0.2       eth2:10.10.0.1           0     0     0

```

```shell
r2# sh ip ospf neighbor  

    Neighbor ID Pri State           Dead Time Address         Interface            RXmtL RqstL DBsmL
127.0.0.1         1 Full/DR           36.747s 10.0.0.1        eth1:10.0.0.2            0     0     0
127.0.0.3         1 Full/Backup       34.599s 10.20.0.1       eth2:10.20.0.2           0     0     0
```

```shell
r3# sh ip ospf neighbor  

    Neighbor ID Pri State           Dead Time Address         Interface            RXmtL RqstL DBsmL
127.0.0.1         1 Full/DR           36.495s 10.10.0.1       eth1:10.10.0.2           0     0     0
127.0.0.2         1 Full/DR           31.275s 10.20.0.2       eth2:10.20.0.1           0     0     0
```

## Изобразить ассиметричный роутинг:

Продемонстрируем ассиметричный роутинг на примере роутеров r2 и r3. Маршрут до сетей 127.0.0.2 и 127.0.0.3 соответственно на этих роутерах выглядит следующим образом:

### Router r2:

```shell
[root@r2 ~]# ip route get 127.0.0.3
127.0.0.3 via 10.20.0.1 dev eth2 src 10.20.0.2 
```

### Router r3:

```shell
[root@r3 ~]# ip route get 127.0.0.2
127.0.0.2 via 10.20.0.2 dev eth2 src 10.20.0.1 
```

Теперь повысим стоимость интерфейса eth2 на r3, чтобы OSPF перестроил таблицу маршрутизации, после чего траффик с r3 к сетям за r2 пойдет через r1:

```shell
[root@r3 ~]# vtysh

Hello, this is Quagga (version 0.99.22.4).
Copyright 1996-2005 Kunihiro Ishiguro, et al.

r3# conf t
r3(config)# int eth2
r3(config-if)# ip ospf cost 100
```

Проверим, что маршурт до 10.20.0.2 на r3 обновился:

```shell
[root@r3 ~]# ip route get 127.0.0.2
127.0.0.2 via 10.10.0.1 dev eth1 src 10.10.0.2 
```

## Сделать один из линков "дорогим", но чтобы при этом роутинг был симметричным

Чтобы восстановить "симметричность" роутинга, не меняя стоимость "дорогого" интерфейса eth2, необходимо выставить стоимость интерфейса eth1 на r3 в значение 100, как и у eth2:

```shell
[root@r3 ~]# vtysh

Hello, this is Quagga (version 0.99.22.4).
Copyright 1996-2005 Kunihiro Ishiguro, et al.

r3# conf t
r3(config)# int eth1
r3(config-if)# ip ospf  cost 100
```

Проверим маршурт до 127.0.0.2 на r3:

```shell
[root@r3 ~]# ip route get 127.0.0.2
127.0.0.2 via 10.20.0.2 dev eth2 src 10.20.0.1 
```