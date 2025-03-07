## Обновление ядра
____

### Задание

Обновление ядра системы

### Запустить ВМ c Ubuntu.

Запускаем виртуальную машину из каталога с нашим Vagrantfile, выполнив команду:

```sh
vagrant up
```

Подключаемся по ssh к созданной виртуальной машине. Для этого в каталоге с нашим Vagrantfile вводим команду:

```sh
vagrant ssh
```

Перед работами проверим текущую версию ядра:

```sh
ivan@ivan-Otus:~/Desktop/Otus_HomeWork/Home work 1$ vagrant ssh
[vagrant@kernel-update ~]$ uname -r
4.18.0-240.1.1.el8_3.x86_64
```

Далее подключим репозиторий, откуда возьмём необходимую версию ядра:

```sh
[vagrant@kernel-update ~]$ sudo sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
[vagrant@kernel-update ~]$ sudo sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*
[vagrant@kernel-update ~]$ sudo yum install -y https://www.elrepo.org/elrepo-release-8.el8.elrepo.noarch.rpm
```

В репозитории есть две версии ядер:
- kernel-ml — свежие и стабильные ядра
- kernel-lt — стабильные ядра с длительной версией поддержки, более старые, чем версия ml.

Установим последнее ядро из репозитория elrepo-kernel:

```sh
[vagrant@kernel-update ~]$ sudo yum --enablerepo elrepo-kernel install kernel-ml -y
```

Обновить конфигурацию загрузчика:

```sh
[vagrant@kernel-update ~]$ sudo grub2-mkconfig -o /boot/grub2/grub.cfg
Generating grub configuration file ...
done
```

Выбрать загрузку нового ядра по-умолчанию:

```sh
[vagrant@kernel-update ~]$ sudo grub2-set-default 0
```

Перезагружаем виртуальную машину с помощью команды:

```sh
sudo reboot
```

После перезагрузки проверяем версию ядра:

```sh
[vagrant@kernel-update ~]$ uname -r
6.13.5-1.el8.elrepo.x86_64
```