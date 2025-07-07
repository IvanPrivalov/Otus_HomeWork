## Vagrant-стенд c PXE
____

### Цель домашнего задания:

Отработать навыки установки и настройки DHCP, TFTP, PXE загрузчика и автоматической загрузки.

### Описание домашнего задания:

1. Настроить загрузку по сети дистрибутива centos 7
2. Установка должна проходить из HTTP-репозитория.
3. Настроить автоматическую установку c помощью файла user-data
*4. Настроить автоматическую загрузку по сети дистрибутива Ubuntu 24 c использованием UEFI

### Разворот хостов и настройка загрузки по сети
Подготовим Vagrantfile в котором будут описаны 2 виртуальные машины:
• pxeserver (хост к которому будут обращаться клиенты для установки ОС)
• pxeclient (хост, на котором будет проводиться установка)

```sh
ENV['VAGRANT_SERVER_URL'] = 'http://vagrant.elab.pro'


Vagrant.configure("2") do |config|
config.vm.define "pxeserver" do |server|
  config.vm.box = 'centos/7'
  config.vm.box_version = '1.0.0'
  server.vm.host_name = 'pxeserver'
  server.vm.network :private_network, 
                     ip: "10.0.0.20", 
                     virtualbox__intnet: 'pxenet'
  server.vm.provider "virtualbox" do |vb|
    vb.memory = "1024"
    vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
  end

  # ENABLE to setup PXE
  server.vm.provision "shell",
    name: "Setup PXE server",
    path: "setup_pxe.sh"
  end

config.vm.define "pxeclient" do |pxeclient|
    pxeclient.vm.box = 'centos/7'
    config.vm.box_version = '1.0.0'
    pxeclient.vm.host_name = 'pxeclient'
    pxeclient.vm.network :private_network, 
						  ip: "10.0.0.21", 
						  virtualbox__intnet: 'pxenet'
  pxeclient.vm.provider :virtualbox do |vb|
      vb.memory = "1024"
      vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
      vb.customize [
          'modifyvm', :id,
          '--nic1', 'intnet',
          '--intnet1', 'pxenet',
          '--nic2', 'nat',
          '--boot1', 'net',
          '--boot2', 'none',
          '--boot3', 'none',
          '--boot4', 'none'
        ]
    vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    end
  end
end
```

### Выполнение ДЗ
____

Копируем файлы в каталог и запускаем PXE сервер:

```sh
vagrant up pxeserver
```

После загрузки PXE сервера, запускаем клиент:

```sh
vagrant up pxeclient
```

В окне VirtualBox открываем консоль pxeclient, увидим загрузку по PXE

![image 1](https://github.com/IvanPrivalov/Otus_HomeWork/blob/main/Home%20work%2020/screens/Screenshot_01.png)

![image 2](https://github.com/IvanPrivalov/Otus_HomeWork/blob/main/Home%20work%2020/screens/Screenshot_02.png)

Выбираем Install System и запустится установка Centos 7

![image 3](https://github.com/IvanPrivalov/Otus_HomeWork/blob/main/Home%20work%2020/screens/Screenshot_03.png)