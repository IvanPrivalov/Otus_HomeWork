## Первые шаги с Ansible.
____

### Описание домашнего задания:

Подготовить стенд на Vagrant как минимум с одним сервером. На этом сервере, используя Ansible необходимо развернуть nginx со следующими условиями:
1. необходимо использовать модуль yum/apt
2. конфигурационный файлы должны быть взяты из шаблона jinja2 с переменными
3. после установки nginx должен быть в режиме enabled в systemd
4. должен быть использован notify для старта nginx после установки
5. сайт должен слушать на нестандартном порту - 8080, для этого использовать переменные в Ansible
* Сделать все это с использованием Ansible роли

### Подготовка окружения 

- В каталоге Ansible создан Vagrantfile
- Поднимите управляемый хост командой ```vagrant up``` и убедитесь, что все прошло успешно и есть доступ по ```ssh```
```sh
ivan@ivan-Otus:~/Desktop/Otus_HomeWork/Home work 12/Ansible$ vagrant ssh
Welcome to Ubuntu 22.04.2 LTS (GNU/Linux 5.15.0-71-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage

  System information as of Tue May  6 05:50:58 UTC 2025

  System load:  0.080078125       Processes:               88
  Usage of /:   3.7% of 38.70GB   Users logged in:         0
  Memory usage: 26%               IPv4 address for enp0s3: 10.0.2.15
  Swap usage:   0%                IPv4 address for enp0s8: 192.168.11.150


Expanded Security Maintenance for Applications is not enabled.

0 updates can be applied immediately.

Enable ESM Apps to receive additional future security updates.
See https://ubuntu.com/esm or run: sudo pro status


The list of available updates is more than a week old.
To check for new updates run: sudo apt update
New release '24.04.2 LTS' available.
Run 'do-release-upgrade' to upgrade to it.
```

- Для подключения к хосту ```nginx``` нам необходимо будет передать множество параметров - это особенность Vagrant. 
Узнать эти параметры можно с помощью команды ```vagrant ssh-config```. Вот основные необходимые нам:

```sh
ivan@ivan-Otus:~/Desktop/Otus_HomeWork/Home work 12/Ansible$ vagrant ssh-config
Host nginx
  HostName 127.0.0.1
  User vagrant
  Port 2222
  UserKnownHostsFile /dev/null
  StrictHostKeyChecking no
  PasswordAuthentication no
  IdentityFile "/home/ivan/Desktop/Otus_HomeWork/Home work 12/Ansible/.vagrant/machines/nginx/virtualbox/private_key"
  IdentitiesOnly yes
  LogLevel FATAL
  PubkeyAcceptedKeyTypes +ssh-rsa
  HostKeyAlgorithms +ssh-rsa
```

### Ansible

Создадим свой первый inventory файл ./staging/hosts
Со следующим содержимым:

```sh
nginx ansible_host=127.0.0.1 ansible_port=2222 ansible_user='vagrant' ansible_private_key_file='/home/ivan/Desktop/Otus_HomeWork/Home work 12/Ansible/.vagrant/machines/nginx/virtualbox/private_key'
```

Убедимся, что Ansible может управлять нашим хостом. Сделать это можно с помощью команды: ```ansible nginx -i staging/hosts -m ping```

```sh
ivan@ivan-Otus:~/Desktop/Otus_HomeWork/Home work 12/Ansible$ ansible nginx -i staging/hosts -m ping
The authenticity of host '[127.0.0.1]:2222 ([127.0.0.1]:2222)' can't be established.
ED25519 key fingerprint is SHA256:LyOTTHHQFgZZm9gTb9/J9Qw7zmNkYXLtobEPPntSbHg.
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])? y
Please type 'yes', 'no' or the fingerprint: yes
nginx | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
```

Как видно, нам придется каждый раз явно указывать наш инвентори файл и вписывать в него много информации. Это можно обойти используя ansible.cfg файл - прописав конфигурацию в нем.
- Для этого в текущем каталоге создадим файл ansible.cfg со следующим содержанием:

```sh
[defaults]
inventory = staging/hosts
remote_user = vagrant
host_key_checking = False
retry_files_enabled = False
```

- Теперь из инвентори можно убрать информацию о пользователе:

```sh
nginx ansible_host=127.0.0.1 ansible_port=2222 ansible_private_key_file='/home/ivan/Desktop/Otus_HomeWork/Home work 12/Ansible/.vagrant/machines/nginx/virtualbox/private_key'
```

Еще раз убедимся, что управляемый хост доступе, только теперь без явного указаниā inventory файла:

```sh
ivan@ivan-Otus:~/Desktop/Otus_HomeWork/Home work 12/Ansible$ ansible nginx -m ping
nginx | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
```

- Теперь, когда мы убедились, что у нас все подготовлено - установлен Ansible, поднят хост для теста и Ansible имеет к нему доступ, мы можем конфигурировать наш хост. Для начала воспользуемся Ad-Hoc командами и выполним некоторые удаленные команды на нашем хосте.

Посмотрим какое ядро установлено на хосте:

```sh
ivan@ivan-Otus:~/Desktop/Otus_HomeWork/Home work 12/Ansible$ ansible nginx -m command -a "uname -r"
nginx | CHANGED | rc=0 >>
5.15.0-71-generic
```

Проверим статус сервиса firewalld:

```sh
ivan@ivan-Otus:~/Desktop/Otus_HomeWork/Home work 12/Ansible$ ansible nginx -m systemd -a name=firewalld
nginx | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "name": "firewalld",
    "status": {
        "ActiveEnterTimestamp": "n/a",
        "ActiveEnterTimestampMonotonic": "0",
        "ActiveExitTimestamp": "n/a",
        "ActiveExitTimestampMonotonic": "0",
        "ActiveState": "inactive",
```

Создадим playbook nginx.yml для установки NGINX

```sh
ivan@ivan-Otus:~/Desktop/Otus_HomeWork/Home work 12/Ansible$ cat nginx.yml 
---
- name: NGINX | Install and configure NGINX
  hosts: nginx
  become: true

  tasks:
    - name: update
      apt:
        update_cache=yes
    
    - name: NGINX | Install NGINX
      apt:
        name: nginx
        state: latest
```

Установим NGINX

```sh
ivan@ivan-Otus:~/Desktop/Otus_HomeWork/Home work 12/Ansible$ ansible-playbook nginx.yml 

PLAY [NGINX | Install and configure NGINX] *********************************************************************************************************************************************

TASK [Gathering Facts] *****************************************************************************************************************************************************************
ok: [nginx]

TASK [update] **************************************************************************************************************************************************************************
changed: [nginx]

TASK [NGINX | Install NGINX] ***********************************************************************************************************************************************************
changed: [nginx]

PLAY RECAP *****************************************************************************************************************************************************************************
nginx                      : ok=3    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

Далее добавим шаблон для конфига NGINX и модуль, который будет копировать этот шаблон на хост, пропишем в Playbook необходимую нам переменную. Нам нужно
чтобы NGINX слушал на порту 8080. Также добавим теги, на данном этапе наш файл будет выглядеть следующим образом:

```sh
---
- name: NGINX | Install and configure NGINX
  hosts: nginx
  become: true
  vars:
    nginx_listen_port: 8080

  tasks:
    - name: update
      apt:
        update_cache=yes
      tags:
        - apdate apt
    
    - name: NGINX | Install NGINX
      apt:
        name: nginx
        state: latest
      tags:
        - nginx-package

    - name: NGINX | Create nginx config file from template
      template:
        src: templates/nginx.conf.j2
        dest: /etc/nginx/nginx.conf
      tags:
        - nginx-configuration
```

Сам шаблон будет выглядеть так:

```sh
# {{ ansible_managed }}
events {
    worker_connections 1024;
}

http {
    server {
        listen       {{ nginx_listen_port }} default_server;
        server_name  default_server;
        root         /usr/share/nginx/html;

        location / {
        }
    }
}
```

Теперь создадим handler и добавим notify к копирования шаблона. Теперь каждый раз когда конфиг будет изменяться - сервис перезагрузиться.
Результирующий файл nginx.yml. Теперь можно его запустить.

```sh
---
- name: NGINX | Install and configure NGINX
  hosts: nginx
  become: true
  vars:
    nginx_listen_port: 8080

  tasks:
    - name: update
      apt:
        update_cache=yes
      tags:
        - apdate apt
    
    - name: NGINX | Install NGINX
      apt:
        name: nginx
        state: latest
      notify:
        - restart nginx
      tags:
        - nginx-package

    - name: NGINX | Create nginx config file from template
      template:
        src: templates/nginx.conf.j2
        dest: /etc/nginx/nginx.conf
      notify:
        - reload nginx
      tags:
        - nginx-configuration

  handlers:
    - name: restart nginx
      systemd:
        name: nginx
        state: restarted
        enabled: yes

    - name: reload nginx
      systemd:
        name: nginx
        state: reloaded
```

```sh
ivan@ivan-Otus:~/Desktop/Otus_HomeWork/Home work 12/Ansible$ ansible-playbook nginx.yml 

PLAY [NGINX | Install and configure NGINX] *********************************************************************************************************************************************

TASK [Gathering Facts] *****************************************************************************************************************************************************************
ok: [nginx]

TASK [update] **************************************************************************************************************************************************************************
changed: [nginx]

TASK [NGINX | Install NGINX] ***********************************************************************************************************************************************************
ok: [nginx]

TASK [NGINX | Create nginx config file from template] **********************************************************************************************************************************
changed: [nginx]

RUNNING HANDLER [reload nginx] *********************************************************************************************************************************************************
changed: [nginx]

PLAY RECAP *****************************************************************************************************************************************************************************
nginx                      : ok=5    changed=3    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

Теперь можно перейти в браузере по адресу http://192.168.11.150:8080 и убедиться, что сайт доступен.
Или из консоли выполнить команду : ```curl http://192.168.11.150:8080```

```sh
ivan@ivan-Otus:~/Desktop/Otus_HomeWork/Home work 12/Ansible$ vagrant ssh
Welcome to Ubuntu 22.04.2 LTS (GNU/Linux 5.15.0-71-generic x86_64)

vagrant@nginx:~$ curl http://192.168.11.150:8080
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
```

### Создание Ansible роли.

В каталоге Ansible-roles создана роль для установки и настройки NGINX, запустим роль для проверки:

```sh
ivan@ivan-Otus:~/Desktop/Otus_HomeWork/Home work 12/Ansible-roles$ ansible-playbook nginx_role.yml

PLAY [nginx] ***************************************************************************************************************************************************************************

TASK [Gathering Facts] *****************************************************************************************************************************************************************
ok: [nginx]

TASK [nginx : update] ******************************************************************************************************************************************************************
changed: [nginx]

TASK [nginx : NGINX | Install NGINX] ***************************************************************************************************************************************************
changed: [nginx]

TASK [nginx : NGINX | Create nginx config file from template] **************************************************************************************************************************
changed: [nginx]

RUNNING HANDLER [nginx : restart nginx] ************************************************************************************************************************************************
changed: [nginx]

RUNNING HANDLER [nginx : reload nginx] *************************************************************************************************************************************************
changed: [nginx]

PLAY RECAP *****************************************************************************************************************************************************************************
nginx                      : ok=6    changed=5    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0  
```

Проверим что сайт доступен, консоли выполнить команду : ```curl http://192.168.11.150:8080```

```sh
ivan@ivan-Otus:~/Desktop/Otus_HomeWork/Home work 12/Ansible$ vagrant ssh
Welcome to Ubuntu 22.04.2 LTS (GNU/Linux 5.15.0-71-generic x86_64)

vagrant@nginx:~$ curl http://192.168.11.150:8080
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
```
