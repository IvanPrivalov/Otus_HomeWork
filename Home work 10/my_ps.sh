#!/bin/bash

# Заголовок
printf "%-8s %-8s %-6s %s\n" "PID" "PPID" "STAT" "COMMAND"

# Временный файл для хранения строк перед сортировкой
tmpfile=$(mktemp)

# Проходим по всем PID-папкам
for pid_dir in /proc/[0-9]*; do
    pid="${pid_dir#/proc/}"

    # Проверка наличия нужных файлов
    if [[ -r "$pid_dir/stat" && -r "$pid_dir/cmdline" ]]; then
        # Чтение файла stat, поиск (PID, PPID, status)
        stat=($(< "$pid_dir/stat"))
        pid="${stat[0]}"
        stat_status="${stat[2]}"
        ppid="${stat[3]}"

        # Чтение файла cmdline, поиск команды
        cmdline=$(tr '\0' ' ' < "$pid_dir/cmdline")
        if [[ -z "$cmdline" ]]; then
            # Если пусто, читаем файл comm и берём имя процесса
            cmdline="[$(cat "$pid_dir/comm")]"
        fi

        # Сохраняем в файл для сортировки
        printf "%-8s %-8s %-6s %s\n" "$pid" "$ppid" "$stat_status" "$cmdline" >> "$tmpfile"
    fi
done

# Сортировка по PID
sort -n "$tmpfile"
rm "$tmpfile"

