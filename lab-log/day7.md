# Day 7 — Deeper Linux: Users, SSH, Services, PATH

**Date:** 2026-10-30
**Goal:** Close the gap between "I can use Linux commands" and "I can administer a server."

**Environment:** container `sshlab` (ubuntu:24.04, port 2222→22), SSH client on Windows.

---

## Part A — SSH key authentication

### Why a separate container
`lab1` had no port mapping, so it couldn't accept SSH. Created `sshlab` with `-p 2222:22`:

```bash
docker run -d --name sshlab -p 2222:22 ubuntu:24.04 sh -c 'while true; do sleep 3600; done'
```

**Lesson:** containers are disposable. Creating a second one costs nothing and keeps the first intact.

### Install the server

```bash
apt update && apt install -y openssh-server
```

| Package | Purpose |
|---|---|
| `openssh-client` | lets you connect **out** (`ssh`, `scp`) |
| `openssh-server` | lets others connect **in** (`sshd`) |

### Generate keys (on Windows)

```cmd
ssh-keygen -t ed25519 -C "portfolio-key"
```

- `-t ed25519` — modern elliptic-curve algorithm. 68-char key, faster and stronger than RSA at equivalent size.
- `-C "portfolio-key"` — comment/label, appended to the public key for identification. Purely cosmetic, no crypto effect.

Result:

```
C:\Users\Imvin\.ssh\id_ed25519       ← PRIVATE, never leaves the machine
C:\Users\Imvin\.ssh\id_ed25519.pub   ← PUBLIC, safe to share
```

Fingerprint: `SHA256:Sjtj0o6CxPLWiP3sWAE3byomP5xqM6MdIY8esBT5IJk`

### Place the public key on the server

```cmd
docker cp %USERPROFILE%\.ssh\id_ed25519.pub sshlab:/tmp/key.pub
```

```bash
mkdir -p /home/devops/.ssh
cat /tmp/key.pub >> /home/devops/.ssh/authorized_keys
chown -R devops:devops /home/devops/.ssh
chmod 700 /home/devops/.ssh
chmod 600 /home/devops/.ssh/authorized_keys
rm /tmp/key.pub
```

**Why `>>` not `>`:** `>>` appends. `>` would wipe any existing keys.

**Why ownership matters:** `sshd` runs with **StrictModes on**. It refuses keys if `~/.ssh` isn't owned by the user, or if group/others can write to it. Failure is **silent** — the client just gets a password prompt.

I hit exactly this: first attempt left `.ssh` owned by `root`:

```
drwx------ 2 root   root   4096 .
-rw------- 1 root   root     96 authorized_keys     ← ❌ wrong owner
```

Fixed with `chown -R devops:devops /home/devops/.ssh`:

```
drwx------ 2 devops devops 4096 .
-rw------- 1 devops devops   96 authorized_keys     ← ✅
```

**Cause:** `chown` ran before `authorized_keys` existed. Order matters: mkdir → create file → chown -R → chmod.

### Connect

```cmd
ssh -p 2222 devops@localhost
```

- `-p 2222` — lowercase `p` = port (note: `scp` uses uppercase `-P`)
- `devops@localhost` — user@host

First connection asks to verify the host key fingerprint → type full `yes` (not `y`). Saved to `~/.ssh/known_hosts` so it won't ask again.

**Result:**

```
devops@9c0776d5000e:~$
```

`devops@` = logged in as devops (not root). `~` = `/home/devops`. `$` = ordinary user (`#` would be root).

**This is the thing every job ad asked for and I had never done.**

---

## Part B — Users and groups

### Create the user

```bash
useradd -m -s /bin/bash devops
```

| Flag | Meaning |
|---|---|
| `-m` | create the home directory (needed for `.ssh`) |
| `-s /bin/bash` | login shell (default may be `sh`) |

### Inspect

```bash
id devops
```
```
uid=1001(devops) gid=1001(devops) groups=1001(devops)
```

| Field | Meaning |
|---|---|
| UID 1001 | 0 = root, 1–999 = system accounts, **1000+ = human users** |
| GID 1001 | personal group, auto-created (USERGROUPS_ENAB) |
| groups | supplementary groups — initially only the primary |

### The raw record

```bash
grep devops /etc/passwd
```
```
devops:x:1001:1001::/home/devops:/bin/bash
```

| # | Field | Value |
|---|---|---|
| 1 | username | `devops` |
| 2 | password | `x` = hash lives in `/etc/shadow` |
| 3 | UID | `1001` |
| 4 | GID | `1001` |
| 5 | GECOS | *(empty)* |
| 6 | home | `/home/devops` |
| 7 | shell | `/bin/bash` |

**Why the split:** `/etc/passwd` must be world-readable (programs map UID→name), but hashes must be secret.

```bash
ls -l /etc/shadow
```
```
-rw-r----- 1 root shadow 668 /etc/shadow      ← root + shadow group only
```

### Add to sudo

```bash
usermod -aG sudo devops
```

⚠️ **`-a` is critical.** Without it, `-G` **replaces** all supplementary groups:

```bash
usermod -G sudo devops     # ❌ wipes existing groups
usermod -aG sudo devops    # ✅ appends
```

Result:
```
groups=1001(devops),27(sudo)
```

---

## Part C — The sudo chain (three separate failures)

Getting `sudo` to work required fixing three different things in sequence. Each failure looked different.

### Failure 1 — `sudo: command not found`

Base `ubuntu:24.04` is minimal — no `sudo` binary.

```bash
apt install -y sudo
```

**Lesson:** being **in** a group ≠ having the **program**. Group membership is permission; the package is capability. You need both.

### Failure 2 — `[sudo] password for devops:` then `Sorry, try again`

`useradd` does **not** set a password. The account is locked:

```
devops:!:20756:0:99999:7:::      ← "!" = locked
```

`sudo` asks for the user's password. None exists → nothing can match.

```bash
passwd devops        # run as root; type the password at the prompts
```

After:
```
devops:$y$j9T$rzW...:20756:0:99999:7:::    ← real hash
```

**Reading `/etc/shadow`:**

`username:hash:lastchange:min:max:warn:inactive:expire:reserved`

| Hash prefix | Algorithm |
|---|---|
| `$y$` | **yescrypt** (Ubuntu 24.04 default — memory-hard, expensive to brute-force) |
| `$6$` | SHA-512 |
| `$5$` | SHA-256 |
| `$1$` | MD5 (broken, never use) |

| Value | Meaning |
|---|---|
| `*` | no password — can't log in with a password (system accounts) |
| `!` | locked |
| `$y$...` | usable password hash |

### Success

```bash
sudo cat /etc/shadow
```

**The complete access chain, proven:**
user created → in sudo group → sudo installed → password set → key-based SSH login → privilege escalation.

**Checklist for a working user:**

| Step | Command |
|---|---|
| 1. User exists | `useradd -m -s /bin/bash <name>` |
| 2. In sudo group | `usermod -aG sudo <name>` |
| 3. sudo installed | `apt install sudo` |
| 4. Password set | `passwd <name>` |
| 5. SSH key in place | `authorized_keys` |
| 6. Ownership correct | `chown -R <name>:<name> ~/.ssh` |

**"Created" ≠ "usable."** The gap is what I hit.

---

## Part D — PATH and environment variables

```bash
echo $PATH
```
```
/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin
```

Colon-separated list. The shell searches **left to right** and runs the first match.

| Directory | Contains |
|---|---|
| `/usr/local/sbin`, `/usr/local/bin` | tools **you** installed (take priority) |
| `/usr/sbin` | system admin tools (packages) |
| `/usr/bin` | **most commands** — `ls`, `grep`, `python3`, `ssh` |
| `/sbin`, `/bin` | essential commands (`/bin` is a symlink → `/usr/bin` on modern systems) |
| `/snap/bin` | snap packages |

**Order = priority.** `/usr/local/bin` before `/usr/bin` means *your* install shadows the system one.

**This is yesterday's bug.** `pip` lived in one Python's directory, `python` in another. The shell found whichever came first in PATH — and they disagreed.

### `which` — which binary actually runs

```bash
which ls grep python3 ssh
```

First thing to run when behaviour is unexpected.

### Other useful variables

```bash
echo $HOME            # /home/devops
echo $USER            # devops
echo $SHELL           # /bin/bash
echo $SSH_CONNECTION  # client_ip client_port server_ip server_port
```

`$SSH_CONNECTION` is set by sshd — proof the session arrived over the network.

---

## Part E — systemd, and why containers don't have it

```bash
systemctl status ssh
```
```
System has not been booted with systemd as init system (PID 1). Can't operate.
Failed to connect to bus: Host is down
```

**"Host is down" is misleading** — the machine is fine. It means the systemd message bus doesn't exist.

### The reason: PID 1

```
$ ps -p 1 -o pid,comm,args
PID  COMMAND
  1  sh -c while true; do sleep 3600; done
```

| Environment | PID 1 | Services managed by |
|---|---|---|
| Container | `sh -c while true...` | nothing — started by hand |
| Real server / VM | `systemd` | systemd, automatically |

`systemctl` talks to systemd *as PID 1*. Not PID 1 → nothing to talk to.

systemd is installed (`systemd 255.4-1ubuntu8.18`) and `systemctl` exists at `/usr/bin/systemctl` — but it can't function without being PID 1.

### What systemd does (on a real server)

| Job | Effect |
|---|---|
| Start services at boot | nginx/sshd/docker come up automatically |
| Restart crashed services | app dies → systemd restarts it |
| Dependency ordering | network before app |
| Logging | captures to `journalctl` |
| Resource limits | CPU/memory caps per service |

**The real consequence in a container:** if `sshd` crashes there is **no supervisor to restart it**. I had to start it by hand with `service ssh start`. On a real server, `systemctl enable ssh` handles it.

### Commands (for EC2 in Phase 2)

```bash
systemctl status <service>
systemctl start/stop/restart <service>
systemctl enable <service>          # start at boot
systemctl list-units --type=service
journalctl -u <service>             # that service's logs
journalctl -u <service> -f          # follow live (like tail -f)
```

**Containers run processes. VMs run init systems.** That distinction is the whole of this section.

---

## The runbook: standing up a usable SSH user on a fresh Ubuntu host

```markdown
# Runbook: create a usable SSH user

Preconditions: root access to the host; public key available on your workstation.

1. Install SSH server + sudo
   apt update && apt install -y openssh-server sudo

2. Create the user with a home directory and bash shell
   useradd -m -s /bin/bash devops

3. Grant sudo
   usermod -aG sudo devops

4. Set a password (required for sudo to work)
   passwd devops

5. Install the public key
   mkdir -p /home/devops/.ssh
   cat /path/to/key.pub >> /home/devops/.ssh/authorized_keys
   chown -R devops:devops /home/devops/.ssh
   chmod 700 /home/devops/.ssh
   chmod 600 /home/devops/.ssh/authorized_keys

6. Start the service
   service ssh start            # container
   systemctl enable --now ssh   # VM with systemd

7. Verify from the workstation
   ssh devops@<host>

Troubleshooting:
  - Key refused, password prompt appears → check ownership/permissions on ~/.ssh
  - "command not found: sudo" → apt install sudo
  - "Sorry, try again" at sudo prompt → no password set; run passwd <user> as root
  - systemctl fails → not a systemd host (container); use `service`
```

---

## What I learned (in my own words)

*(fill this in — 3-5 sentences: why are keys better than passwords? why does SSH refuse wrong ownership? why do containers not have systemd? what surprised me?)*
