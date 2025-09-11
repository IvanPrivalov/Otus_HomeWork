## PostgreSQL: репликация и backup
____

### Цель домашнего задания:

Поработать с PostgreSQL репликацей и backup.

### Описание домашнего задания:

1. Настроить hot_standby репликацию с использованием слотов
2. Настроить правильное резервное копирование

## Выполнение:
____

Создадим Vagrantfile, в котором будут указаны параметры наших ВМ:

```sh
ENV['VAGRANT_SERVER_URL'] = 'http://vagrant.elab.pro'

Vagrant.configure(2) do |config|
  config.vm.box = "ubuntu/jammy64"
  
  config.vm.provider "virtualbox" do |v|
    v.memory = 1024
    v.cpus = 1
  end

  config.vm.define "node1" do |server|
    server.vm.network "private_network", ip: "192.168.56.11"
    server.vm.hostname = "node1"
  end

  config.vm.define "node2" do |server|
    server.vm.network "private_network", ip: "192.168.56.12"
    server.vm.hostname = "node2"
  end

  config.vm.define "barman" do |client|
    client.vm.network "private_network", ip: "192.168.56.13"
    client.vm.hostname = "barman"
  end

      config.vm.provision "shell", inline: <<-SHELL
         timedatectl set-timezone Europe/Moscow
         mkdir -p ~root/.ssh
         cp ~vagrant/.ssh/auth* ~root/.ssh
         sed -i 's/^PasswordAuthentication.*$/PasswordAuthentication yes/' /etc/ssh/sshd_config
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
ssh-copy-id -i ~/.ssh/id_rsa.pub vagrant@192.168.56.11
ssh-copy-id -i ~/.ssh/id_rsa.pub vagrant@192.168.56.12
ssh-copy-id -i ~/.ssh/id_rsa.pub vagrant@192.168.56.13
```

Выполняем Ansible-playbook:

```sh
ansible-playbook pg.yml
```

## Проверка:
____

### На хосте node1:

Создадим тестовую базу и убедимся в начале репликации

```sh
vagrant@node1:~$ sudo -u postgres psql
postgres=# \l
                              List of databases
   Name    |  Owner   | Encoding | Collate |  Ctype  |   Access privileges   
-----------+----------+----------+---------+---------+-----------------------
 otus      | postgres | UTF8     | C.UTF-8 | C.UTF-8 | 
 postgres  | postgres | UTF8     | C.UTF-8 | C.UTF-8 | 
 template0 | postgres | UTF8     | C.UTF-8 | C.UTF-8 | =c/postgres          +
           |          |          |         |         | postgres=CTc/postgres
 template1 | postgres | UTF8     | C.UTF-8 | C.UTF-8 | =c/postgres          +
           |          |          |         |         | postgres=CTc/postgres
(4 rows)

postgres=# CREATE DATABASE otus_test;
CREATE DATABASE

postgres=# \l
                              List of databases
   Name    |  Owner   | Encoding | Collate |  Ctype  |   Access privileges   
-----------+----------+----------+---------+---------+-----------------------
 otus      | postgres | UTF8     | C.UTF-8 | C.UTF-8 | 
 otus_test | postgres | UTF8     | C.UTF-8 | C.UTF-8 | 
 postgres  | postgres | UTF8     | C.UTF-8 | C.UTF-8 | 
 template0 | postgres | UTF8     | C.UTF-8 | C.UTF-8 | =c/postgres          +
           |          |          |         |         | postgres=CTc/postgres
 template1 | postgres | UTF8     | C.UTF-8 | C.UTF-8 | =c/postgres          +
           |          |          |         |         | postgres=CTc/postgres
(5 rows)

postgres=# select * from pg_stat_replication;

-[ RECORD 1 ]----+------------------------------
pid              | 7428
usesysid         | 16384
usename          | replication
application_name | walreceiver
client_addr      | 192.168.56.12
client_hostname  | 
client_port      | 38170
backend_start    | 2025-09-11 04:09:54.929774-03
backend_xmin     | 738
state            | streaming
sent_lsn         | 0/4000AF0
write_lsn        | 0/4000AF0
flush_lsn        | 0/4000AF0
replay_lsn       | 0/4000AF0
write_lag        | 
flush_lag        | 
replay_lag       | 
sync_priority    | 0
sync_state       | async
reply_time       | 2025-09-11 04:22:11.438441-03
```

### На хосте node2:

Убеждаемся в успешной репликации созданной БД: 

```sh
vagrant@node2:~$ sudo -u postgres psql
could not change directory to "/home/vagrant": Permission denied
psql (14.19 (Ubuntu 14.19-0ubuntu0.22.04.1))
Type "help" for help.

postgres=# \l
                              List of databases
   Name    |  Owner   | Encoding | Collate |  Ctype  |   Access privileges   
-----------+----------+----------+---------+---------+-----------------------
 otus      | postgres | UTF8     | C.UTF-8 | C.UTF-8 | 
 otus_test | postgres | UTF8     | C.UTF-8 | C.UTF-8 | 
 postgres  | postgres | UTF8     | C.UTF-8 | C.UTF-8 | 
 template0 | postgres | UTF8     | C.UTF-8 | C.UTF-8 | =c/postgres          +
           |          |          |         |         | postgres=CTc/postgres
 template1 | postgres | UTF8     | C.UTF-8 | C.UTF-8 | =c/postgres          +
           |          |          |         |         | postgres=CTc/postgres
(5 rows)

postgres=# select * from pg_stat_wal_receiver;

-[ RECORD 1 ]---------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
pid                   | 7306
status                | streaming
receive_start_lsn     | 0/3000000
receive_start_tli     | 1
written_lsn           | 0/4000BD8
flushed_lsn           | 0/4000BD8
received_tli          | 1
last_msg_send_time    | 2025-09-11 04:24:06.063379-03
last_msg_receipt_time | 2025-09-11 04:24:06.058276-03
latest_end_lsn        | 0/4000BD8
latest_end_time       | 2025-09-11 04:22:35.842912-03
slot_name             | 
sender_host           | 192.168.56.11
sender_port           | 5432
conninfo              | user=replication password=******** channel_binding=prefer dbname=replication host=192.168.56.11 port=5432 fallback_application_name=walreceiver sslmode=prefer sslcompression=0 sslsni=1 ssl_min_protocol_version=TLSv1.2 gssencmode=prefer krbsrvname=postgres target_session_attrs=any
```

## Резервное копирование c помощью barman
____

Создание тестовой БД с таблицей:

```sh
postgres=#  CREATE DATABASE otus;
CREATE DATABASE
postgres=# \c otus;
You are now connected to database "otus" as user "postgres".

otus=# CREATE TABLE test (id int, name varchar(30));
CREATE TABLE
otus=# INSERT INTO test VALUES (1, 'alex');
INSERT 0 1
```

Теперь проверим работу barman:

```sh
barman@barman:~$ barman switch-wal node1
The WAL file 000000010000000000000004 has been closed on server 'node1'
barman@barman:~$ barman cron
Starting WAL archiving for server node1
```

Запускаем резервную копию:

```sh
barman@barman:~$ barman backup node1
Starting backup using postgres method for server node1 in /var/lib/barman/node1/base/20250911T120608
Backup start at LSN: 0/5000148 (000000010000000000000005, 00000148)
Starting backup copy via pg_basebackup for 20250911T120608
WARNING: pg_basebackup does not copy the PostgreSQL configuration files that reside outside PGDATA. Please manually backup the following files:
	/etc/postgresql/14/main/postgresql.conf
	/etc/postgresql/14/main/pg_hba.conf
	/etc/postgresql/14/main/pg_ident.conf

Copy done (time: 4 seconds)
Finalising the backup.
This is the first backup for server node1
WAL segments preceding the current backup have been found:
	000000010000000000000004 from server node1 has been removed
Backup size: 41.8 MiB
Backup end at LSN: 0/7000000 (000000010000000000000006, 00000000)
Backup completed (start time: 2025-09-11 12:06:08.120196, elapsed time: 4 seconds)
Processing xlog segments from streaming for node1
	000000010000000000000005
WARNING: IMPORTANT: this backup is classified as WAITING_FOR_WALS, meaning that Barman has not received yet all the required WAL files for the backup consistency.
This is a common behaviour in concurrent backup scenarios, and Barman automatically set the backup as DONE once all the required WAL files have been archived.
Hint: execute the backup command with '--wait'
```

Убеждаемся, что все в порядке:

```sh
barman@barman:~$ barman check node1
Server node1:
	PostgreSQL: OK
	superuser or standard user with backup privileges: OK
	PostgreSQL streaming: OK
	wal_level: OK
	replication slot: OK
	directories: OK
	retention policy settings: OK
	backup maximum age: OK (interval provided: 4 days, latest backup age: 1 minute, 57 seconds)
	backup minimum size: OK (41.8 MiB)
	wal maximum age: OK (no last_wal_maximum_age provided)
	wal size: OK (0 B)
	compression settings: OK
	failed backups: OK (there are 0 failed backups)
	minimum redundancy requirements: OK (have 1 backups, expected at least 1)
	pg_basebackup: OK
	pg_basebackup compatible: OK
	pg_basebackup supports tablespaces mapping: OK
	systemid coherence: OK
	pg_receivexlog: OK
	pg_receivexlog compatible: OK
	receive-wal running: OK
	archiver errors: OK
```

### На хосте node1:

Для проверки удалим базы otus и otus_test: 

```sh
postgres=# \l
                              List of databases
   Name    |  Owner   | Encoding | Collate |  Ctype  |   Access privileges   
-----------+----------+----------+---------+---------+-----------------------
 otus      | postgres | UTF8     | C.UTF-8 | C.UTF-8 | 
 otus_test | postgres | UTF8     | C.UTF-8 | C.UTF-8 | 
 postgres  | postgres | UTF8     | C.UTF-8 | C.UTF-8 | 
 template0 | postgres | UTF8     | C.UTF-8 | C.UTF-8 | =c/postgres          +
           |          |          |         |         | postgres=CTc/postgres
 template1 | postgres | UTF8     | C.UTF-8 | C.UTF-8 | =c/postgres          +
           |          |          |         |         | postgres=CTc/postgres
(5 rows)

postgres=# DROP DATABASE otus;
DROP DATABASE
postgres=# DROP DATABASE otus_test;
DROP DATABASE
```

### На хосте barman:

Посмотрим список доступных архивов 

```sh
barman@barman:~$ barman list-backup node1
node1 20250911T120608 - Thu Sep 11 06:06:12 2025 - Size: 41.8 MiB - WAL Size: 0 B - WAITING_FOR_WALS
```

Восстановим сервер node1: 

```sh
barman@barman:~$ barman recover node1 20250911T120608 /var/lib/postgresql/14/main/ --remote-ssh-command "ssh postgres@192.168.56.11"
The authenticity of host '192.168.56.11 (192.168.56.11)' can't be established.
ED25519 key fingerprint is SHA256:qV7DRzMRBBAOFymCf720v3yisrzS8+ffpOb2o27zzms.
This key is not known by any other names
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Starting remote restore for server node1 using backup 20250911T120608
Destination directory: /var/lib/postgresql/14/main/
Remote command: ssh postgres@192.168.56.11
WARNING: IMPORTANT: You have requested a recovery operation for a backup that does not have yet all the WAL files that are required for consistency.
Copying the base backup.
WARNING: IMPORTANT: The backup we have recovered IS NOT VALID. Required WAL files for consistency are missing. Please verify that WAL archiving is working correctly or evaluate using the 'get-wal' option for recovery
Copying required WAL segments.
Generating archive status files
Identify dangerous settings in destination directory.

WARNING
The following configuration files have not been saved during backup, hence they have not been restored.
You need to manually restore them in order to start the recovered PostgreSQL instance:

    postgresql.conf
    pg_hba.conf
    pg_ident.conf

Recovery completed (start time: 2025-09-11 12:13:50.509940, elapsed time: 41 seconds)

Your PostgreSQL server has been successfully prepared for recovery!
```

### На хосте node1:

Нужно перезапустить postgres, после этого убеждаемся, что базы восстановлены: 

```sh
vagrant@node1:~$ sudo -i
root@node1:~# systemctl restart postgresql
root@node1:~# su postgres
postgres@node1:/root$ psql
could not change directory to "/root": Permission denied
psql (14.19 (Ubuntu 14.19-0ubuntu0.22.04.1))
Type "help" for help.

postgres=# \l
                              List of databases
   Name    |  Owner   | Encoding | Collate |  Ctype  |   Access privileges   
-----------+----------+----------+---------+---------+-----------------------
 otus      | postgres | UTF8     | C.UTF-8 | C.UTF-8 | 
 otus_test | postgres | UTF8     | C.UTF-8 | C.UTF-8 | 
 postgres  | postgres | UTF8     | C.UTF-8 | C.UTF-8 | 
 template0 | postgres | UTF8     | C.UTF-8 | C.UTF-8 | =c/postgres          +
           |          |          |         |         | postgres=CTc/postgres
 template1 | postgres | UTF8     | C.UTF-8 | C.UTF-8 | =c/postgres          +
           |          |          |         |         | postgres=CTc/postgres
(5 rows)
```