## Домашнее задание Vagrant-стенд c DNS
____

### Цель домашнего задания:

Создать домашнюю сетевую лабораторию. Изучить основы DNS, научиться работать с технологией Split-DNS в Linux-based системах

### Описание домашнего задания:

1. взять стенд https://github.com/erlong15/vagrant-bind 
    - добавить еще один сервер client2
    - завести в зоне dns.lab имена:
        * web1 - смотрит на клиент1
        * web2  смотрит на клиент2
    - завести еще одну зону newdns.lab
    - завести в ней запись
        * www - смотрит на обоих клиентов

2. настроить split-dns
    - клиент1 - видит обе зоны, но в зоне dns.lab только web1
    - клиент2 видит только dns.lab

Дополнительное задание
* настроить все без выключения selinux

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

  config.vm.define "ns01" do |ns01|
    ns01.vm.network "private_network", ip: "192.168.50.10", virtualbox__intnet: "dns"
    #management network
    ns01.vm.network "private_network", ip: "192.168.56.10"
    ns01.vm.hostname = "ns01"
  end

  config.vm.define "ns02" do |ns02|
    ns02.vm.network "private_network", ip: "192.168.50.11", virtualbox__intnet: "dns"
    #management network
    ns02.vm.network "private_network", ip: "192.168.56.11"
    ns02.vm.hostname = "ns02"
  end

  config.vm.define "client1" do |client1|
    client1.vm.network "private_network", ip: "192.168.50.15", virtualbox__intnet: "dns"
    #management network
    client1.vm.network "private_network", ip: "192.168.56.15"
    client1.vm.hostname = "client1"
  end

  config.vm.define "client2" do |client2|
    client2.vm.network "private_network", ip: "192.168.50.16", virtualbox__intnet: "dns"
    #management network
    client2.vm.network "private_network", ip: "192.168.56.16"
    client2.vm.hostname = "client2"
  end

  config.vm.provision "shell", inline: <<-SHELL
        mkdir -p ~root/.ssh
        cp ~vagrant/.ssh/auth* ~root/.ssh
        sed -i 's/^PasswordAuthentication.*$/PasswordAuthentication yes/' /etc/ssh/sshd_config
        sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
        sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*
        systemctl restart sshd.service
      SHELL
  
#  config.vm.provision "dns", type:'ansible' do |ansible|
#    ansible.inventory_path = './inventories/all.yml'
#    ansible.playbook = "./dns.yml"
#  end
end
```

Копируем файлы в каталог и запускаем Vagrantfile:

```sh
vagrant up
```

#### Когда виртуальные машины создадутся, необходимо скопировать сертификат с хостовой машины, выполнив команды:

```sh
ivan@ivan-Otus:~/Desktop/Otus_HomeWork/Home work 24$ ssh-copy-id -i ~/.ssh/id_rsa.pub vagrant@192.168.56.10
/usr/bin/ssh-copy-id: INFO: Source of key(s) to be installed: "/home/ivan/.ssh/id_rsa.pub"
/usr/bin/ssh-copy-id: INFO: attempting to log in with the new key(s), to filter out any that are already installed
/usr/bin/ssh-copy-id: INFO: 1 key(s) remain to be installed -- if you are prompted now it is to install the new keys
vagrant@192.168.56.10's password: 

Number of key(s) added: 1

Now try logging into the machine, with:   "ssh 'vagrant@192.168.56.10'"
and check to make sure that only the key(s) you wanted were added.

ivan@ivan-Otus:~/Desktop/Otus_HomeWork/Home work 24$ ssh-copy-id -i ~/.ssh/id_rsa.pub vagrant@192.168.56.11
/usr/bin/ssh-copy-id: INFO: Source of key(s) to be installed: "/home/ivan/.ssh/id_rsa.pub"
/usr/bin/ssh-copy-id: INFO: attempting to log in with the new key(s), to filter out any that are already installed
/usr/bin/ssh-copy-id: INFO: 1 key(s) remain to be installed -- if you are prompted now it is to install the new keys
vagrant@192.168.56.11's password: 

Number of key(s) added: 1

Now try logging into the machine, with:   "ssh 'vagrant@192.168.56.11'"
and check to make sure that only the key(s) you wanted were added.

ivan@ivan-Otus:~/Desktop/Otus_HomeWork/Home work 24$ ssh-copy-id -i ~/.ssh/id_rsa.pub vagrant@192.168.56.15
/usr/bin/ssh-copy-id: INFO: Source of key(s) to be installed: "/home/ivan/.ssh/id_rsa.pub"
/usr/bin/ssh-copy-id: INFO: attempting to log in with the new key(s), to filter out any that are already installed
/usr/bin/ssh-copy-id: INFO: 1 key(s) remain to be installed -- if you are prompted now it is to install the new keys
vagrant@192.168.56.15's password: 

Number of key(s) added: 1

Now try logging into the machine, with:   "ssh 'vagrant@192.168.56.15'"
and check to make sure that only the key(s) you wanted were added.

ivan@ivan-Otus:~/Desktop/Otus_HomeWork/Home work 24$ ssh-copy-id -i ~/.ssh/id_rsa.pub vagrant@192.168.56.16
/usr/bin/ssh-copy-id: INFO: Source of key(s) to be installed: "/home/ivan/.ssh/id_rsa.pub"
/usr/bin/ssh-copy-id: INFO: attempting to log in with the new key(s), to filter out any that are already installed
/usr/bin/ssh-copy-id: INFO: 1 key(s) remain to be installed -- if you are prompted now it is to install the new keys
vagrant@192.168.56.16's password: 

Number of key(s) added: 1

Now try logging into the machine, with:   "ssh 'vagrant@192.168.56.16'"
and check to make sure that only the key(s) you wanted were added.
```

#### Запускаем playbook:

```sh
ivan@ivan-Otus:~/Desktop/Otus_HomeWork/Home work 24$ ansible-playbook dns.yml 

PLAY [dnsservers] **********************************************************************************************************************************************************************

TASK [Gathering Facts] *****************************************************************************************************************************************************************
ok: [ns02]
ok: [ns01]

TASK [dns-server : Install packages] ***************************************************************************************************************************************************
changed: [ns02]
changed: [ns01]

TASK [dns-server : Copy key for zone update to ns01] ***********************************************************************************************************************************
changed: [ns02]
changed: [ns01]

TASK [dns-server : Copy named.conf to ns01] ********************************************************************************************************************************************
skipping: [ns02]
changed: [ns01]

TASK [dns-server : Copy named.conf to ns02] ********************************************************************************************************************************************
skipping: [ns01]
changed: [ns02]

TASK [dns-server : Copy zones to ns01] *************************************************************************************************************************************************
skipping: [ns02] => (item=/home/ivan/Desktop/Otus_HomeWork/Home work 24/dns-server/files/named.client2-dns.lab) 
skipping: [ns02] => (item=/home/ivan/Desktop/Otus_HomeWork/Home work 24/dns-server/files/named.client1-dns.lab) 
skipping: [ns02] => (item=/home/ivan/Desktop/Otus_HomeWork/Home work 24/dns-server/files/named.general-dns.lab) 
skipping: [ns02] => (item=/home/ivan/Desktop/Otus_HomeWork/Home work 24/dns-server/files/named.newdns.lab) 
skipping: [ns02]
changed: [ns01] => (item=/home/ivan/Desktop/Otus_HomeWork/Home work 24/dns-server/files/named.client2-dns.lab)
changed: [ns01] => (item=/home/ivan/Desktop/Otus_HomeWork/Home work 24/dns-server/files/named.client1-dns.lab)
changed: [ns01] => (item=/home/ivan/Desktop/Otus_HomeWork/Home work 24/dns-server/files/named.general-dns.lab)
changed: [ns01] => (item=/home/ivan/Desktop/Otus_HomeWork/Home work 24/dns-server/files/named.newdns.lab)

TASK [dns-server : Copy dynamic zone to ns01] ******************************************************************************************************************************************
skipping: [ns02]
changed: [ns01]

TASK [dns-server : Copy resolv.conf to the dns-servers] ********************************************************************************************************************************
changed: [ns01]
changed: [ns02]

TASK [dns-server : Prevent update resolv.conf by network service] **********************************************************************************************************************
changed: [ns02]
changed: [ns01]

TASK [dns-server : Ensure named is running and enabled] ********************************************************************************************************************************
changed: [ns02]
changed: [ns01]

RUNNING HANDLER [dns-server : restart named] *******************************************************************************************************************************************
changed: [ns02]
changed: [ns01]

PLAY [clients] *************************************************************************************************************************************************************************

TASK [Gathering Facts] *****************************************************************************************************************************************************************
ok: [client2]
ok: [client1]

TASK [dns-client : Install packages] ***************************************************************************************************************************************************
changed: [client2]
changed: [client1]

TASK [dns-client : Copy zone update key to clients for zone's update] ******************************************************************************************************************
changed: [client2]
changed: [client1]

TASK [dns-client : Copy resolv.conf to the client] *************************************************************************************************************************************
changed: [client2]
changed: [client1]

TASK [dns-client : Prevent update resolv.conf by Network Manager] **********************************************************************************************************************
changed: [client1]
changed: [client2]

PLAY RECAP *****************************************************************************************************************************************************************************
client1                    : ok=5    changed=4    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
client2                    : ok=5    changed=4    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
ns01                       : ok=10   changed=9    unreachable=0    failed=0    skipped=1    rescued=0    ignored=0   
ns02                       : ok=8    changed=7    unreachable=0    failed=0    skipped=3    rescued=0    ignored=0   
```

#### После загрузки, запускаем client1 и client2:

```sh
ivan@ivan-Otus:~/Desktop/Otus_HomeWork/Home work 24$ ssh vagrant@192.168.56.15
Last login: Fri Aug  1 11:48:46 2025 from 192.168.56.1
[vagrant@client1 ~]$ sudo -i
[root@client1 ~]#
```

```sh
ivan@ivan-Otus:~/Desktop/Otus_HomeWork/Home work 24$ ssh vagrant@192.168.56.16
Last login: Fri Aug  1 11:48:46 2025 from 192.168.56.1
[vagrant@client2 ~]$ sudo -i
[root@client2 ~]#
```

## Проверяем видимость зон:
____

Клиент1 - видит обе зоны, но в зоне dns.lab только web1:

```sh
[root@client1 ~]# dig web1.dns.lab +short @192.168.50.10
192.168.50.111
[root@client1 ~]# dig web1.dns.lab +short @192.168.50.11
192.168.50.111
[root@client1 ~]# dig web2.dns.lab +short @192.168.50.10
[root@client1 ~]# dig web2.dns.lab +short @192.168.50.11
[root@client1 ~]# dig www.newdns.lab +short @192.168.50.10
192.168.50.103
[root@client1 ~]# dig www.newdns.lab +short @192.168.50.11
192.168.50.103
[root@client1 ~]#
```

Клиент2 - видит только dns.lab:

```sh
[root@client2 ~]# dig web1.dns.lab +short @192.168.50.10
192.168.50.111
[root@client2 ~]# dig web1.dns.lab +short @192.168.50.11
192.168.50.111
[root@client2 ~]# dig web2.dns.lab +short @192.168.50.10
192.168.50.112
[root@client2 ~]# dig web2.dns.lab +short @192.168.50.11
192.168.50.112
[root@client2 ~]# dig www.newdns.lab +short @192.168.50.10
[root@client2 ~]# dig www.newdns.lab +short @192.168.50.11
[root@client2 ~]#
```

Видим, что запросы отрабатываются в соответсвии с заданием как на мастере, так и на слэйве.