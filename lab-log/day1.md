# Day 1 — Linux Fundamentals (Container Lab)

**Date:** 2026-10-20 (continued 2026-10-21)
**Goal:** Get Docker running, create a Linux container, learn files/permissions, processes, disk/memory, and logs hands-on.

---

## 1. Docker setup

```
$ docker info
Server Version: 24.0.6
Storage Driver: overlay2
Kernel Version: 5.10.16.3-microsoft-standard-WSL2
Operating System: Docker Desktop
CPUs: 4
Total Memory: 6.111GiB
```

✅ Docker Desktop running via WSL2 backend. Created container:

```
$ docker run -it --name lab1 ubuntu:24.04 bash
```

---

## 2. Confirming I'm inside Linux

```
$ whoami
root

$ cat /etc/os-release
PRETTY_NAME="Ubuntu 24.04.5 LTS"
NAME="Ubuntu"
VERSION="24.04.5 LTS (Noble Numbat)"

$ uname -a
Linux bfae9c96267f 5.10.16.3-microsoft-standard-WSL2 #1 SMP Fri Apr 2 22:23:49 UTC 2021 x86_64 x86_64 x86_64 GNU/Linux
```

---

## 3. Files & permissions (4a)

```
$ mkdir -p /tmp/lab
$ cd /tmp/lab
$ echo "hello" > file1.txt
$ cat file1.txt
hello

$ ls -l file1.txt
-rw-r--r-- 1 root root 6 Oct 20 21:45 file1.txt

$ chmod 600 file1.txt
$ ls -l file1.txt
-rw------- 1 root root 6 Oct 20 21:45 file1.txt

$ chmod +x file1.txt
$ ls -l file1.txt
-rwx--x--x 1 root root 6 Oct 20 21:45 file1.txt

$ chmod 644 file1.txt
$ ls -l file1.txt
-rw-r--r-- 1 root root 6 Oct 20 21:45 file1.txt
```

---

## 4. Processes (4b)

```
$ ps aux
USER  PID %CPU %MEM  VSZ  RSS TTY   STAT START TIME COMMAND
root    1  0.0  0.0 4588 3744 pts/0 Ss   08:01 0:00 bash
root   13  0.0  0.0 7892 3744 pts/0 R+   08:05 0:00 ps aux

$ sleep 60 &
[1] 14

$ ps aux | grep sleep
root  18 ... grep --color=auto sleep      # sleep already finished, grep matched itself

$ sleep 120 &
[1] 19

$ ps aux | grep sleep
root  19 ... sleep 120
root  21 ... grep --color=auto sleep

$ ps aux | grep sleep | grep -v grep
root  19 ... sleep 120

$ sleep 300 &
[1] 25

$ ps aux | grep sleep | grep -v grep
root  25 ... sleep 300

$ kill 25
$ ps aux | grep sleep
root  30 ... grep --color=auto sleep      # process gone

[1]+  Terminated              sleep 300
```

---

## 5. Disk & memory (4c)

```
$ df -h
Filesystem  Size Used Avail Use% Mounted on
overlay     251G 7.8G  231G  4% /
tmpfs        64M   0    64M  0% /dev
tmpfs       3.1G   0   3.1G  0% /sys/fs/cgroup
shm          64M   0    64M  0% /dev/shm
/dev/sdc    251G 7.8G  231G  4% /etc/hosts
tmpfs       3.1G   0   3.1G  0% /proc/acpi
tmpfs       3.1G   0   3.1G  0% /sys/firmware

$ du -sh /tmp
12K     /tmp

$ free -h
              total  used  free  shared buff/cache available
Mem:          6.1Gi 986Mi 4.3Gi  1.5Mi     1.0Gi     5.1Gi
Swap:         2.0Gi    0B 2.0Gi
```

---

## 6. Logs & filtering (4d)

```
$ cd /var/log
$ ls -la
-rw-r--r--  1 root root   4860 Sep 30 14:12 alternatives.log
drwxr-xr-x  2 root root   4096 Sep 30 14:12 apt
-rw-r--r--  1 root root  61229 Sep 30 14:05 bootstrap.log
-rw-rw----  1 root utmp      0 Sep 30 14:05 btmp
-rw-r--r--  1 root root 185387 Sep 30 14:12 dpkg.log
-rw-r--r--  1 root root      0 Sep 30 14:05 faillog
-rw-rw-r--  1 root utmp      0 Sep 30 14:05 lastlog
-rw-rw-r--  1 root utmp      0 Sep 30 14:05 wtmp

$ grep "status installed" dpkg.log | wc -l
313

$ grep -c "status installed" dpkg.log
313

$ grep "unminimize" dpkg.log
2026-09-30 14:12:48 install unminimize:amd64 <none> 0.2.1
2026-09-30 14:12:48 status half-installed unminimize:amd64 0.2.1
2026-09-30 14:12:48 status unpacked unminimize:amd64 0.2.1
2026-09-30 14:12:48 configure unminimize:amd64 0.2.1 <none>
2026-09-30 14:12:48 status unpacked unminimize:amd64 0.2.1
2026-09-30 14:12:48 status half-configured unminimize:amd64 0.2.1
2026-09-30 14:12:48 status installed unminimize:amd64 0.2.1
```

### Live `tail -f` (two terminals, same container)

```
Window 1 (writer):                Window 2 (watcher):
$ echo "I typed this myself"      $ tail -f /tmp/mylog.txt
  >> /tmp/mylog.txt                 hello from the other window
                                    second line at 12:45:34
                                    third line at 12:45:35
                                    I typed this myself
                                    NOW I see it live   <- appeared live
```

✅ Confirmed: both windows `cat /tmp/mylog.txt` show identical content (same container, same filesystem).

---

## What I learned (in my own words)

*(fill this in — 3-5 sentences: job number vs PID, what chmod 644 means, what tail -f does, why available > free)*
