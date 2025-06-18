## Настройка мониторинга
____

### Цель домашнего задания:

Научиться настраивать дашборд.

### Описание домашнего задания:

Настроить дашборд с 4-мя графиками:

- память;
- процессор;
- диск;
- сеть.

Настроить на одной из систем:

- zabbix (использовать screen (комплексный экран);
- prometheus - grafana.

## Выполнение ДЗ
____

Необходимо запустить Vagrantfile командой ```vagrant up```

Будут созданы 2 виртуальные машины zabbix-server и zabbix-agent

zabbix-server с IP адресом 192.168.56.3
zabbix-agent с IP адресом 192.168.56.4

На zabbix-server с помощью скрипта ```/script/zabbix.sh```, автоматически установится Postgresql и Zabbix сервер, после установки необходимо подключиться к серверу http://192.168.56.3/zabbix и произвести базовые настройки.

На zabbix-agent с помощью скрипта ```/script/zabbix_agent.sh```, автоматически установится Zabbix agent 2 и астоматически пропишутся настройки Zabbix сервера в конфиг /etc/zabbix/zabbix_agent2.conf

Далее в интерфейсе Zabbix http://192.168.56.3/zabbix добавляем узел сети, добавляем шаблон:

![image 1](https://github.com/IvanPrivalov/Otus_HomeWork/blob/main/Home%20work%2015/screens/Screenshot_02.png)

После чего можно создавать панели с графиками:

![image 1](https://github.com/IvanPrivalov/Otus_HomeWork/blob/main/Home%20work%2015/screens/Screenshot_03.png)