## Docker
____

### Цель домашнего задания:

Разобраться с основами docker, с образом, эко системой docker в целом.

### Описание домашнего задания:
1) Установите Docker на хост машину

2) Установите Docker Compose - как плагин, или как отдельное приложение.

3) Создайте свой кастомный образ nginx на базе alpine. После запуска nginx должен отдавать кастомную страницу (достаточно изменить дефолтную страницу nginx)

4) Определите разницу между контейнером и образом. Вывод опишите в домашнем задании.

5) Ответьте на вопрос: Можно ли в контейнере собрать ядро?

### Установите Docker на хост машину

1. Добавим репозиторий Docker

```sh
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
```

2. Установим Docker

```sh
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

3. Проверяем

```sh
root@ivan-Otus:~# sudo docker run hello-world
Unable to find image 'hello-world:latest' locally
latest: Pulling from library/hello-world
e6590344b1a5: Pull complete 
Digest: sha256:dd01f97f252193ae3210da231b1dca0cffab4aadb3566692d6730bf93f123a48
Status: Downloaded newer image for hello-world:latest

Hello from Docker!
This message shows that your installation appears to be working correctly.

To generate this message, Docker took the following steps:
 1. The Docker client contacted the Docker daemon.
 2. The Docker daemon pulled the "hello-world" image from the Docker Hub.
    (amd64)
 3. The Docker daemon created a new container from that image which runs the
    executable that produces the output you are currently reading.
 4. The Docker daemon streamed that output to the Docker client, which sent it
    to your terminal.

To try something more ambitious, you can run an Ubuntu container with:
 $ docker run -it ubuntu bash

Share images, automate workflows, and more with a free Docker ID:
 https://hub.docker.com/

For more examples and ideas, visit:
 https://docs.docker.com/get-started/

root@ivan-Otus:~# docker ps -a
CONTAINER ID   IMAGE         COMMAND    CREATED          STATUS                      PORTS     NAMES
d510b53415fb   hello-world   "/hello"   13 seconds ago   Exited (0) 12 seconds ago             great_carson
```

### Установите Docker Compose - как плагин, или как отдельное приложение.

```sh
root@ivan-Otus:/home/ivan/Desktop/Otus_HomeWork/Home work 14# curl -SL "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0
  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0
100 71.7M  100 71.7M    0     0  26.4M      0  0:00:02  0:00:02 --:--:-- 31.8M
root@ivan-Otus:/home/ivan/Desktop/Otus_HomeWork/Home work 14# chmod +x /usr/local/bin/docker-compose
root@ivan-Otus:/home/ivan/Desktop/Otus_HomeWork/Home work 14# docker-compose --version
Docker Compose version v2.36.1
```

### Создайте свой кастомный образ nginx на базе alpine. После запуска nginx должен отдавать кастомную страницу (достаточно изменить дефолтную страницу nginx)

Создал ```Dockerfile``` кастомная страница ```index.html``` и конфиг ```nginx.conf```

```sh
FROM alpine:3.20
RUN apk update && apk add nginx \
&& rm -rf /var/cache/apk/*
RUN adduser -D -g 'webuser' webuser \
&& mkdir /webuser \
&& chown -R webuser:webuser /var/lib/nginx \
&& chown -R webuser:webuser /webuser \
&& mkdir -p /run/nginx
COPY nginx.conf /etc/nginx
COPY index.html /webuser
EXPOSE 80
ENTRYPOINT ["nginx", "-g", "daemon off;"]
```

Билдим образ ```docker build -t privalovip/otus_nginx_alpine:1.0 .```:

```sh
root@ivan-Otus:/home/ivan/Desktop/Otus_HomeWork/Home work 14# docker build -t privalovip/otus_nginx_alpine:1.0 .
[+] Building 6.6s (10/10) FINISHED                                                                                                                                       docker:default
 => [internal] load build definition from Dockerfile                                                                                                                               0.0s
 => => transferring dockerfile: 385B                                                                                                                                               0.0s
 => [internal] load metadata for docker.io/library/alpine:3.20                                                                                                                     2.3s
 => [internal] load .dockerignore                                                                                                                                                  0.0s
 => => transferring context: 2B                                                                                                                                                    0.0s
 => [1/5] FROM docker.io/library/alpine:3.20@sha256:de4fe7064d8f98419ea6b49190df1abbf43450c1702eeb864fe9ced453c1cc5f                                                               0.9s
 => => resolve docker.io/library/alpine:3.20@sha256:de4fe7064d8f98419ea6b49190df1abbf43450c1702eeb864fe9ced453c1cc5f                                                               0.0s
 => => sha256:de4fe7064d8f98419ea6b49190df1abbf43450c1702eeb864fe9ced453c1cc5f 9.22kB / 9.22kB                                                                                     0.0s
 => => sha256:43180c492a5e6cedd8232e8f77a454f666f247586853eecb90258b26688ad1d3 1.02kB / 1.02kB                                                                                     0.0s
 => => sha256:ff221270b9fb7387b0ad9ff8f69fbbd841af263842e62217392f18c3b5226f38 581B / 581B                                                                                         0.0s
 => => sha256:0a9a5dfd008f05ebc27e4790db0709a29e527690c21bcbcd01481eaeb6bb49dc 3.63MB / 3.63MB                                                                                     0.6s
 => => extracting sha256:0a9a5dfd008f05ebc27e4790db0709a29e527690c21bcbcd01481eaeb6bb49dc                                                                                          0.1s
 => [internal] load build context                                                                                                                                                  0.0s
 => => transferring context: 1.05kB                                                                                                                                                0.0s
 => [2/5] RUN apk update && apk add nginx && rm -rf /var/cache/apk/*                                                                                                               2.8s
 => [3/5] RUN adduser -D -g 'webuser' webuser && mkdir /webuser && chown -R webuser:webuser /var/lib/nginx && chown -R webuser:webuser /webuser && mkdir -p /run/nginx             0.4s 
 => [4/5] COPY nginx.conf /etc/nginx                                                                                                                                               0.1s 
 => [5/5] COPY index.html /webuser                                                                                                                                                 0.0s 
 => exporting to image                                                                                                                                                             0.1s 
 => => exporting layers                                                                                                                                                            0.1s 
 => => writing image sha256:3a049fc18d78f97cfe94eb02343ba28290b1da32abe2a31f074591d1d7812b9d                                                                                       0.0s 
 => => naming to docker.io/privalovip/otus_nginx_alpine:1.0  

root@ivan-Otus:/home/ivan/Desktop/Otus_HomeWork/Home work 14# docker images
REPOSITORY                     TAG       IMAGE ID       CREATED              SIZE
privalovip/otus_nginx_alpine   1.0       3a049fc18d78   About a minute ago   9.26MB
hello-world                    latest    74cc54e27dc4   3 months ago         10.1kB
```

Запускаем контейнер:

```sh
root@ivan-Otus:/home/ivan/Desktop/Otus_HomeWork/Home work 14# docker run -d -p 80:80 --name nginx_alpine privalovip/otus_nginx_alpine:1.0
2214da19e7c79a757de679edbe69e480554b65bd73c2e49b3cc15978bfdb2911
root@ivan-Otus:/home/ivan/Desktop/Otus_HomeWork/Home work 14# docker ps -a
CONTAINER ID   IMAGE                              COMMAND                  CREATED             STATUS                         PORTS                                 NAMES
2214da19e7c7   privalovip/otus_nginx_alpine:1.0   "nginx -g 'daemon of…"   17 seconds ago      Up 16 seconds                  0.0.0.0:80->80/tcp, [::]:80->80/tcp   nginx_alpine
```

Проверяем:

![image 1](https://github.com/IvanPrivalov/Otus_HomeWork/blob/main/Home%20work%2014/screens/Screenshot_01.png)

Заливаем образ на ```https://hub.docker.com/repositories/privalovip```

1. Генерируем персональный ключ доступа.

![image 2](https://github.com/IvanPrivalov/Otus_HomeWork/blob/main/Home%20work%2014/screens/Screenshot_02.png)

2. Лонинимся ```docker login -u privalovip```

```sh
root@ivan-Otus:/home/ivan/Desktop/Otus_HomeWork/Home work 14# docker login -u privalovip

i Info → A Personal Access Token (PAT) can be used instead.
         To create a PAT, visit https://app.docker.com/settings
         
         
Password: 

WARNING! Your credentials are stored unencrypted in '/root/.docker/config.json'.
Configure a credential helper to remove this warning. See
https://docs.docker.com/go/credential-store/

Login Succeeded
```

3. Заливаем образ:

```sh
root@ivan-Otus:/home/ivan/Desktop/Otus_HomeWork/Home work 14# docker push privalovip/otus_nginx_alpine:1.0
The push refers to repository [docker.io/privalovip/otus_nginx_alpine]
635c4afa55f9: Pushed 
6d9806d2ed2e: Pushed 
40bb4d32a55a: Pushed 
f127f3a145e1: Pushed 
994456c4fd7b: Mounted from library/alpine 
1.0: digest: sha256:bf4fd11d7a683b9d34d9741cdd1d996aadc3c51b69ed9ae62691d313fa0335c0 size: 1360
```

Проверяем:

![image 3](https://github.com/IvanPrivalov/Otus_HomeWork/blob/main/Home%20work%2014/screens/Screenshot_03.png)

Ссылка на Docker Hub https://hub.docker.com/repository/docker/privalovip/otus_nginx_alpine/general

Проверим запуск контейнера из репозитория:

Удалим ранее запущенные контейнеры:

```sh
root@ivan-Otus:/home/ivan/Desktop/Otus_HomeWork/Home work 14# docker ps -a
CONTAINER ID   IMAGE                              COMMAND                  CREATED          STATUS                     PORTS     NAMES
2214da19e7c7   privalovip/otus_nginx_alpine:1.0   "nginx -g 'daemon of…"   42 minutes ago   Exited (0) 2 seconds ago             nginx_alpine
d510b53415fb   hello-world                        "/hello"                 2 hours ago      Exited (0) 2 hours ago               great_carson
root@ivan-Otus:/home/ivan/Desktop/Otus_HomeWork/Home work 14# docker rm 2214da19e7c7 d510b53415fb
2214da19e7c7
d510b53415fb
root@ivan-Otus:/home/ivan/Desktop/Otus_HomeWork/Home work 14# docker ps -a
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
```

Удалим образы:

```sh
root@ivan-Otus:/home/ivan/Desktop/Otus_HomeWork/Home work 14# docker images
REPOSITORY                     TAG       IMAGE ID       CREATED        SIZE
privalovip/otus_nginx_alpine   1.0       3a049fc18d78   2 hours ago    9.26MB
hello-world                    latest    74cc54e27dc4   3 months ago   10.1kB
root@ivan-Otus:/home/ivan/Desktop/Otus_HomeWork/Home work 14# docker rmi 3a049fc18d78 74cc54e27dc4
Untagged: privalovip/otus_nginx_alpine:1.0
Untagged: privalovip/otus_nginx_alpine@sha256:bf4fd11d7a683b9d34d9741cdd1d996aadc3c51b69ed9ae62691d313fa0335c0
Deleted: sha256:3a049fc18d78f97cfe94eb02343ba28290b1da32abe2a31f074591d1d7812b9d
Untagged: hello-world:latest
Untagged: hello-world@sha256:dd01f97f252193ae3210da231b1dca0cffab4aadb3566692d6730bf93f123a48
Deleted: sha256:74cc54e27dc41bb10dc4b2226072d469509f2f22f1a3ce74f4a59661a1d44602
Deleted: sha256:63a41026379f4391a306242eb0b9f26dc3550d863b7fdbb97d899f6eb89efe72
root@ivan-Otus:/home/ivan/Desktop/Otus_HomeWork/Home work 14# docker images
REPOSITORY   TAG       IMAGE ID   CREATED   SIZE
```

Скачаем образ из репозитория и запустим контейнер:

```sh
root@ivan-Otus:/home/ivan/Desktop/Otus_HomeWork/Home work 14# docker pull privalovip/otus_nginx_alpine:1.0
1.0: Pulling from privalovip/otus_nginx_alpine
0a9a5dfd008f: Already exists 
4837aaf88b71: Already exists 
a9476200a0d4: Already exists 
f1f9808048b5: Already exists 
edfd6b534915: Already exists 
Digest: sha256:bf4fd11d7a683b9d34d9741cdd1d996aadc3c51b69ed9ae62691d313fa0335c0
Status: Downloaded newer image for privalovip/otus_nginx_alpine:1.0
docker.io/privalovip/otus_nginx_alpine:1.0
root@ivan-Otus:/home/ivan/Desktop/Otus_HomeWork/Home work 14# docker images
REPOSITORY                     TAG       IMAGE ID       CREATED       SIZE
privalovip/otus_nginx_alpine   1.0       3a049fc18d78   2 hours ago   9.26MB
root@ivan-Otus:/home/ivan/Desktop/Otus_HomeWork/Home work 14# docker run -d -p 80:80 --name nginx_alpine privalovip/otus_nginx_alpine:1.0
d470540dc6c35a2e0a400ee9f104c5cd749eb0b3bdb6b06ce0a064512eca9a10
root@ivan-Otus:/home/ivan/Desktop/Otus_HomeWork/Home work 14# docker ps -a
CONTAINER ID   IMAGE                              COMMAND                  CREATED         STATUS         PORTS                                 NAMES
d470540dc6c3   privalovip/otus_nginx_alpine:1.0   "nginx -g 'daemon of…"   6 seconds ago   Up 5 seconds   0.0.0.0:80->80/tcp, [::]:80->80/tcp   nginx_alpine
```

### Ответы на вопросы

____

#### Определите разницу между контейнером и образом.

Образ - это файл, включающий зависимости, сведения, конфигурацию для дальнейшего развертывания и инициализации контейнера. Контейнер - это работающий (выполняющийся) экземпляр образа, который включает в себя все необходимое для запуска внутри какго-либо приложения (код приложения, среду выполнения, библиотеки, настройки и т.д), из одного образа можно создать неограниченное количество контейнеров.

#### Можно ли в контейнере собрать ядро?

Да, можно, как и любую программу из исходников.