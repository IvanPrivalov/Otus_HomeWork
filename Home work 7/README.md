## Домашнее задание: Работа с загрузчиком.
____

### Задание:

1. Включить отображение меню Grub.
2. Попасть в систему без пароля несколькими способами.
3. Установить систему с LVM, после чего переименовать VG.

### Включить отображение меню Grub

По умолчанию меню загрузчика Grub скрыто и нет задержки при загрузке. Для отображения меню нужно отредактировать конфигурационный файл.

```sh
root@grub:~# nano /etc/default/grub
```

Комментируем строку, скрывающую меню и ставим задержку для выбора пункта меню в 20 секунд.

```sh
GRUB_DEFAULT=0
#GRUB_TIMEOUT_STYLE=hidden
GRUB_TIMEOUT=20
GRUB_DISTRIBUTOR=`lsb_release -i -s 2> /dev/null || echo Debian`
GRUB_CMDLINE_LINUX_DEFAULT=""
GRUB_CMDLINE_LINUX=""
```

Обновляем конфигурацию загрузчика и перезагружаемся для проверки.

```sh
root@grub:~# update-grub
Sourcing file `/etc/default/grub'
Sourcing file `/etc/default/grub.d/init-select.cfg'
Generating grub configuration file ...
Found linux image: /boot/vmlinuz-5.15.0-136-generic
Found initrd image: /boot/initrd.img-5.15.0-136-generic
Warning: os-prober will not be executed to detect other bootable partitions.
Systems on them will not be added to the GRUB boot configuration.
Check GRUB_DISABLE_OS_PROBER documentation entry.
done
root@grub:~# reboot
```

При загрузке в окне виртуальной машины мы должны увидеть меню загрузчика.

![image 1](https://github.com/IvanPrivalov/Otus_HomeWork/blob/main/Home%20work%207/screens/Screenshot_01.png)

### Попасть в систему без пароля несколькими способами

Для получения доступа необходимо открыть GUI VirtualBox, запустить виртуальную машину и при выборе ядра для загрузки нажать e - в данном контексте edit. Попадаем в окно, где мы можем изменить параметры загрузки:

![image 2](https://github.com/IvanPrivalov/Otus_HomeWork/blob/main/Home%20work%207/screens/Screenshot_02.png)

#### Способ 1. init=/bin/bash
В конце строки, начинающейся с linux, добавляем rw init=/bin/bash и нажимаем сtrl-x для загрузки в систему:

![image 3](https://github.com/IvanPrivalov/Otus_HomeWork/blob/main/Home%20work%207/screens/Screenshot_03.png)

В целом на этом все, Вы попали в систему.

![image 4](https://github.com/IvanPrivalov/Otus_HomeWork/blob/main/Home%20work%207/screens/Screenshot_04.png)

Затем запустить команду passwd для изменения пароля root. 

После настройки пароля требуется перезагрузить систему. Для этого написать команду exec /sbin/init и нажать Enter.

#### Способ 2. Recovery mode

В меню загрузчика на первом уровне выбрать второй пункт (Advanced options…), далее загрузить пункт меню с указанием recovery mode в названии. 
Получим меню режима восстановления.

![image 5](https://github.com/IvanPrivalov/Otus_HomeWork/blob/main/Home%20work%207/screens/Screenshot_05.png)

В этом меню сначала включаем поддержку сети (network) для того, чтобы файловая система перемонтировалась в режим read/write (либо это можно сделать вручную).
Далее выбираем пункт root и попадаем в консоль с пользователем root. Если вы ранее устанавливали пароль для пользователя root (по умолчанию его нет), то необходимо его ввести. 
В этой консоли можно производить любые манипуляции с системой.

![image 6](https://github.com/IvanPrivalov/Otus_HomeWork/blob/main/Home%20work%207/screens/Screenshot_06.png)

### Установить систему с LVM, после чего переименовать VG

Посмотрим текущее состояние системы (список Volume Group):

```sh
root@grub:~# vgs
  VG        #PV #LV #SN Attr   VSize   VFree 
  ubuntu-vg   1   1   0 wz--n- <13.25g <3.25g
```

Нас интересует вторая строка с именем Volume Group. Приступим к переименованию:

```sh
root@grub:~# vgrename ubuntu-vg ubuntu-otus
  Volume group "ubuntu-vg" successfully renamed to "ubuntu-otus"
```

Далее правим /boot/grub/grub.cfg. Везде заменяем старое название VG на новое (в файле дефис меняется на два дефиса ubuntu--vg ubuntu--otus).
После чего можем перезагружаться и, если все сделано правильно, успешно грузимся с новым именем Volume Group и проверяем:

```sh
root@grub:~# cp /boot/grub/grub.cfg /tmp/grub.cfg.bkk
root@grub:~# cat /boot/grub/grub.cfg | grep vg
    insmod vga
	linux	/vmlinuz-5.15.0-119-generic root=/dev/mapper/ubuntu--vg-ubuntu--lv ro  
		linux	/vmlinuz-5.15.0-119-generic root=/dev/mapper/ubuntu--vg-ubuntu--lv ro  
		linux	/vmlinuz-5.15.0-119-generic root=/dev/mapper/ubuntu--vg-ubuntu--lv ro recovery nomodeset dis_ucode_ldr 
root@grub:~# find /boot/grub/ -name 'grub.cfg' -exec sed -i 's/--vg/--otus/g' {} +
root@grub:~# cat /boot/grub/grub.cfg | grep vg
    insmod vga
root@grub:~# cat /boot/grub/grub.cfg | grep otus
	linux	/vmlinuz-5.15.0-119-generic root=/dev/mapper/ubuntu--otus-ubuntu--lv ro  
		linux	/vmlinuz-5.15.0-119-generic root=/dev/mapper/ubuntu--otus-ubuntu--lv ro  
		linux	/vmlinuz-5.15.0-119-generic root=/dev/mapper/ubuntu--otus-ubuntu--lv ro recovery nomodeset dis_ucode_ldr 
```

```sh
root@grub:~# vgs
  VG          #PV #LV #SN Attr   VSize   VFree 
  ubuntu-otus   1   1   0 wz--n- <13.25g <3.25g
```