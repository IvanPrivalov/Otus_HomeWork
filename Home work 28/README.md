## Репликация mysql
____

### Цель домашнего задания:

Поработать с реаликацией MySQL.

### Описание домашнего задания:

Развернуть базу из дампа и настроить репликацию Цель: В результате выполнения ДЗ студент развернет базу из дампа и настроит репликацию. В материалах приложены ссылки на вагрант для репликации и дамп базы bet.dmp Базу развернуть на мастере и настроить так, чтобы реплицировались таблицы: | bookmaker | | competition | | market | | odds | | outcome

   * Настроить GTID репликацию

варианты которые принимаются к сдаче:

   * рабочий вагрантафайл
   * скрины или логи SHOW TABLES * конфиги * пример в логе изменения строки и появления строки на реплике


## Выполнение:
____

Создадим Vagrantfile, в котором будут указаны параметры наших ВМ:

```sh
ENV['VAGRANT_SERVER_URL'] = 'http://vagrant.elab.pro'

Vagrant.configure(2) do |config|
  config.vm.box = "centos/7"
  
  config.vm.provider "virtualbox" do |v|
    v.memory = 1024
    v.cpus = 1
  end

  config.vm.define "master" do |server|
    server.vm.network "private_network", ip: "192.168.56.10"
    server.vm.hostname = "master"
  end

  config.vm.define "slave" do |client|
    client.vm.network "private_network", ip: "192.168.56.20"
    client.vm.hostname = "slave"
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
ssh-copy-id -i ~/.ssh/id_rsa.pub vagrant@192.168.56.20
```

Выполняем Ansible-playbook:

```sh
ansible-playbook mysql_repl.yml
```

## Проверка:
____

1. Подключиться к серверу master:

```sh
vagrant ssh master
```

    Вывести содержимое таблицы bookmaker:

```sh
mysql -e "use bet; select * from bookmaker;"
```

![image 1](https://github.com/IvanPrivalov/Otus_HomeWork/blob/main/Home%20work%2028/screens/Screenshot_01.png)

![image 2](https://github.com/IvanPrivalov/Otus_HomeWork/blob/main/Home%20work%2028/screens/Screenshot_02.png)


2. Добавить запись bet1 в таблицу bookmaker:

```sh
mysql -e "use bet; insert into bookmaker (id,bookmaker_name) values(1,'bet1');"
```

![image 3](https://github.com/IvanPrivalov/Otus_HomeWork/blob/main/Home%20work%2028/screens/Screenshot_03.png)


3. Подключиться к серверу slave:

```sh
vagrant ssh slave
```


4. Вывести содержимое таблицы bookmaker, убедившись, что новая запись в ней присутствует:

```sh
mysql -e "use bet; select * from bookmaker;"
```

![image 4](https://github.com/IvanPrivalov/Otus_HomeWork/blob/main/Home%20work%2028/screens/Screenshot_04.png)

