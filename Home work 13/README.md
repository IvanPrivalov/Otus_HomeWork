## Vagrant-стенд для обновления ядра и создания образа системы
____

### Цель домашнего задания:

Научиться обновлять ядро в ОС Linux. Получение навыков работы с Vagrant.

### Описание домашнего задания:

1) Запустить ВМ с помощью Vagrant.
2) Обновить ядро ОС из репозитория ELRepo.
3) Оформить отчет в README-файле в GitHub-репозитории.

#### Запустить ВМ с помощью Vagrant.

Создадим Vagrantfile, в котором будут указаны параметры нашей ВМ:

```sh
ENV['VAGRANT_SERVER_URL'] = 'http://vagrant.elab.pro'


MACHINES = {
  :"kernel-update" => {
              :box_name => "centos/8",
              :box_version => "1.0.0",
              :cpus => 2,
              :memory => 1024,
            }
}

Vagrant.configure("2") do |config|
  MACHINES.each do |boxname, boxconfig|
    config.vm.synced_folder ".", "/vagrant", disabled: true
    config.vm.define boxname do |box|
      box.vm.box = boxconfig[:box_name]
      box.vm.box_version = boxconfig[:box_version]
      box.vm.host_name = boxname.to_s
      box.vm.provider "virtualbox" do |v|
        v.memory = boxconfig[:memory]
        v.cpus = boxconfig[:cpus]
      end
    end
  end
end
```

После создания Vagrantfile, запустим виртуальную машину командой ```vagrant up```
Будет создана виртуальная машина с ОС CentOS 8 Stream, с 2-мя ядрами CPU и 1ГБ ОЗУ.

```sh
ivan@ivan-Otus:~/Desktop/Otus_HomeWork/Home work 13$ vagrant ssh
[vagrant@kernel-update ~]$ uname
Linux
[vagrant@kernel-update ~]$ uname -a
Linux kernel-update 4.18.0-240.1.1.el8_3.x86_64 #1 SMP Thu Nov 19 17:20:08 UTC 2020 x86_64 x86_64 x86_64 GNU/Linux
[vagrant@kernel-update ~]$ cat /etc/*-release
CentOS Linux release 8.3.2011
NAME="CentOS Linux"
VERSION="8"
ID="centos"
ID_LIKE="rhel fedora"
VERSION_ID="8"
PLATFORM_ID="platform:el8"
PRETTY_NAME="CentOS Linux 8"
ANSI_COLOR="0;31"
CPE_NAME="cpe:/o:centos:centos:8"
HOME_URL="https://centos.org/"
BUG_REPORT_URL="https://bugs.centos.org/"
CENTOS_MANTISBT_PROJECT="CentOS-8"
CENTOS_MANTISBT_PROJECT_VERSION="8"
CentOS Linux release 8.3.2011
CentOS Linux release 8.3.2011
```

#### Обновление ядра

Подключаемся по ssh к созданной виртуальной машины. Для этого в каталоге с нашим Vagrantfile вводим команду ```vagrant ssh```
Перед работами проверим текущую версию ядра:

```sh
[vagrant@kernel-update ~]$ uname -r
4.18.0-240.1.1.el8_3.x86_64
```

Далее подключим репозиторий, откуда возьмём необходимую версию ядра:

```sh
[root@kernel-update ~]# sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
[root@kernel-update ~]# sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*
[root@kernel-update ~]# yum install -y https://www.elrepo.org/elrepo-release-8.el8.elrepo.noarch.rpm
CentOS Linux 8 - AppStream                                                                                                                              7.0 MB/s | 8.4 MB     00:01    
CentOS Linux 8 - BaseOS                                                                                                                                 3.8 MB/s | 4.6 MB     00:01    
CentOS Linux 8 - Extras                                                                                                                                  16 kB/s |  10 kB     00:00    
elrepo-release-8.el8.elrepo.noarch.rpm                                                                                                                   17 kB/s |  19 kB     00:01    
Dependencies resolved.
========================================================================================================================================================================================
 Package                                       Architecture                          Version                                          Repository                                   Size
========================================================================================================================================================================================
Installing:
 elrepo-release                                noarch                                8.4-2.el8.elrepo                                 @commandline                                 19 k

Transaction Summary
========================================================================================================================================================================================
Install  1 Package

Total size: 19 k
Installed size: 8.3 k
Downloading Packages:
Running transaction check
Transaction check succeeded.
Running transaction test
Transaction test succeeded.
Running transaction
  Preparing        :                                                                                                                                                                1/1 
  Installing       : elrepo-release-8.4-2.el8.elrepo.noarch                                                                                                                         1/1 
  Verifying        : elrepo-release-8.4-2.el8.elrepo.noarch                                                                                                                         1/1 

Installed:
  elrepo-release-8.4-2.el8.elrepo.noarch                                                                                                                                                

Complete!
```

Установим последнее ядро из репозитория elrepo-kernel:

```sh
[root@kernel-update ~]# yum --enablerepo elrepo-kernel install kernel-ml -y
ELRepo.org Community Enterprise Linux Kernel Repository - el8                                                                                           1.0 MB/s | 2.2 MB     00:02    
Last metadata expiration check: 0:00:01 ago on Wed 14 May 2025 05:33:47 AM UTC.
Dependencies resolved.
========================================================================================================================================================================================
 Package                                        Architecture                        Version                                            Repository                                  Size
========================================================================================================================================================================================
Installing:
 kernel-ml                                      x86_64                              6.14.6-1.el8.elrepo                                elrepo-kernel                              150 k
Installing dependencies:
 kernel-ml-core                                 x86_64                              6.14.6-1.el8.elrepo                                elrepo-kernel                               66 M
 kernel-ml-modules                              x86_64                              6.14.6-1.el8.elrepo                                elrepo-kernel                               62 M

Transaction Summary
========================================================================================================================================================================================
Install  3 Packages

Total download size: 128 M
Installed size: 174 M
Downloading Packages:
(1/3): kernel-ml-6.14.6-1.el8.elrepo.x86_64.rpm                                                                                                         351 kB/s | 150 kB     00:00    
(2/3): kernel-ml-modules-6.14.6-1.el8.elrepo.x86_64.rpm                                                                                                 7.8 MB/s |  62 MB     00:07    
(3/3): kernel-ml-core-6.14.6-1.el8.elrepo.x86_64.rpm                                                                                                    3.0 MB/s |  66 MB     00:22    
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Total                                                                                                                                                   5.7 MB/s | 128 MB     00:22     
warning: /var/cache/dnf/elrepo-kernel-e80375c2d5802dd1/packages/kernel-ml-6.14.6-1.el8.elrepo.x86_64.rpm: Header V4 RSA/SHA256 Signature, key ID eaa31d4a: NOKEY
ELRepo.org Community Enterprise Linux Kernel Repository - el8                                                                                           983 kB/s | 1.7 kB     00:00    
Importing GPG key 0xBAADAE52:
 Userid     : "elrepo.org (RPM Signing Key for elrepo.org) <secure@elrepo.org>"
 Fingerprint: 96C0 104F 6315 4731 1E0B B1AE 309B C305 BAAD AE52
 From       : /etc/pki/rpm-gpg/RPM-GPG-KEY-elrepo.org
Key imported successfully
ELRepo.org Community Enterprise Linux Kernel Repository - el8                                                                                           1.1 MB/s | 3.1 kB     00:00    
Importing GPG key 0xEAA31D4A:
 Userid     : "elrepo.org (RPM Signing Key v2 for elrepo.org) <secure@elrepo.org>"
 Fingerprint: B8A7 5587 4DA2 40C9 DAC4 E715 5160 0989 EAA3 1D4A
 From       : /etc/pki/rpm-gpg/RPM-GPG-KEY-v2-elrepo.org
Key imported successfully
Running transaction check
Transaction check succeeded.
Running transaction test
Transaction test succeeded.
Running transaction
  Preparing        :                                                                                                                                                                1/1 
  Installing       : kernel-ml-core-6.14.6-1.el8.elrepo.x86_64                                                                                                                      1/3 
  Running scriptlet: kernel-ml-core-6.14.6-1.el8.elrepo.x86_64                                                                                                                      1/3 
  Installing       : kernel-ml-modules-6.14.6-1.el8.elrepo.x86_64                                                                                                                   2/3 
  Running scriptlet: kernel-ml-modules-6.14.6-1.el8.elrepo.x86_64                                                                                                                   2/3 
  Installing       : kernel-ml-6.14.6-1.el8.elrepo.x86_64                                                                                                                           3/3 
  Running scriptlet: kernel-ml-core-6.14.6-1.el8.elrepo.x86_64                                                                                                                      3/3 
dracut: Disabling early microcode, because kernel does not support it. CONFIG_MICROCODE_[AMD|INTEL]!=y

  Running scriptlet: kernel-ml-6.14.6-1.el8.elrepo.x86_64                                                                                                                           3/3 
  Verifying        : kernel-ml-6.14.6-1.el8.elrepo.x86_64                                                                                                                           1/3 
  Verifying        : kernel-ml-core-6.14.6-1.el8.elrepo.x86_64                                                                                                                      2/3 
  Verifying        : kernel-ml-modules-6.14.6-1.el8.elrepo.x86_64                                                                                                                   3/3 

Installed:
  kernel-ml-6.14.6-1.el8.elrepo.x86_64                    kernel-ml-core-6.14.6-1.el8.elrepo.x86_64                    kernel-ml-modules-6.14.6-1.el8.elrepo.x86_64                   

Complete!
```

Обновить конфигурацию загрузчика:

```sh
[root@kernel-update ~]# grub2-mkconfig -o /boot/grub2/grub.cfg
Generating grub configuration file ...
done
```

Выбрать загрузку нового ядра по-умолчанию:

```sh
[root@kernel-update ~]# grub2-set-default 0
```

Далее перезагружаем нашу виртуальную машину с помощью команды ```sudo reboot```

После перезагрузки снова проверяем версию ядра (версия должна стать новее):

```sh
[root@kernel-update ~]# reboot
Connection to 127.0.0.1 closed by remote host.
ivan@ivan-Otus:~/Desktop/Otus_HomeWork/Home work 13$ vagrant ssh
Last login: Wed May 14 05:25:22 2025 from 10.0.2.2
[vagrant@kernel-update ~]$ uname -r
6.14.6-1.el8.elrepo.x86_64
```
