# Day 2 — Linux Networking (Container Lab)

**Date:** 2026-10-21
**Goal:** Learn network interfaces, connectivity testing, DNS, ports, and the client-server model.

---

## 1. Installing tools (minimal container had none)

```
$ apt update
... (fetched 33.6 MB from archive.ubuntu.com + security.ubuntu.com)
Reading package lists... Done
3 packages can be upgraded.

$ apt install -y iproute2 iputils-ping curl
Updating certificates in /etc/ssl/certs...
0 added, 0 removed; done.

$ DEBIAN_FRONTEND=noninteractive apt install -y python3
running python rtupdate hooks for python3.12...
Processing triggers for libc-bin ...
```

**Lesson:** minimal Ubuntu images ship with almost no tools. Install what you need with `apt`.
**Gotcha:** `apt install python3` triggers an interactive *timezone* prompt (`tzdata`). Bypass it with `DEBIAN_FRONTEND=noninteractive` — essential for CI/Dockerfiles later.

---

## 2. Network interfaces

```
$ ip addr
1: lo: ... state UNKNOWN
    inet 127.0.0.1/8 scope host   <- loopback (myself)
2: tunl0@NONE: ... state DOWN     <- tunneling, unused
3: sit0@NONE: ... state DOWN      <- tunneling, unused
13: eth0@if14: ... state UP
    link/ether 02:42:ac:11:00:02
    inet 172.17.0.2/16            <- MY IP, Docker private network
```

- `lo` = loopback (`127.0.0.1` = "localhost", talks to self)
- `eth0` = real connection; `172.17.0.2` is my container's IP on Docker's `172.17.x.x` network
- `/16` = subnet mask (first 16 bits are the network)

---

## 3. Connectivity + DNS (the "network or DNS?" chain)

```
$ ping -c 4 8.8.8.8
4 packets transmitted, 4 received, 0% packet loss
rtt min/avg/max = 12.576/14.749/19.750 ms

$ ping -c 2 google.com
2 packets transmitted, 2 received, 0% packet loss
rtt min/avg/max = 8.542/8.672/8.802 ms

$ getent hosts google.com
2404:6800:4007:821::200e google.com     <- IPv6 address

$ cat /etc/resolv.conf
nameserver 192.168.65.7                  <- Docker's DNS forwarder
```

**Key insight:** `ping 8.8.8.8` tests *connectivity* (by IP). `ping google.com` tests *connectivity + DNS*. If the first works but the second fails, the problem is **DNS**.

---

## 4. Ports (who's listening?)

```
$ ss -tulpn
(empty — nothing running)

$ python3 -m http.server 8000 &
[1] 2842

$ ss -tulpn
tcp  LISTEN  0  5  0.0.0.0:8000  0.0.0.0:*  users:(("python3",pid=2842,fd=3))
```

- `0.0.0.0:8000` = listening on port 8000, all interfaces
- `-p` reveals the process (`python3`, pid 2842)

---

## 5. Client-server (curl the web server)

```
$ curl http://localhost:8000/
127.0.0.1 - - [21/Oct/2026 20:52:01] "GET / HTTP/1.1" 200 -
<!DOCTYPE HTML>
<html>... <h1>Directory listing for /</h1> ...
```

- The `200` = success (status code)
- `"GET / HTTP/1.1"` = the request
- The HTML = the response (a directory listing)

**Status codes:** 200 OK · 301/302 redirect · 404 not found · 500 server error

---

## 6. Cleanup

```
$ jobs
[1]+  Running   python3 -m http.server 8000 &

$ kill %1
$ ss -tulpn
(empty again)

[1]+  Terminated   python3 -m http.server 8000
```

---

## What I learned (in my own words)

*(fill this in — 3-5 sentences: what's the difference between testing connectivity vs DNS? what does "listening on a port" mean? what happened when curl hit the server?)*
