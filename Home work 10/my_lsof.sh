#!/bin/bash

printf "%-8s %-20s %-5s %-10s %s\n" "PID" "COMMAND" "FD" "TYPE" "FILE"

for pid in /proc/[0-9]*; do
    pid=${pid#/proc/}

    # Проверяем доступность каталога fd
    if [[ ! -r /proc/$pid/fd ]]; then
        continue
    fi

    # Получаем имя процесса
    if [[ -r /proc/$pid/comm ]]; then
        comm=$(< /proc/$pid/comm)
    fi

    # Перебор всех файловых дескрипторов
    for fd_path in /proc/$pid/fd/*; do
        if [[ -e "$fd_path" ]]; then
            fd=$(basename "$fd_path")

            # Получаем путь, на который указывает дескриптор
            target=$(readlink -f "$fd_path" 2>/dev/null)

            # Определим тип (файл, сокет, pipe и т.д.)
            if [[ -S "$fd_path" ]]; then
                ftype="socket"
            elif [[ -p "$fd_path" ]]; then
                ftype="pipe"
            elif [[ -f "$target" ]]; then
                ftype="file"
            elif [[ -d "$target" ]]; then
                ftype="dir"
            else
                ftype="other"
            fi

            printf "%-8s %-20s %-5s %-10s %s\n" "$pid" "$comm" "$fd" "$ftype" "$target"
        fi
    done
done