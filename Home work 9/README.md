## Написать скрипт на языке Bash.
____

### Задание:

Написать скрипт для CRON, который раз в час будет формировать письмо и отправлять на заданную почту.


Необходимая информация в письме:

- Список IP адресов (с наибольшим кол-вом запросов) с указанием кол-ва запросов c момента последнего запуска скрипта;
- Список запрашиваемых URL (с наибольшим кол-вом запросов) с указанием кол-ва запросов c момента последнего запуска скрипта;
- Ошибки веб-сервера/приложения c момента последнего запуска;
- Список всех кодов HTTP ответа с указанием их кол-ва с момента последнего запуска скрипта.
- Скрипт должен предотвращать одновременный запуск нескольких копий, до его завершения.

В письме должен быть прописан обрабатываемый временной диапазон.

#### Скрипт: report_log.sh

```sh
#!/bin/bash

# Уникальный путь к lock-файлу
LOCK_FILE="/tmp/nginx_log_analyzer.lock"

# Используем flock для блокировки
(
  flock -n 200 || {
    echo "Скрипт уже запущен. Завершение."
    exit 1
  }

  echo "Скрипт запущен: $(date)"

# Настройки отправки почты
TO_EMAIL="privalovnt@gmail.com"
SUBJECT="Отчет отправляется каждый час"

# Путь к файлу лога
LOG_FILE="/var/log/nginx/access.log"

# Количество IP в топе (можно изменить)
TOP_N=5

# Путь к файлу, в котором сохраняется время последнего запуска
STATE_FILE="/var/log/ip_analyzer_last_run"

# Если файл состояния не существует — берем всю историю
if [[ ! -f "$STATE_FILE" ]]; then
    echo "01/Apr/1970:00:00" > "$STATE_FILE"
fi

# Читаем время последнего запуска
LAST_RUN=$(cat "$STATE_FILE")

# Обновляем время последнего запуска
date '+%d/%b/%Y:%H:%M' > "$STATE_FILE"

BODY="Отчет о запросах лога Nginx с последнего запуска скрипта ($LAST_RUN):\n\n"

BODY+="\nСписок IP с наибольшим количеством запросов:\n"
TOP_IP=$(awk -v time="$LAST_RUN" '
    $0 ~ "\\[" time {
        print $1
    }
' "$LOG_FILE" | sort | uniq -c | sort -nr | head -n "$TOP_N")
BODY+="$TOP_IP\n"

BODY+="\nТоп запрашиваемых URL (кол-во запросов):\n"
BODY+="Кол-во  |  URL\n"
TOP_URL=$(awk -v time="$LAST_RUN" '
    $0 ~ "\\[" time {
        match($0, /"(GET|POST|HEAD|PUT|DELETE|OPTIONS) ([^ ]+)/, m)
        if (m[2] != "")
            urls[m[2]]++
    }
    END {
        for (u in urls)
            printf "    %s   |   %s\n", urls[u], u
    }
' "$LOG_FILE" | sort -nr | head -n "$TOP_N")
BODY+="$TOP_URL\n"

BODY+="\nОшибки Nginx с последнего запуска:\n"
ERROR=$(awk -v time="$LAST_RUN" '
    $0 ~ "\\[" time {
        status = $9
        if (status ~ /^4[0-9][0-9]$/ || status ~ /^5[0-9][0-9]$/)
            print
    }
' "$LOG_FILE")
BODY+="$ERROR\n"

BODY+="\nHTTP коды ответов с последнего запуска:\n"
BODY+="Код ответа  |  Кол-во\n"
HTTP=$(awk -v time="$LAST_RUN" '
    $0 ~ "\\[" time {
        code = $9
        if (code ~ /^[1-5][0-9][0-9]$/) {
            count[code]++
        }
    }
    END {
        for (code in count)
            printf "    %s      |   %d\n", code, count[code]
    }
' "$LOG_FILE" | sort)
BODY+="$HTTP\n"

# Отправка письма
echo -e "$BODY" | mail -s "$SUBJECT" "$TO_EMAIL"

echo "Скрипт завершён: $(date)"

) 200>"$LOCK_FILE"
```

Дать права на выполнение:

```sh
root@otusserver:~# chmod +x ./report_log.sh
```

Запустить:

```sh
root@otusserver:~# ./report_log.sh 
Скрипт запущен: Wed Apr  9 13:05:57 UTC 2025
Скрипт завершён: Wed Apr  9 13:05:58 UTC 2025
```

#### Добавить в CRON

Открой редактор crontab:

```sh
root@otusserver:~# crontab -e
```

Добавь строчку:

```sh
0 * * * * ~./report_log.sh
```
#### Установка nginx

```sh
root@otusserver:~# apt install nginx -y
```

#### Настройка ssmtp

Установим ssmtp

```sh
root@otusserver:~# apt install ssmtp -y
```

Настроим конфигурационный файл ssmtp.conf:

```sh
root@otusserver:~# nano /etc/ssmtp/ssmtp.conf

mailhub=mail.netangels.ru:25
hostname=mail.netangels.ru:25
root=otus@3ddiamond.ru
AuthUser=otus@3ddiamond.ru
AuthPass=******
UseSTARTTLS=YES
#UseTLS=YES
FromLineOverride=YES
TLS_CA_File=/etc/pki/tls/certs/ca-bundle.crt
```

Настройте конфигурационный файл revaliases:

```sh
root@otusserver:~# nano /etc/ssmtp/revaliases

root:otus@3ddiamond.ru:mail.netangels.ru:25
```

#### Проверка:

В первый раз запустим скрипт без первоначальной даты, для этого очистим файл, куда пишется дата последнего запуска скрипта:

```sh
root@otusserver:~# > /var/log/ip_analyzer_last_run
```

Запустим скрипт:

```sh
root@otusserver:~# ./report_log.sh 
Скрипт запущен: Wed Apr  9 14:42:39 UTC 2025
Скрипт завершён: Wed Apr  9 14:42:40 UTC 2025
```

Проверяем выполнение:

![image 1](https://github.com/IvanPrivalov/Otus_HomeWork/blob/main/Home%20work%209/screens/Screenshot_01.png)

Выполним действия на сайте Nginx, что бы появились новые записи в лог файле и запустим скрипт еще раз.

![image 2](https://github.com/IvanPrivalov/Otus_HomeWork/blob/main/Home%20work%209/screens/Screenshot_02.png)

Появились новые события!
