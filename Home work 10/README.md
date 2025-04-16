## Работа с процессами.
____

### Задание:


1. Написать свою реализацию ps ax используя анализ /proc
    - Результат ДЗ - рабочий скрипт который можно запустить

2. Написать свою реализацию lsof
    - Результат ДЗ - рабочий скрипт который можно запустить

### Написать свою реализацию ps ax используя анализ /proc

Реализация ps ax на bash с анализом содержимого /proc, выводящая:

- PID — ID процесса
- PPID — родительский PID
- STAT — статус процесса
- COMMAND — команда запуска

Сортировка по PID.

Скрипт my_ps.sh

Пример выполнения:

```sh
root@ivan-Otus:/home/ivan/Desktop/Otus_HomeWork/Home work 10# ./my_ps.sh 
PID      PPID     STAT   COMMAND
1        0        S      /sbin/init splash 
2        0        S      [kthreadd]
3        2        S      [pool_workqueue_release]
4        2        I      [kworker/R-rcu_gp]
5        2        I      [kworker/R-sync_wq]
6        2        I      [kworker/R-slub_flushwq]
7        2        I      [kworker/R-netns]
10       2        I      [kworker/0:0H-events_highpri]
12       2        I      [kworker/R-mm_percpu_wq]
13       2        I      [rcu_tasks_kthread]
14       2        I      [rcu_tasks_rude_kthread]
15       2        I      [rcu_tasks_trace_kthread]
16       2        S      [ksoftirqd/0]
17       2        I      [rcu_preempt]
18       2        S      [rcu_exp_par_gp_kthread_worker/0]
19       2        S      [rcu_exp_gp_kthread_worker]
20       2        S      [migration/0]
21       2        S      [idle_inject/0]
22       2        S      [cpuhp/0]
23       2        S      [cpuhp/1]
24       2        S      [idle_inject/1]
25       2        S      [migration/1]
26       2        S      [ksoftirqd/1]
28       2        I      [kworker/1:0H-events_highpri]
29       2        S      [cpuhp/2]
30       2        S      [idle_inject/2]
31       2        S      [migration/2]
32       2        S      [ksoftirqd/2]
34       2        I      [kworker/2:0H-events_highpri]
35       2        S      [cpuhp/3]
36       2        S      [idle_inject/3]
37       2        S      [migration/3]
38       2        S      [ksoftirqd/3]
40       2        I      [kworker/3:0H-events_highpri]
41       2        S      [cpuhp/4]
42       2        S      [idle_inject/4]
43       2        S      [migration/4]
44       2        S      [ksoftirqd/4]
46       2        I      [kworker/4:0H-events_highpri]
47       2        S      [cpuhp/5]
48       2        S      [idle_inject/5]
49       2        S      [migration/5]
50       2        S      [ksoftirqd/5]
```

### Написать свою реализацию lsof

Реализация lsof на Bash, с анализом содержимого /proc/[pid]/fd, выводящая:

- PID - ID процесса
- COMM - имя процесса
- FD - дескриптор
- FTYPE - тип файла
- TARGET - имя файла

Скрипт my_lsof.sh

Пример выполнения:

```sh
root@ivan-Otus:/home/ivan/Desktop/Otus_HomeWork/Home work 10# ./my_lsof.sh
PID      COMMAND              FD    TYPE       FILE
1        systemd              0     other      /dev/null
1        systemd              1     other      /dev/null
1        systemd              10    other      /proc/1/fd/anon_inode:[pidfd]
1        systemd              100   socket     /proc/1/fd/socket:[8808]
1        systemd              101   socket     /proc/1/fd/socket:[9634]
1        systemd              102   socket     /proc/1/fd/socket:[11409]
1        systemd              103   socket     /proc/1/fd/socket:[8186]
1        systemd              104   other      /proc/1/fd/anon_inode:[pidfd]
1        systemd              105   socket     /proc/1/fd/socket:[43756]
1        systemd              106   socket     /proc/1/fd/socket:[10466]
1        systemd              107   socket     /proc/1/fd/socket:[7112]
1        systemd              108   socket     /proc/1/fd/socket:[8177]
1        systemd              11    other      /proc/1/fd/anon_inode:inotify
1        systemd              112   socket     /proc/1/fd/socket:[8165]
1        systemd              113   socket     /proc/1/fd/socket:[8766]
1        systemd              114   socket     /proc/1/fd/socket:[9580]
1        systemd              116   socket     /proc/1/fd/socket:[7866]
1        systemd              117   socket     /proc/1/fd/socket:[7864]
1        systemd              118   socket     /proc/1/fd/socket:[7863]
1        systemd              119   socket     /proc/1/fd/socket:[7778]
1        systemd              12    other      /proc/1/fd/anon_inode:[pidfd]
1        systemd              120   socket     /proc/1/fd/socket:[5578]
1        systemd              121   socket     /proc/1/fd/socket:[13534]
1        systemd              122   socket     /proc/1/fd/socket:[10757]
1        systemd              123   socket     /proc/1/fd/socket:[11782]
1        systemd              124   socket     /proc/1/fd/socket:[11897]
1        systemd              125   socket     /proc/1/fd/socket:[12010]
1        systemd              126   socket     /proc/1/fd/socket:[12978]
1        systemd              128   socket     /proc/1/fd/socket:[13014]
1        systemd              129   socket     /proc/1/fd/socket:[11255]
```

Проверка:

```sh
905      NetworkManager       0     other      /dev/null
905      NetworkManager       1     socket     /proc/905/fd/socket:[13341]
905      NetworkManager       10    socket     /proc/905/fd/socket:[12393]
905      NetworkManager       11    socket     /proc/905/fd/socket:[12394]
905      NetworkManager       12    socket     /proc/905/fd/socket:[12395]
905      NetworkManager       13    socket     /proc/905/fd/socket:[12396]
905      NetworkManager       14    other      /proc/905/fd/anon_inode:inotify
905      NetworkManager       15    other      /proc/905/fd/anon_inode:inotify
905      NetworkManager       16    socket     /proc/905/fd/socket:[13439]
905      NetworkManager       17    socket     /proc/905/fd/socket:[13440]
905      NetworkManager       18    other      /proc/905/fd/anon_inode:[eventpoll]
905      NetworkManager       19    other      /proc/905/fd/anon_inode:[eventpoll]
905      NetworkManager       2     socket     /proc/905/fd/socket:[13341]
905      NetworkManager       20    pipe       /run/systemd/inhibit/2.ref
905      NetworkManager       21    other      /proc/905/fd/anon_inode:[timerfd]
905      NetworkManager       23    other      /proc/905/fd/anon_inode:[eventpoll]
905      NetworkManager       24    other      /proc/905/fd/anon_inode:[timerfd]
905      NetworkManager       25    socket     /proc/905/fd/socket:[12959]
905      NetworkManager       26    socket     /proc/905/fd/socket:[12960]
905      NetworkManager       3     other      /proc/905/fd/anon_inode:[eventfd]
905      NetworkManager       4     other      /proc/905/fd/anon_inode:[eventfd]
905      NetworkManager       5     socket     /proc/905/fd/socket:[12381]
905      NetworkManager       6     socket     /proc/905/fd/socket:[11514]
905      NetworkManager       7     other      /proc/905/fd/anon_inode:[eventfd]
905      NetworkManager       8     other      /proc/905/fd/net:[4026531840]
905      NetworkManager       9     other      /proc/905/fd/mnt:[4026532389]

root@ivan-Otus:/home/ivan/Desktop/Otus_HomeWork/Home work 10# ll /proc/905/fd
total 0
dr-x------ 2 root root 26 Apr 16 10:16 ./
dr-xr-xr-x 9 root root  0 Apr 16 10:16 ../
lr-x------ 1 root root 64 Apr 16 10:16 0 -> /dev/null
lrwx------ 1 root root 64 Apr 16 10:16 1 -> 'socket:[13341]'=
lrwx------ 1 root root 64 Apr 16 10:17 10 -> 'socket:[12393]'=
lrwx------ 1 root root 64 Apr 16 10:17 11 -> 'socket:[12394]'=
lrwx------ 1 root root 64 Apr 16 10:17 12 -> 'socket:[12395]'=
lrwx------ 1 root root 64 Apr 16 10:17 13 -> 'socket:[12396]'=
lr-x------ 1 root root 64 Apr 16 10:17 14 -> anon_inode:inotify
lr-x------ 1 root root 64 Apr 16 10:16 15 -> anon_inode:inotify
lrwx------ 1 root root 64 Apr 16 10:17 16 -> 'socket:[13439]'=
lrwx------ 1 root root 64 Apr 16 10:16 17 -> 'socket:[13440]'=
lrwx------ 1 root root 64 Apr 16 10:17 18 -> 'anon_inode:[eventpoll]'
lrwx------ 1 root root 64 Apr 16 10:16 19 -> 'anon_inode:[eventpoll]'
lrwx------ 1 root root 64 Apr 16 10:16 2 -> 'socket:[13341]'=
l-wx------ 1 root root 64 Apr 16 10:17 20 -> /run/systemd/inhibit/2.ref|
lrwx------ 1 root root 64 Apr 16 10:16 21 -> 'anon_inode:[timerfd]'
lrwx------ 1 root root 64 Apr 16 10:17 23 -> 'anon_inode:[eventpoll]'
lrwx------ 1 root root 64 Apr 16 10:17 24 -> 'anon_inode:[timerfd]'
lrwx------ 1 root root 64 Apr 16 10:17 25 -> 'socket:[12959]'=
lrwx------ 1 root root 64 Apr 16 10:17 26 -> 'socket:[12960]'=
lrwx------ 1 root root 64 Apr 16 10:16 3 -> 'anon_inode:[eventfd]'
lrwx------ 1 root root 64 Apr 16 10:16 4 -> 'anon_inode:[eventfd]'
lrwx------ 1 root root 64 Apr 16 10:17 5 -> 'socket:[12381]'=
lrwx------ 1 root root 64 Apr 16 10:17 6 -> 'socket:[11514]'=
lrwx------ 1 root root 64 Apr 16 10:17 7 -> 'anon_inode:[eventfd]'
lr-x------ 1 root root 64 Apr 16 10:17 8 -> 'net:[4026531840]'
lr-x------ 1 root root 64 Apr 16 10:16 9 -> 'mnt:[4026532389]'
```