## Домашнее задание Vagrant-стенд c VLAN и LACP
____

### Цель домашнего задания:

Научиться настраивать VLAN и LACP.

### Описание домашнего задания:

в Office1 в тестовой подсети появляется сервера с доп интерфейсами и адресами
в internal сети testLAN: 
- testClient1 - 10.10.10.254
- testClient2 - 10.10.10.254
- testServer1- 10.10.10.1 
- testServer2- 10.10.10.1

Равести вланами:
testClient1 <-> testServer1
testClient2 <-> testServer2

Между centralRouter и inetRouter "пробросить" 2 линка (общая inernal сеть) и объединить их в бонд, проверить работу c отключением интерфейсов

Формат сдачи ДЗ - vagrant + ansible

## Выполнение:

Создадим Vagrantfile, в котором будут указаны параметры наших ВМ:

```sh
ENV['VAGRANT_SERVER_URL'] = 'http://vagrant.elab.pro'

Vagrant.configure(2) do |config|
  config.vm.box = "centos/7"

  config.vm.provider "virtualbox" do |v|
    v.memory = 256
  end

  config.vm.define "inetRouter" do |inetRouter|
    inetRouter.vm.network "private_network", ip: "192.168.50.4", virtualbox__intnet: "router-net", auto_config: false
    inetRouter.vm.network "private_network", ip: "192.168.50.5", virtualbox__intnet: "router-net", auto_config: false
    #management network
    inetRouter.vm.network "private_network", ip: "192.168.56.10"
    inetRouter.vm.hostname = "inetRouter"
  end

  config.vm.define "centralRouter" do |centralRouter|
    centralRouter.vm.network "private_network", ip: "192.168.50.6", virtualbox__intnet: "router-net", auto_config: false
    centralRouter.vm.network "private_network", ip: "192.168.50.7", virtualbox__intnet: "router-net", auto_config: false
    centralRouter.vm.network "private_network", ip: "192.168.2.1", virtualbox__intnet: "test-lan"
    #management network
    centralRouter.vm.network "private_network", ip: "192.168.56.11"
    centralRouter.vm.hostname = "centralRouter"
  end

  config.vm.define "testServer1" do |testServer1|
    testServer1.vm.network "private_network", ip: "192.168.2.2", virtualbox__intnet: "test-lan"
    #management network
    testServer1.vm.network "private_network", ip: "192.168.56.20"
    testServer1.vm.hostname = "testServer1"
  end

  config.vm.define "testClient1" do |testClient1|
    testClient1.vm.network "private_network", ip: "192.168.2.3", virtualbox__intnet: "test-lan"
    #management network
    testClient1.vm.network "private_network", ip: "192.168.56.21"
    testClient1.vm.hostname = "testClient1"
  end

  config.vm.define "testServer2" do |testServer2|
    testServer2.vm.network "private_network", ip: "192.168.2.4", virtualbox__intnet: "test-lan"
    #management network
    testServer2.vm.network "private_network", ip: "192.168.56.30"
    testServer2.vm.hostname = "testServer2"
  end

  config.vm.define "testClient2" do |testClient2|
    testClient2.vm.network "private_network", ip: "192.168.2.5", virtualbox__intnet: "test-lan"
    #management network
    testClient2.vm.network "private_network", ip: "192.168.56.31"
    testClient2.vm.hostname = "testClient2"
  config.vm.provision "shell", inline: <<-SHELL
        mkdir -p ~root/.ssh
        cp ~vagrant/.ssh/auth* ~root/.ssh
        sed -i 's/^PasswordAuthentication.*$/PasswordAuthentication yes/' /etc/ssh/sshd_config
        sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
        sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*
        systemctl restart sshd.service
      SHELL

#    testClient2.vm.provision "vlan-bonding", type:'ansible' do |ansible|
#      ansible.limit = 'all'
#      ansible.inventory_path = './inventories/all.yml'
#      ansible.playbook = './vlan-bonding.yml'
#    end

  end

end
```

Копируем файлы в каталог и запускаем Vagrantfile:

```sh
vagrant up
```

#### Когда виртуальные машины создадутся, необходимо скопировать сертификат с хостовой машины, выполнив команды:

```sh
ivan@ivan-Otus:~/Desktop/Otus_HomeWork/Home work 25$ ssh-copy-id -i ~/.ssh/id_rsa.pub vagrant@192.168.56.10
/usr/bin/ssh-copy-id: INFO: Source of key(s) to be installed: "/home/ivan/.ssh/id_rsa.pub"
The authenticity of host '192.168.56.10 (192.168.56.10)' can't be established.
ED25519 key fingerprint is SHA256:/yw6pet1SeChx6+B+wEg/gegbSgOjhZroFc66RRYpHM.
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
/usr/bin/ssh-copy-id: INFO: attempting to log in with the new key(s), to filter out any that are already installed
/usr/bin/ssh-copy-id: INFO: 1 key(s) remain to be installed -- if you are prompted now it is to install the new keys
vagrant@192.168.56.10's password: 

Number of key(s) added: 1

Now try logging into the machine, with:   "ssh 'vagrant@192.168.56.10'"
and check to make sure that only the key(s) you wanted were added.

ivan@ivan-Otus:~/Desktop/Otus_HomeWork/Home work 25$ ssh-copy-id -i ~/.ssh/id_rsa.pub vagrant@192.168.56.11
/usr/bin/ssh-copy-id: INFO: Source of key(s) to be installed: "/home/ivan/.ssh/id_rsa.pub"
The authenticity of host '192.168.56.11 (192.168.56.11)' can't be established.
ED25519 key fingerprint is SHA256:ho81CQan43EflKxWIxvFE0qGRAGUiPK4rIVpQh1VZQ0.
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
/usr/bin/ssh-copy-id: INFO: attempting to log in with the new key(s), to filter out any that are already installed
/usr/bin/ssh-copy-id: INFO: 1 key(s) remain to be installed -- if you are prompted now it is to install the new keys
vagrant@192.168.56.11's password: 

Number of key(s) added: 1

Now try logging into the machine, with:   "ssh 'vagrant@192.168.56.11'"
and check to make sure that only the key(s) you wanted were added.

ivan@ivan-Otus:~/Desktop/Otus_HomeWork/Home work 25$ ssh-copy-id -i ~/.ssh/id_rsa.pub vagrant@192.168.56.20
/usr/bin/ssh-copy-id: INFO: Source of key(s) to be installed: "/home/ivan/.ssh/id_rsa.pub"
The authenticity of host '192.168.56.20 (192.168.56.20)' can't be established.
ED25519 key fingerprint is SHA256:pnWMIEa4VHrEOQRvoxSzhPoXG/pP1jGZ2ClfXVyfXxU.
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
/usr/bin/ssh-copy-id: INFO: attempting to log in with the new key(s), to filter out any that are already installed
/usr/bin/ssh-copy-id: INFO: 1 key(s) remain to be installed -- if you are prompted now it is to install the new keys
vagrant@192.168.56.20's password: 

Number of key(s) added: 1

Now try logging into the machine, with:   "ssh 'vagrant@192.168.56.20'"
and check to make sure that only the key(s) you wanted were added.

ivan@ivan-Otus:~/Desktop/Otus_HomeWork/Home work 25$ ssh-copy-id -i ~/.ssh/id_rsa.pub vagrant@192.168.56.21
/usr/bin/ssh-copy-id: INFO: Source of key(s) to be installed: "/home/ivan/.ssh/id_rsa.pub"
The authenticity of host '192.168.56.21 (192.168.56.21)' can't be established.
ED25519 key fingerprint is SHA256:YAz2kSnU50bRJDju4v3ZHJnRKNpVbpcmuWxvnr2/sh4.
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
/usr/bin/ssh-copy-id: INFO: attempting to log in with the new key(s), to filter out any that are already installed
/usr/bin/ssh-copy-id: INFO: 1 key(s) remain to be installed -- if you are prompted now it is to install the new keys
vagrant@192.168.56.21's password: 

Number of key(s) added: 1

Now try logging into the machine, with:   "ssh 'vagrant@192.168.56.21'"
and check to make sure that only the key(s) you wanted were added.

ivan@ivan-Otus:~/Desktop/Otus_HomeWork/Home work 25$ ssh-copy-id -i ~/.ssh/id_rsa.pub vagrant@192.168.56.30
/usr/bin/ssh-copy-id: INFO: Source of key(s) to be installed: "/home/ivan/.ssh/id_rsa.pub"
The authenticity of host '192.168.56.30 (192.168.56.30)' can't be established.
ED25519 key fingerprint is SHA256:vKEDwxT/4FvyT6tKBfpru8f3GL4UTcGqdbc0CJFyMXg.
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
/usr/bin/ssh-copy-id: INFO: attempting to log in with the new key(s), to filter out any that are already installed
/usr/bin/ssh-copy-id: INFO: 1 key(s) remain to be installed -- if you are prompted now it is to install the new keys
vagrant@192.168.56.30's password: 

Number of key(s) added: 1

Now try logging into the machine, with:   "ssh 'vagrant@192.168.56.30'"
and check to make sure that only the key(s) you wanted were added.

ivan@ivan-Otus:~/Desktop/Otus_HomeWork/Home work 25$ ssh-copy-id -i ~/.ssh/id_rsa.pub vagrant@192.168.56.31
/usr/bin/ssh-copy-id: INFO: Source of key(s) to be installed: "/home/ivan/.ssh/id_rsa.pub"
The authenticity of host '192.168.56.31 (192.168.56.31)' can't be established.
ED25519 key fingerprint is SHA256:0Tm2aCYgAJ+brFKemxtGXoHEk1MR5W1gd+Nktw/EIdY.
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
/usr/bin/ssh-copy-id: INFO: attempting to log in with the new key(s), to filter out any that are already installed
/usr/bin/ssh-copy-id: INFO: 1 key(s) remain to be installed -- if you are prompted now it is to install the new keys
vagrant@192.168.56.31's password: 

Number of key(s) added: 1

Now try logging into the machine, with:   "ssh 'vagrant@192.168.56.31'"
and check to make sure that only the key(s) you wanted were added.
```

#### Запускаем playbook:

```sh
ivan@ivan-Otus:~/Desktop/Otus_HomeWork/Home work 25$ ansible-playbook vlan-bonding.yml
```

## Проверяем VLANs:
____

#### testServer1:

```sh
ivan@ivan-Otus:~/Desktop/Otus_HomeWork/Home work 25$ ssh vagrant@192.168.56.20
Last login: Wed Aug  6 12:52:49 2025 from 192.168.56.1
[vagrant@testServer1 ~]$ ip --brief addr show
lo               UNKNOWN        127.0.0.1/8 ::1/128 
eth0             UP             10.0.2.15/24 fe80::5054:ff:fe4d:77d3/64 
eth1             UP             192.168.2.2/24 fe80::a00:27ff:fecd:1da5/64 
eth2             UP             192.168.56.20/24 fe80::a00:27ff:fe00:c0bc/64 
eth1.10@eth1     UP             10.10.10.1/24 fe80::a00:27ff:fecd:1da5/64 
[vagrant@testServer1 ~]$ ping 10.10.10.254
PING 10.10.10.254 (10.10.10.254) 56(84) bytes of data.
64 bytes from 10.10.10.254: icmp_seq=1 ttl=64 time=14.3 ms
64 bytes from 10.10.10.254: icmp_seq=2 ttl=64 time=1.20 ms
64 bytes from 10.10.10.254: icmp_seq=3 ttl=64 time=1.05 ms
64 bytes from 10.10.10.254: icmp_seq=4 ttl=64 time=0.974 ms
^C
--- 10.10.10.254 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3006ms
rtt min/avg/max/mdev = 0.974/4.408/14.399/5.769 ms
```

#### testClient1:

```sh
ivan@ivan-Otus:~/Desktop/Otus_HomeWork/Home work 25$ ssh vagrant@192.168.56.21
Last login: Wed Aug  6 12:52:45 2025 from 192.168.56.1
[vagrant@testClient1 ~]$ ip --brief addr show
lo               UNKNOWN        127.0.0.1/8 ::1/128 
eth0             UP             10.0.2.15/24 fe80::5054:ff:fe4d:77d3/64 
eth1             UP             192.168.2.3/24 fe80::a00:27ff:fe54:18d1/64 
eth2             UP             192.168.56.21/24 fe80::a00:27ff:fef4:dbdf/64 
eth1.10@eth1     UP             10.10.10.254/24 fe80::a00:27ff:fe54:18d1/64 
[vagrant@testClient1 ~]$ ping 10.10.10.1
PING 10.10.10.1 (10.10.10.1) 56(84) bytes of data.
64 bytes from 10.10.10.1: icmp_seq=1 ttl=64 time=0.892 ms
64 bytes from 10.10.10.1: icmp_seq=2 ttl=64 time=1.02 ms
64 bytes from 10.10.10.1: icmp_seq=3 ttl=64 time=0.991 ms
64 bytes from 10.10.10.1: icmp_seq=4 ttl=64 time=1.08 ms
^C
--- 10.10.10.1 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3003ms
rtt min/avg/max/mdev = 0.892/0.997/1.085/0.073 ms
```

#### testServer2:

```sh
ivan@ivan-Otus:~/Desktop/Otus_HomeWork/Home work 25$ ssh vagrant@192.168.56.30
Last login: Wed Aug  6 12:52:51 2025 from 192.168.56.1
[vagrant@testServer2 ~]$ ip --brief addr show
lo               UNKNOWN        127.0.0.1/8 ::1/128 
eth0             UP             10.0.2.15/24 fe80::5054:ff:fe4d:77d3/64 
eth1             UP             192.168.2.4/24 fe80::a00:27ff:fe1a:6bb8/64 
eth2             UP             192.168.56.30/24 fe80::a00:27ff:fe14:9ffd/64
eth1.20@eth1     UP             10.10.10.1/24 fe80::a00:27ff:fe28:1170/64 
[vagrant@testServer2 ~]$ ping 10.10.10.254
PING 10.10.10.254 (10.10.10.254) 56(84) bytes of data.
64 bytes from 10.10.10.254: icmp_seq=1 ttl=64 time=2.37 ms
64 bytes from 10.10.10.254: icmp_seq=2 ttl=64 time=0.607 ms
64 bytes from 10.10.10.254: icmp_seq=3 ttl=64 time=0.511 ms
64 bytes from 10.10.10.254: icmp_seq=4 ttl=64 time=1.88 ms
```

#### testClient2:

```sh
ivan@ivan-Otus:~/Desktop/Otus_HomeWork/Home work 25$ ssh vagrant@192.168.56.31
Last login: Wed Aug  6 12:54:49 2025 from 192.168.56.1
[vagrant@testClient2 ~]$ ip --brief addr show
lo               UNKNOWN        127.0.0.1/8 ::1/128 
eth0             UP             10.0.2.15/24 fe80::5054:ff:fe4d:77d3/64 
eth1             UP             192.168.2.5/24 fe80::a00:27ff:fe89:7ab5/64 
eth2             UP             192.168.56.31/24 fe80::a00:27ff:fe0c:9103/64
eth1.20@eth1     UP             10.10.10.254/24 fe80::a00:27ff:fe4c:2acb/64 
[vagrant@testClient2 ~]$ ping 10.10.10.1
PING 10.10.10.1 (10.10.10.1) 56(84) bytes of data.
64 bytes from 10.10.10.1: icmp_seq=1 ttl=64 time=1.36 ms
64 bytes from 10.10.10.1: icmp_seq=2 ttl=64 time=1.14 ms
64 bytes from 10.10.10.1: icmp_seq=3 ttl=64 time=0.706 ms
64 bytes from 10.10.10.1: icmp_seq=4 ttl=64 time=1.42 ms
```

## Проверяем Bonding:
____

#### inetRouter

```sh
ivan@ivan-Otus:~/Desktop/Otus_HomeWork/Home work 25$ ssh vagrant@192.168.56.10
Last login: Wed Aug  6 12:46:26 2025 from 192.168.56.1
[vagrant@inetRouter ~]$ cat /proc/net/bonding/bond0
Ethernet Channel Bonding Driver: v3.7.1 (April 27, 2011)

Bonding Mode: fault-tolerance (active-backup) (fail_over_mac active)
Primary Slave: None
Currently Active Slave: eth1
MII Status: up
MII Polling Interval (ms): 100
Up Delay (ms): 0
Down Delay (ms): 0

Slave Interface: eth1
MII Status: up
Speed: 1000 Mbps
Duplex: full
Link Failure Count: 0
Permanent HW addr: 08:00:27:be:c6:16
Slave queue ID: 0

Slave Interface: eth2
MII Status: up
Speed: 1000 Mbps
Duplex: full
Link Failure Count: 0
Permanent HW addr: 08:00:27:81:48:89
Slave queue ID: 0
```

#### centralRouter

```sh
ivan@ivan-Otus:~/Desktop/Otus_HomeWork/Home work 25$ ssh vagrant@192.168.56.11
Last login: Wed Aug  6 12:46:26 2025 from 192.168.56.1
[vagrant@centralRouter ~]$ cat /proc/net/bonding/bond0
Ethernet Channel Bonding Driver: v3.7.1 (April 27, 2011)

Bonding Mode: fault-tolerance (active-backup) (fail_over_mac active)
Primary Slave: None
Currently Active Slave: eth1
MII Status: up
MII Polling Interval (ms): 100
Up Delay (ms): 0
Down Delay (ms): 0

Slave Interface: eth1
MII Status: up
Speed: 1000 Mbps
Duplex: full
Link Failure Count: 0
Permanent HW addr: 08:00:27:d0:b6:36
Slave queue ID: 0

Slave Interface: eth2
MII Status: up
Speed: 1000 Mbps
Duplex: full
Link Failure Count: 0
Permanent HW addr: 08:00:27:12:25:c0
Slave queue ID: 0
```

Активный интерфейс на обоих роутерах eth1. Запустим пинги и выключим eth1 на inetRouter:

![image 1](https://github.com/IvanPrivalov/Otus_HomeWork/blob/main/Home%20work%2025/Screenshot_01.png)