## Домашнее задание Vagrant-стенд c LDAP на базе FreeIPA
____

### Цель домашнего задания:

Научиться настраивать LDAP-сервер и подключать к нему LDAP-клиентов

### Описание домашнего задания:

1) Установить FreeIPA
2) Написать Ansible-playbook для конфигурации клиента

Дополнительное задание
3) * Настроить аутентификацию по SSH-ключам
4) ** Firewall должен быть включен на сервере и на клиенте

## Выполнение:

Создадим Vagrantfile, в котором будут указаны параметры наших ВМ:

```sh
ENV['VAGRANT_SERVER_URL'] = 'http://vagrant.elab.pro'

Vagrant.configure(2) do |config|
  config.vm.box = "centos/8"

  config.vm.provider "virtualbox" do |v|
    v.memory = 512
  end

  config.vm.define "ipaServer" do |ipaServer|
    ipaServer.vm.network "private_network", ip: "192.168.56.10"
    ipaServer.vm.hostname = "ipa.otus.lan"
  end

  config.vm.define "client1" do |client1|
    client1.vm.network "private_network", ip: "192.168.56.11"
    client1.vm.hostname = "client1.otus.lan"
  end

  config.vm.define "client2" do |client2|
    client2.vm.network "private_network", ip: "192.168.56.12"
    client2.vm.hostname = "client2.otus.lan"

  config.vm.provision "shell", inline: <<-SHELL
        mkdir -p ~root/.ssh
        cp ~vagrant/.ssh/auth* ~root/.ssh
        sed -i 's/^PasswordAuthentication.*$/PasswordAuthentication yes/' /etc/ssh/sshd_config
        sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
        sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*
        systemctl restart sshd.service
      SHELL
  end
end
```

## Установка FreeIPA сервера

Копируем файлы в каталог и запускаем Vagrantfile:

```sh
vagrant up
```

Когда виртуальные машины создадутся, необходимо скопировать сертификат с хостовой машины, выполнив команды:

```sh
ssh-copy-id -i ~/.ssh/id_rsa.pub vagrant@192.168.56.10
ssh-copy-id -i ~/.ssh/id_rsa.pub vagrant@192.168.56.11
ssh-copy-id -i ~/.ssh/id_rsa.pub vagrant@192.168.56.12
```

Для начала нам необходимо настроить FreeIPA-сервер. Подключимся к нему по SSH с помощью команды: ```ssh vagrant@192.168.56.10``` и перейдём в root-пользователя: ```sudo -i```

Начнем настройку FreeIPA-сервера: 
- Установим часовой пояс: ```[root@ipa ~]# timedatectl set-timezone Europe/Moscow```
- Установим утилиту chrony: ```[root@ipa ~]# yum install -y chrony```
- Запустим chrony и добавим его в автозагрузку: ```[root@ipa ~]# systemctl enable chronyd```
- Выключим Firewall: ```[root@ipa ~]# systemctl stop firewalld```
- Отключаем автозапуск Firewalld: ```[root@ipa ~]# systemctl disable firewalld```
- Остановим Selinux: ```setenforce 0```
- Поменяем в файле /etc/selinux/config, параметр Selinux на disabled

```sh
[root@ipa ~]# vi /etc/selinux/config

# This file controls the state of SELinux on the system.
# SELINUX= can take one of these three values:
#     enforcing - SELinux security policy is enforced.
#     permissive - SELinux prints warnings instead of enforcing.
#     disabled - No SELinux policy is loaded.
SELINUX=disabled
# SELINUXTYPE= can take one of these three values:
#     targeted - Targeted processes are protected,
#     minimum - Modification of targeted policy. Only selected processes are protected.
#     mls - Multi Level Security protection.
SELINUXTYPE=targeted
```

- Для дальнейшей настройки FreeIPA нам потребуется, чтобы DNS-сервер хранил запись о нашем LDAP-сервере. В рамках данной лабораторной работы мы не будем настраивать отдельный DNS-сервер и просто добавим запись в файл /etc/hosts

```sh
[root@ipa ~]# vi /etc/hosts

127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
127.0.1.1 ipa.otus.lan ipa
192.168.56.10 ipa.otus.lan ipa
```

- Установим модуль DL1: ```[root@ipa ~]# yum install -y @idm:DL1```
- Установим FreeIPA-сервер: ```[root@ipa ~]# yum install -y ipa-server```
- Запустим скрипт установки: ```ipa-server-install```

```sh
[root@ipa ~]# ipa-server-install

The log file for this installation can be found in /var/log/ipaserver-install.log
==============================================================================
This program will set up the IPA Server.
Version 4.9.6

This includes:
  * Configure a stand-alone CA (dogtag) for certificate management
  * Configure the NTP client (chronyd)
  * Create and configure an instance of Directory Server
  * Create and configure a Kerberos Key Distribution Center (KDC)
  * Configure Apache (httpd)
  * Configure SID generation
  * Configure the KDC to enable PKINIT

To accept the default shown in brackets, press the Enter key.

Do you want to configure integrated DNS (BIND)? [no]: no

Enter the fully qualified domain name of the computer
on which you're setting up server software. Using the form
<hostname>.<domainname>
Example: master.example.com.


Server host name [ipa.otus.lan]: 

The domain name has been determined based on the host name.

Please confirm the domain name [otus.lan]: 

The kerberos protocol requires a Realm name to be defined.
This is typically the domain name converted to uppercase.

Please provide a realm name [OTUS.LAN]: 
Certain directory server operations require an administrative user.
This user is referred to as the Directory Manager and has full access
to the Directory for system management tasks and will be added to the
instance of directory server created for IPA.
The password must be at least 8 characters long.

Directory Manager password: 
Password (confirm): 

The IPA server requires an administrative user, named 'admin'.
This user is a regular system account used for IPA server administration.

IPA admin password: 
Password (confirm): 

Invalid IP address 127.0.1.1 for ipa.otus.lan: cannot use loopback IP address 127.0.1.1
Trust is configured but no NetBIOS domain name found, setting it now.
Enter the NetBIOS name for the IPA domain.
Only up to 15 uppercase ASCII letters, digits and dashes are allowed.
Example: EXAMPLE.


NetBIOS domain name [OTUS]: 

Do you want to configure chrony with NTP server or pool address? [no]: no

The IPA Master Server will be configured with:
Hostname:       ipa.otus.lan
IP address(es): 192.168.56.10
Domain name:    otus.lan
Realm name:     OTUS.LAN

The CA will be configured with:
Subject DN:   CN=Certificate Authority,O=OTUS.LAN
Subject base: O=OTUS.LAN
Chaining:     self-signed

Continue to configure the system with these values? [no]: yes
```

После успешной установки FreeIPA, проверим, что сервер Kerberos может выдать нам билет:

```sh
[root@ipa ~]# kinit admin
Password for admin@OTUS.LAN: 
[root@ipa ~]# klist
Ticket cache: KCM:0
Default principal: admin@OTUS.LAN

Valid starting       Expires              Service principal
08/19/2025 15:03:28  08/20/2025 14:18:36  krbtgt/OTUS.LAN@OTUS.LAN
```

Мы можем зайти в Web-интерфейс нашего FreeIPA-сервера, для этого на нашей хостой машине нужно прописать следующую строку в файле Hosts:
```192.168.56.10 ipa.otus.lan```

После добавления DNS-записи откроем c нашей хост-машины веб-страницу https://ipa.otus.lan/ipa/ui/#/e/user/search 

![image 1](https://github.com/IvanPrivalov/Otus_HomeWork/blob/main/Home%20work%2026/screens/Screenshot_01.png)

## Ansible playbook для конфигурации клиента

Запускаем Ansible playbook командой:

```sh
ansible-playbook clients.yml
```

Давайте проверим работу LDAP, для этого на сервере FreeIPA создадим пользователя и попробуем залогиниться к клиенту:
- Авторизируемся на сервере: ```kinit admin```
- Создадим пользователя otus-user

```sh
[root@ipa ~]# ipa user-add otus-user --first=Otus --last=User --password
Password: 
Enter Password again to verify: 
----------------------
Added user "otus-user"
----------------------
  User login: otus-user
  First name: Otus
  Last name: User
  Full name: Otus User
  Display name: Otus User
  Initials: OU
  Home directory: /home/otus-user
  GECOS: Otus User
  Login shell: /bin/sh
  Principal name: otus-user@OTUS.LAN
  Principal alias: otus-user@OTUS.LAN
  User password expiration: 20250819125444Z
  Email address: otus-user@otus.lan
  UID: 1790200003
  GID: 1790200003
  Password: True
  Member of groups: ipausers
  Kerberos keys available: True
```

![image 2](https://github.com/IvanPrivalov/Otus_HomeWork/blob/main/Home%20work%2026/screens/Screenshot_02.png)

На хосте client1 или client2 выполним команду ```kinit otus-user```

```sh
[root@client1 ~]# kinit otus-user
Password for otus-user@OTUS.LAN: 
Password expired.  You must change it now.
Enter new password: 
Enter it again: 
[root@client1 ~]# su otus-user
sh-4.4$ whoami
otus-user
sh-4.4$
```

```sh
[root@client2 ~]# kinit otus-user
Password for otus-user@OTUS.LAN: 
[root@client2 ~]# whoami
root
[root@client2 ~]# su otus-user
sh-4.4$ whoami
otus-user
sh-4.4$
```

На этом процесс добавления хостов к FreeIPA-серверу завершен.