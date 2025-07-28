## Домашнее задание VPN
____

### Цель домашнего задания:

Создать домашнюю сетевую лабораторию. Научится настраивать VPN-сервер в Linux-based системах.

### Описание домашнего задания:

1. Настроить VPN между двумя ВМ в tun/tap режимах, замерить скорость в туннелях, сделать вывод об отличающихся показателях
2. Поднять RAS на базе OpenVPN с клиентскими сертификатами, подключиться с локальной машины на ВМ
3. (*) Самостоятельно изучить и настроить ocserv, подключиться с хоста к ВМ

## Выполнение:

Создадим Vagrantfile, в котором будут указаны параметры наших ВМ:

```sh
ENV['VAGRANT_SERVER_URL'] = 'http://vagrant.elab.pro'


MACHINES = {
  :"server" => {
              :box_name => "ubuntu/jammy64",
              :box_version => "1.0.0",
              :cpus => 1,
              :memory => 1024,
              :ip => '192.168.56.10',
            },
  :"client" => {
              :box_name => "ubuntu/jammy64",
              :box_version => "1.0.0",
              :cpus => 1,
              :memory => 1024,
              :ip => '192.168.56.20',
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

После запуска машин из Vagrantfile необходимо выполнить следующие действия на server и client машинах:

Устанавливаем нужные пакеты и отключаем SELinux

```sh
apt update
apt install openvpn iperf3 selinux-utils -y
setenforce 0
```

### Настройка хоста 1:

Cоздаем файл-ключ

```sh
openvpn --genkey secret /etc/openvpn/static.key
```

Cоздаем конфигурационный файл OpenVPN

```sh
vim /etc/openvpn/server.conf
```

Содержимое файла server.conf

```sh
dev tap 
ifconfig 10.10.10.1 255.255.255.0 
topology subnet 
secret /etc/openvpn/static.key 
comp-lzo 
status /var/log/openvpn-status.log 
log /var/log/openvpn.log  
verb 3
```

Создаем service unit для запуска OpenVPN

```sh
vim /etc/systemd/system/openvpn@.service
```

Содержимое файла-юнита

```sh
[Unit] 
Description=OpenVPN Tunneling Application On %I 
After=network.target 
[Service] 
Type=notify 
PrivateTmp=true 
ExecStart=/usr/sbin/openvpn --cd /etc/openvpn/ --config %i.conf 
[Install] 
WantedBy=multi-user.target
```

Запускаем сервис

```sh
systemctl start openvpn@server 
systemctl enable openvpn@server
```

### Настройка хоста 2:

Cоздаем конфигурационный файл OpenVPN

```sh
vim /etc/openvpn/server.conf
```

Содержимое конфигурационного файла

```sh
dev tap 
remote 192.168.56.10 
ifconfig 10.10.10.2 255.255.255.0 
topology subnet 
route 192.168.56.0 255.255.255.0 
secret /etc/openvpn/static.key
comp-lzo
status /var/log/openvpn-status.log 
log /var/log/openvpn.log 
verb 3
```

На хост 2 в директорию /etc/openvpn необходимо скопировать файл-ключ static.key, который был создан на хосте 1.

Создаем service unit для запуска OpenVPN

```sh
vim /etc/systemd/system/openvpn@.service
```

Содержимое файла-юнита

```sh
[Unit] 
Description=OpenVPN Tunneling Application On %I 
After=network.target 
[Service] 
Type=notify 
PrivateTmp=true 
ExecStart=/usr/sbin/openvpn --cd /etc/openvpn/ --config %i.conf 
[Install] 
WantedBy=multi-user.target
```

Запускаем сервис

```sh
systemctl start openvpn@server 
systemctl enable openvpn@server
```

### Далее необходимо замерить скорость в туннеле:

1. На хосте 1 запускаем iperf3 в режиме сервера: ```iperf3 -s &```

```sh
root@server:~# iperf3 -s &
[1] 1027
root@server:~# -----------------------------------------------------------
Server listening on 5201
-----------------------------------------------------------
Accepted connection from 10.10.10.2, port 41178
[  5] local 10.10.10.1 port 5201 connected to 10.10.10.2 port 41190
[ ID] Interval           Transfer     Bitrate
[  5]   0.00-1.00   sec  2.49 MBytes  20.9 Mbits/sec                  
[  5]   1.00-2.00   sec  2.61 MBytes  21.9 Mbits/sec                  
[  5]   2.00-3.00   sec  2.79 MBytes  23.4 Mbits/sec                  
[  5]   3.00-4.00   sec  2.62 MBytes  22.0 Mbits/sec                  
[  5]   4.00-5.00   sec  2.64 MBytes  22.2 Mbits/sec                  
[  5]   5.00-6.00   sec  2.69 MBytes  22.6 Mbits/sec                  
[  5]   6.00-7.00   sec  3.07 MBytes  25.8 Mbits/sec                  
[  5]   7.00-8.00   sec  3.07 MBytes  25.7 Mbits/sec                  
[  5]   8.00-9.00   sec  3.02 MBytes  25.3 Mbits/sec                  
[  5]   9.00-10.00  sec  3.16 MBytes  26.5 Mbits/sec                  
[  5]  10.00-11.00  sec  2.91 MBytes  24.4 Mbits/sec                  
[  5]  11.00-12.00  sec  2.82 MBytes  23.7 Mbits/sec                  
[  5]  12.00-13.00  sec  3.06 MBytes  25.6 Mbits/sec                  
[  5]  13.00-14.00  sec  2.90 MBytes  24.3 Mbits/sec                  
[  5]  14.00-15.00  sec  2.65 MBytes  22.2 Mbits/sec                  
[  5]  15.00-16.00  sec  2.58 MBytes  21.6 Mbits/sec                  
[  5]  16.00-17.00  sec  2.87 MBytes  24.1 Mbits/sec                  
[  5]  17.00-18.00  sec  2.61 MBytes  21.9 Mbits/sec                  
[  5]  18.00-19.00  sec  2.81 MBytes  23.6 Mbits/sec                  
[  5]  19.00-20.00  sec  2.80 MBytes  23.5 Mbits/sec                  
[  5]  20.00-21.00  sec  2.86 MBytes  23.9 Mbits/sec                  
[  5]  21.00-22.00  sec  2.85 MBytes  23.9 Mbits/sec                  
[  5]  22.00-23.00  sec  2.57 MBytes  21.6 Mbits/sec                  
[  5]  23.00-24.00  sec  2.44 MBytes  20.4 Mbits/sec                  
[  5]  24.00-25.00  sec  2.69 MBytes  22.6 Mbits/sec                  
[  5]  25.00-26.00  sec  2.77 MBytes  23.2 Mbits/sec                  
[  5]  26.00-27.00  sec  2.83 MBytes  23.7 Mbits/sec                  
[  5]  27.00-28.00  sec  3.08 MBytes  25.9 Mbits/sec                  
[  5]  28.00-29.00  sec  2.97 MBytes  24.9 Mbits/sec                  
[  5]  29.00-30.00  sec  3.10 MBytes  26.0 Mbits/sec                  
[  5]  30.00-31.00  sec  2.68 MBytes  22.5 Mbits/sec                  
[  5]  31.00-32.00  sec  2.54 MBytes  21.3 Mbits/sec                  
[  5]  32.00-33.00  sec  2.40 MBytes  20.1 Mbits/sec                  
[  5]  33.00-34.00  sec  2.68 MBytes  22.5 Mbits/sec                  
[  5]  34.00-35.00  sec  3.12 MBytes  26.2 Mbits/sec                  
[  5]  34.00-35.00  sec  3.12 MBytes  26.2 Mbits/sec                  
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate
[  5]   0.00-35.00  sec  98.6 MBytes  23.6 Mbits/sec                  receiver
iperf3: the client has terminated
-----------------------------------------------------------
Server listening on 5201
-----------------------------------------------------------
```

2. На хосте 2 запускаем iperf3 в режиме клиента и замеряем  скорость в туннеле: ```iperf3 -c 10.10.10.1 -t 40 -i 5```

```sh
root@client:~# iperf3 -c 10.10.10.1 -t 40 -i 5
Connecting to host 10.10.10.1, port 5201
[  5] local 10.10.10.2 port 41190 connected to 10.10.10.1 port 5201
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  5]   0.00-5.00   sec  14.2 MBytes  23.9 Mbits/sec    0    679 KBytes       
[  5]   5.00-10.00  sec  15.7 MBytes  26.4 Mbits/sec  131    365 KBytes       
[  5]  10.00-15.00  sec  14.7 MBytes  24.6 Mbits/sec   11    357 KBytes       
[  5]  15.00-20.00  sec  13.0 MBytes  21.7 Mbits/sec   38    298 KBytes       
[  5]  20.00-25.00  sec  13.8 MBytes  23.2 Mbits/sec    0    383 KBytes       
[  5]  25.00-30.00  sec  14.8 MBytes  24.9 Mbits/sec   54    208 KBytes       
[  5]  30.00-35.00  sec  13.1 MBytes  22.0 Mbits/sec    0    249 KBytes       
^C[  5]  35.00-35.21  sec   885 KBytes  35.2 Mbits/sec    0    249 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  5]   0.00-35.21  sec   100 MBytes  23.9 Mbits/sec  234             sender
[  5]   0.00-35.21  sec  0.00 Bytes  0.00 bits/sec                  receiver
iperf3: interrupt - the client has terminated
```

На сервере и клиенте меняем в файле server.conf режим на tun

Сервер:

```sh
dev tun
ifconfig 10.10.10.1 255.255.255.0
topology subnet
secret /etc/openvpn/static.key
comp-lzo
status /var/log/openvpn-status.log
log /var/log/openvpn.log
verb 3
```

Клиент:

```sh
dev tun
remote 192.168.56.10
ifconfig 10.10.10.2 255.255.255.0
topology subnet
route 192.168.56.0 255.255.255.0
secret /etc/openvpn/static.key
comp-lzo
status /var/log/openvpn-status.log
log /var/log/openvpn.log
verb 3
```

### Далее необходимо замерить скорость в туннеле:

1. На хосте 1 запускаем iperf3 в режиме сервера: ```iperf3 -s &```

```sh
root@server:~# -----------------------------------------------------------
Server listening on 5201
-----------------------------------------------------------
Accepted connection from 10.10.10.2, port 49192
[  5] local 10.10.10.1 port 5201 connected to 10.10.10.2 port 49200
[ ID] Interval           Transfer     Bitrate
[  5]   0.00-1.00   sec  2.65 MBytes  22.2 Mbits/sec                  
[  5]   1.00-2.00   sec  2.73 MBytes  22.9 Mbits/sec                  
[  5]   2.00-3.00   sec  2.93 MBytes  24.6 Mbits/sec                  
[  5]   3.00-4.00   sec  2.85 MBytes  23.9 Mbits/sec                  
[  5]   4.00-5.00   sec  2.70 MBytes  22.7 Mbits/sec                  
[  5]   5.00-6.00   sec  2.83 MBytes  23.7 Mbits/sec                  
[  5]   6.00-7.00   sec  2.88 MBytes  24.2 Mbits/sec                  
[  5]   7.00-8.00   sec  2.68 MBytes  22.5 Mbits/sec                  
[  5]   8.00-9.00   sec  2.90 MBytes  24.3 Mbits/sec                  
[  5]   9.00-10.00  sec  3.07 MBytes  25.7 Mbits/sec                  
[  5]  10.00-11.00  sec  2.44 MBytes  20.5 Mbits/sec                  
[  5]  11.00-12.00  sec  2.58 MBytes  21.6 Mbits/sec                  
[  5]  12.00-13.00  sec  2.42 MBytes  20.3 Mbits/sec                  
[  5]  13.00-14.00  sec  2.74 MBytes  23.0 Mbits/sec                  
[  5]  14.00-15.00  sec  2.76 MBytes  23.2 Mbits/sec                  
[  5]  15.00-16.00  sec  2.49 MBytes  20.9 Mbits/sec                  
[  5]  16.00-17.00  sec  2.81 MBytes  23.6 Mbits/sec                  
[  5]  17.00-18.00  sec  3.18 MBytes  26.7 Mbits/sec                  
[  5]  18.00-19.00  sec  3.19 MBytes  26.7 Mbits/sec                  
[  5]  19.00-20.00  sec  2.79 MBytes  23.4 Mbits/sec                  
[  5]  20.00-21.00  sec  3.05 MBytes  25.6 Mbits/sec                  
[  5]  21.00-22.00  sec  2.41 MBytes  20.2 Mbits/sec                  
[  5]  22.00-23.00  sec  3.18 MBytes  26.7 Mbits/sec                  
[  5]  23.00-24.00  sec  2.82 MBytes  23.6 Mbits/sec                  
[  5]  24.00-25.00  sec  2.42 MBytes  20.3 Mbits/sec                  
[  5]  25.00-26.00  sec  2.84 MBytes  23.9 Mbits/sec                  
[  5]  26.00-27.00  sec  3.29 MBytes  27.6 Mbits/sec                  
[  5]  27.00-28.00  sec  3.17 MBytes  26.6 Mbits/sec                  
[  5]  28.00-29.00  sec  3.02 MBytes  25.3 Mbits/sec                  
[  5]  29.00-30.00  sec  3.08 MBytes  25.8 Mbits/sec                  
[  5]  30.00-31.00  sec  2.97 MBytes  24.9 Mbits/sec                  
[  5]  31.00-32.00  sec  2.81 MBytes  23.5 Mbits/sec                  
[  5]  32.00-33.00  sec  2.90 MBytes  24.3 Mbits/sec                  
[  5]  33.00-34.00  sec  2.60 MBytes  21.8 Mbits/sec                  
[  5]  34.00-35.00  sec  2.93 MBytes  24.5 Mbits/sec                  
[  5]  35.00-36.00  sec  3.18 MBytes  26.7 Mbits/sec                  
[  5]  36.00-37.00  sec  3.24 MBytes  27.2 Mbits/sec                  
[  5]  37.00-38.00  sec  3.11 MBytes  26.0 Mbits/sec                  
[  5]  38.00-39.00  sec  3.40 MBytes  28.5 Mbits/sec                  
[  5]  39.00-40.00  sec  2.76 MBytes  23.1 Mbits/sec                  
[  5]  40.00-40.08  sec   203 KBytes  21.2 Mbits/sec                  
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate
[  5]   0.00-40.08  sec   115 MBytes  24.1 Mbits/sec                  receiver
-----------------------------------------------------------
Server listening on 5201
-----------------------------------------------------------
```

2. На хосте 2 запускаем iperf3 в режиме клиента и замеряем  скорость в туннеле: ```iperf3 -c 10.10.10.1 -t 40 -i 5```

```sh
root@client:~# iperf3 -c 10.10.10.1 -t 40 -i 5
Connecting to host 10.10.10.1, port 5201
[  5] local 10.10.10.2 port 49200 connected to 10.10.10.1 port 5201
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  5]   0.00-5.00   sec  15.2 MBytes  25.5 Mbits/sec   24    444 KBytes       
[  5]   5.00-10.00  sec  14.5 MBytes  24.3 Mbits/sec   16    292 KBytes       
[  5]  10.00-15.00  sec  13.0 MBytes  21.8 Mbits/sec   16    238 KBytes       
[  5]  15.00-20.00  sec  14.2 MBytes  23.9 Mbits/sec    0    324 KBytes       
[  5]  20.00-25.00  sec  13.6 MBytes  22.9 Mbits/sec    0    371 KBytes       
[  5]  25.00-30.00  sec  15.7 MBytes  26.4 Mbits/sec   53    287 KBytes       
[  5]  30.00-35.00  sec  14.2 MBytes  23.9 Mbits/sec    0    340 KBytes       
[  5]  35.00-40.00  sec  15.5 MBytes  26.1 Mbits/sec    0    418 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  5]   0.00-40.00  sec   116 MBytes  24.3 Mbits/sec  109             sender
[  5]   0.00-40.08  sec   115 MBytes  24.1 Mbits/sec                  receiver

iperf Done.
```

#### В лабораторной среде результаты в режиме tun лучше. Поэтому режим tap рекомендуется использовать в специфических задачах, например, если в архитектуре сети необходимо достичь связности по L2, в остальных же случаях нужно использовать режим tun.

## RAS на базе OpenVPN

Настройка сервера:

Устанавливаем необходимые пакеты

```sh
apt update
apt install openvpn easy-rsa -y
```

Переходим в директорию /etc/openvpn и инициализируем PKI

```sh
root@server:~# cd /etc/openvpn
root@server:/etc/openvpn# /usr/share/easy-rsa/easyrsa init-pki

init-pki complete; you may now create a CA or requests.
Your newly created PKI dir is: /etc/openvpn/pki
```

Генерируем необходимые ключи и сертификаты для сервера

```sh
root@server:~# echo 'rasvpn' | /usr/share/easy-rsa/easyrsa gen-req server nopass
root@server:~# echo 'yes' | /usr/share/easy-rsa/easyrsa sign-req server server /usr/share/easy-rsa/easyrsa gen-dh
root@server:~# openvpn --genkey secret ca.key
```

Генерируем необходимые ключи и сертификаты для клиента

```sh
root@server:~# echo 'client' | /usr/share/easy-rsa/easyrsa gen-req client nopass
root@server:~# echo 'yes' | /usr/share/easy-rsa/easyrsa sign-req client client
```

Создаем конфигурационный файл сервера

```sh
root@server:~# vim /etc/openvpn/server.conf
```

Зададим параметр iroute для клиента

```sh
root@server:/etc/openvpn# echo 'iroute 10.10.10.0 255.255.255.0' > /etc/openvpn/client/client
```

Содержимое файла server.conf

```sh
port 1207 
proto udp 
dev tun 
ca /etc/openvpn/pki/ca.crt 
cert /etc/openvpn/pki/issued/server.crt 
key /etc/openvpn/pki/private/server.key 
dh /etc/openvpn/pki/dh.pem 
server 10.10.10.0 255.255.255.0 
ifconfig-pool-persist ipp.txt 
client-to-client 
client-config-dir /etc/openvpn/client 
keepalive 10 120 
comp-lzo 
persist-key 
persist-tun 
status /var/log/openvpn-status.log 
log /var/log/openvpn.log 
verb 3
```

Запускаем сервис:

```sh
root@server:~# systemctl start openvpn@server
root@server:~# systemctl enable openvpn@server
```

На client машине:

1. Необходимо создать файл client.conf со следующим содержимым:

```sh
dev tun 
proto udp 
remote 192.168.56.10 1207 
client 
resolv-retry infinite 
remote-cert-tls server 
ca ./ca.crt 
cert ./client.crt 
key ./client.key 
route 192.168.56.0 255.255.255.0 
persist-key 
persist-tun 
comp-lzo 
verb 3 
```

2. Скопировать в одну директорию с client.conf файлы с сервера:

```sh
/etc/openvpn/pki/ca.crt 
/etc/openvpn/pki/issued/client.crt 
/etc/openvpn/pki/private/client.key
```

Подключаемся к серверу с клиента:

```sh
root@client:~# openvpn --config /etc/openvpn/client.conf
```

Проверим доступность лупбэка на машине server:

```sh
root@client:~# ping 10.10.10.1
PING 10.10.10.1 (10.10.10.1) 56(84) bytes of data.
64 bytes from 10.10.10.1: icmp_seq=1 ttl=64 time=1.72 ms
64 bytes from 10.10.10.1: icmp_seq=2 ttl=64 time=1.20 ms
64 bytes from 10.10.10.1: icmp_seq=3 ttl=64 time=1.31 ms
64 bytes from 10.10.10.1: icmp_seq=4 ttl=64 time=1.09 ms
```