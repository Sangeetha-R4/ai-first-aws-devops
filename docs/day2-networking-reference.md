# Day 2 — Networking Command Reference

> Study guide. Read to refresh; use the interview questions at the end to self-test.
> Companion to `lab-log/day2.md` (your actual outputs).

---

## 1. Installing software (`apt`)

| Command | What it does |
|---|---|
| `apt update` | Refresh the package catalog (downloads lists, installs nothing) |
| `apt install -y pkg1 pkg2` | Install packages (`-y` = auto-yes) |
| `apt list --upgradable` | Show packages with newer versions available |
| `which <tool>` | Check if a tool is installed and where |

### The interactive-prompt gotcha
Some packages (like `tzdata`) stop and *ask questions* (timezone, license, config). Two fixes:
1. **Answer it** — read the prompt, pick the right option.
2. **Bypass it** — prefix with `DEBIAN_FRONTEND=noninteractive`:
   ```bash
   DEBIAN_FRONTEND=noninteractive apt install -y python3
   ```
   This is **essential** for Dockerfiles and CI, where nobody is there to answer prompts.

### Minimal containers
Minimal images (like `ubuntu:24.04`) ship with almost no tools — no `ip`, `ping`, `curl`, `python3`. Install what you need. That's normal, and it's why real deployments use a `Dockerfile` to bake in the exact tools required.

---

## 2. Network interfaces

| Command | What it does |
|---|---|
| `ip addr` | Show all network interfaces + their IP addresses |
| `hostname -I` | Quick way to see just your IP |

### Reading `ip addr`
- **`lo`** — loopback interface, `127.0.0.1` = "localhost" (talks to yourself). Every machine has it.
- **`eth0`** — the real network connection (your actual IP).
- `state UP` / `DOWN` — active vs not in use.
- **`172.17.0.2/16`** — the `/16` is the subnet mask: first 16 bits are the *network*, the rest identifies *you*.

### IP formats
- **IPv4**: `8.8.8.8`, `172.17.0.2` (four numbers, dots)
- **IPv6**: `2404:6800:4007:821::200e` (colons, `::` = long run of zeros)

---

## 3. Connectivity vs DNS (THE core diagnostic)

| Command | Tests |
|---|---|
| `ping -c 4 8.8.8.8` | Raw connectivity (by IP) |
| `ping -c 4 google.com` | Connectivity **+** DNS (by name) |
| `getent hosts name` | What IP a name resolves to |
| `cat /etc/resolv.conf` | Which DNS server you're asking |

### The decision tree (memorize this)
```
ping 8.8.8.8 fails        → network/interface problem (check ip addr, cables, routes)
ping 8.8.8.8 works,
  but ping google.com fails → DNS problem (check /etc/resolv.conf)
both work                 → network is fine; look higher (app, firewall, port)
```

### DNS = the phonebook
You dial a number, not a name. DNS translates names → IPs. It forwards up a chain:
```
container → Docker DNS (192.168.65.7) → host → real internet DNS
```
(Same model later in AWS: instance → VPC resolver `10.0.0.2` → Route 53 → real DNS.)

---

## 4. Ports & listening services

| Command | What it does |
|---|---|
| `ss -tulpn` | Show everything **listening** for connections + process names |

### The flags
- `-t` TCP, `-u` UDP, `-l` listening, `-p` show process, `-n` numeric

### Reading the output
```
tcp  LISTEN  0  5  0.0.0.0:8000  0.0.0.0:*  users:(("python3",pid=2842,fd=3))
```
- `0.0.0.0:8000` = listening on port 8000, all interfaces
- `LISTEN` = waiting for connections
- `users:(("python3",pid=2842))` = which process holds it (`-p` reveals this)

### What a port IS
A port is just a *number* a program listens on. A "service" = a program listening on a port waiting for connections.

---

## 5. HTTP & the client-server model

### Start a simple web server
```bash
python3 -m http.server 8000 &      # serves current dir on port 8000
```

### Fetch it
```bash
curl http://localhost:8000/
```

### The interaction
```
client (curl)  ──"GET /"──▶  server (listening on :8000)
client         ◀──200 + HTML──  server
```

### Status codes (the vocabulary of the web)
| Code | Meaning |
|---|---|
| 200 | OK / success |
| 301 / 302 | Redirect (go elsewhere) |
| 404 | Not found |
| 500 | Server error (app broke) |

---

## 6. Background jobs + kill (recap)

```bash
command &      # run in background
jobs           # list background jobs
kill %1        # kill by JOB number (%1)
kill 2842      # kill by PID (2842)
```

`Done` = finished itself · `Terminated` = was killed.

---

## Interview questions (self-test)

1. What's the difference between `ping 8.8.8.8` and `ping google.com`? Why test both?
2. `ping 8.8.8.8` works but `ping google.com` fails. What's broken, and what file do you check?
3. What does `0.0.0.0:8000` mean in `ss -tulpn` output?
4. How do you find out which process is listening on a specific port?
5. What's the loopback interface, and what's its IP address?
6. What is DNS, in one plain-English sentence?
7. Explain what happens, step by step, when you run `curl http://localhost:8000/`.
8. What's the difference between status codes 200, 404, and 500?
9. You run `apt install python3` and it "hangs" asking about geographic area. What happened, and how do you fix it non-interactively?
10. Your app can't be reached on port 8080. Walk me through your diagnosis, command by command.
11. What's the difference between IPv4 and IPv6? Give an example of each.
12. Why do minimal Docker containers lack `ping`, `curl`, `ip`, etc., and how do you get them?
