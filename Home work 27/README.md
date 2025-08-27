## Динамический веб. Развертывание веб приложения
____

### Цель домашнего задания:

Получить практические навыки в настройке инфраструктуры с помощью манифестов и конфигураций. Отточить навыки использования ansible/vagrant/docker.

### Описание домашнего задания:

Варианты стенда:
nginx + php-fpm (laravel/wordpress) + python (flask/django) + js(react/angular);
nginx + java (tomcat/jetty/netty) + go + ruby;
можно свои комбинации.
Реализации на выбор:
на хостовой системе через конфиги в /etc;
деплой через docker-compose.
Для усложнения можно попросить проекты у коллег с курсов по разработке
К сдаче принимается:
vagrant стэнд с проброшенными на локалхост портами
каждый порт на свой сайт
через нжинкс Формат сдачи ДЗ - vagrant + ansible

## Выполнение:

Создадим Vagrantfile, в котором будут указаны параметры наших ВМ:

```sh
ENV['VAGRANT_SERVER_URL'] = 'http://vagrant.elab.pro'

Vagrant.configure(2) do |config|
  config.vm.box = "centos/7"
  
  config.vm.provider "virtualbox" do |v|
    v.memory = 2048
    v.cpus = 1
  end

  config.vm.define "web" do |server|
    server.vm.network "private_network", ip: "192.168.56.10"
    server.vm.hostname = "web"
  end

  config.vm.provision "shell", inline: <<-SHELL
        mkdir -p ~root/.ssh
        cp ~vagrant/.ssh/auth* ~root/.ssh
        sed -i 's/^PasswordAuthentication.*$/PasswordAuthentication yes/' /etc/ssh/sshd_config
        sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
        sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*
        systemctl restart sshd.service
      SHELL
end
```

Копируем файлы в каталог и запускаем Vagrantfile:

```sh
vagrant up
```

Когда виртуальные машины создадутся, необходимо скопировать сертификат с хостовой машины, выполнив команды:

```sh
ssh-copy-id -i ~/.ssh/id_rsa.pub vagrant@192.168.56.10
```

## Ansible-playbook разворачивает комбинацию nginx + php-fpm (laravel) + python (django) + js(react)

### Проверка:

1. Проверка:

php-fpm/laravel - http://192.168.56.10:10001/

![image 1](https://github.com/IvanPrivalov/Otus_HomeWork/blob/main/Home%20work%2027/screens/Screenshot_01.png)

http://192.168.56.10:10001/homework

![image 2](https://github.com/IvanPrivalov/Otus_HomeWork/blob/main/Home%20work%2027/screens/Screenshot_02.png)

uwsgi/django - http://192.168.56.10:10002/

![image 3](https://github.com/IvanPrivalov/Otus_HomeWork/blob/main/Home%20work%2027/screens/Screenshot_03.png)

nodejs/reactjs - http://192.168.56.10:10003/

![image 4](https://github.com/IvanPrivalov/Otus_HomeWork/blob/main/Home%20work%2027/screens/Screenshot_04.png)