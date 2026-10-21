# Day 1 — Linux Fundamentals Command Reference

> Study guide. Read this when you need to refresh, and use the interview questions at the end to self-test.
> Companion to `lab-log/day1.md` (your actual outputs).

---

## 1. Orientation — "where am I?"

| Command | What it does | Example output |
|---|---|---|
| `pwd` | Print working directory — shows your current folder path | `/` |
| `whoami` | Shows which user you are | `root` |
| `ls -la` | List everything (including hidden `.` files) with full detail | `drwxr-xr-x 1 root root ...` |
| `cat /etc/os-release` | Print the OS identity file | `NAME="Ubuntu", VERSION="24.04..."` |
| `uname -a` | Show kernel + system info | `Linux ... 5.10.16.3-microsoft-standard-WSL2 ...` |

**The ritual:** whenever you land in an unfamiliar machine, run `whoami` → `pwd` → `ls -la` → `uname -a` before touching anything.

---

## 2. Files & permissions

### Reading a permissions string: `-rw-r--r--`

```
-   rwx   rwx   rwx
│   └───┘ └───┘ └───┘
│   owner  group  others
type
```

- **First char**: `-` file, `d` directory, `l` symlink (shortcut)
- **Then 3 groups of 3**: owner / group / others
- Each group: `r` read, `w` write, `x` execute, `-` none

### The numeric mapping (MEMORIZE THIS)

| Value | Permission |
|---|---|
| 4 | read (`r`) |
| 2 | write (`w`) |
| 1 | execute (`x`) |
| 0 | nothing |

Digits add up: `6` = read+write (4+2), `7` = read+write+execute (4+2+1).

### Common values

| Command | Result | Meaning |
|---|---|---|
| `chmod 644 file` | `-rw-r--r--` | Default for files: owner rw, all can read |
| `chmod 600 file` | `-rw-------` | Private: owner rw only (SSH keys use this) |
| `chmod 700 dir` | `drwx------` | Private script/dir |
| `chmod 755 dir` | `drwxr-xr-x` | Default for dirs: owner full, others read+execute |
| `chmod +x file` | adds `x` to **all three** | Make executable (everyone) |

### Symbolic vs numeric
- **Symbolic** (`+x`, `-r`, `u+w`) = modify one bit, keep the rest
- **Numeric** (`600`, `755`) = set the *entire* permission explicitly

**Common mistake:** `2` means *write*, not "nothing". "Read only" is `4`, not `2`.

### File commands
- `mkdir -p /path` — create dir, creating missing parents too (`-p` = idempotent, safe to re-run)
- `cd` — change directory
- `echo "text" > file` — write to file (overwrites!)
- `echo "text" >> file` — **append** to file (doesn't erase)
- `cat file` — print file contents
- `touch file` — create empty file / update timestamp

---

## 3. Processes

| Command | What it does |
|---|---|
| `ps aux` | All processes, full detail (Task Manager equivalent) |
| `ps aux \| grep name` | Find a specific process |
| `ps aux \| grep name \| grep -v grep` | Same, but remove the grep line itself |
| `command &` | Run in background |
| `jobs` | List your background jobs |
| `kill PID` | Terminate a process by its PID |
| `top` | Live process view (`q` to quit) |

### The "find + kill" loop (core incident skill)
```
sleep 300 &                       # start something
ps aux | grep sleep | grep -v grep  # find its PID
kill 25                           # kill it
ps aux | grep sleep               # verify it's gone
```

### Job number vs PID — CRITICAL distinction

| | Example | Scope | Used by |
|---|---|---|---|
| **Job number** | `[1]` | Your shell only | `jobs`, `fg`, `bg` |
| **PID** | `25` | Whole system | `kill`, `ps`, everything |

`kill` takes a **PID**, never a job number.

### `ps aux` column cheat sheet
- `PID` — process ID (the number you control)
- `%CPU` / `%MEM` — resource usage
- `STAT` — state: `S` sleeping (normal idle), `R` running, `Z` zombie (finished but not cleaned up)
- `COMMAND` — what's running

### Shell job status messages
- `Done` — finished on its own
- `Terminated` — was killed
- `Exit <code>` — failed with an error

Reading the difference tells you *how* a process ended — key for diagnosing why something died.

---

## 4. Disk & memory

| Command | What it does |
|---|---|
| `df -h` | Disk free — whole filesystem usage (`-h` = human-readable) |
| `du -sh /path` | Disk usage of one folder (`-s` = summary, `-h` = readable) |
| `free -h` | Memory (RAM) usage |

### The two-step disk debug
1. `df -h` → "is the disk full?" (look at `Use%` on the `/` line)
2. `du -sh /some/folder` → "which folder is eating it?"

### Memory — the interview trap
- `free` = completely unused RAM (looks low)
- `available` = free + reclaimable cache = **the real number** (looks higher)

Linux uses spare RAM as disk cache (`buff/cache`); that cache is instantly freed when needed. So **`available`, not `free`, is what matters.** If you see high swap usage, that's "memory pressure" — the machine is thrashing to disk.

### `tmpfs`
Filesystems like `/dev`, `/proc` are `tmpfs` = RAM-backed, wiped on reboot, not real disk. That's why `df -h` shows them separately.

---

## 5. Logs & filtering (the most important block)

| Command | What it does |
|---|---|
| `tail -20 file` | Last 20 lines (most recent — usually what you want) |
| `tail -f file` | **Follow** — watch new lines appear live (`Ctrl+C` to stop) |
| `head -20 file` | First 20 lines |
| `grep "pattern" file` | Filter matching lines |
| `grep -c "pattern" file` | Count matching lines (one step) |
| `grep "x" file \| wc -l` | Count lines (two steps, same result as `-c`) |
| `grep "x" \| grep -v grep` | Remove the grep itself from results |

### The pipe (`|`)
`command A | command B` = take A's output and feed it into B. The backbone of everything:
```
grep "error" app.log | wc -l      # how many errors?
grep "error" app.log | sort | uniq -c  # which error is most frequent?
```

### Reading a log line
Most logs follow `TIMESTAMP ACTION DETAILS`. The **last line before silence is the clue** — a process doesn't fail silently in a log; it fails *between* two lines, and the final line tells you where.

### `tail -f` live-catch (real-time debugging)
- Window 1: `tail -f /var/log/nginx/error.log` (watch)
- Window 2: trigger the bug
- The error line appears in Window 1 the instant it happens

---

## 6. Docker basics (used this day)

| Command | What it does |
|---|---|
| `docker info` | Verify the daemon/engine is running |
| `docker run -it --name lab1 ubuntu:24.04 bash` | **Create + start** a new container |
| `docker start -ai lab1` | **Restart** an existing container |
| `docker exec -it lab1 bash` | Run a *new* shell in a running container |
| `docker stop lab1` | Stop the container |
| `docker ps -a` | List containers (including stopped) |
| `docker rm lab1` | Delete a container |

### `run` vs `start` vs `exec`
- `run` = create new container (first time only)
- `start -ai` = restart the existing one (every time after)
- `exec -it ... bash` = open a second shell into an already-running container

**Key mental model:** a container is one machine; `start` and `exec` are just two doors into it. They share the same filesystem (prove it: `cat` the same file in both windows).

### Docker daemon
"Docker CLI installed but daemon not running" = Docker Desktop isn't open. Always launch Docker Desktop first; the whale icon must be solid.

---

## Interview questions (self-test)

**Permissions**
1. What does `-rw-r--r--` mean? What command produces it?
2. What's `chmod 600` in plain English, and why is it used for SSH keys?
3. What's the difference between `chmod 644` and `chmod 600`?
4. A directory needs `x` to be usable — why? What happens if a dir has `r` but not `x`?

**Processes**
5. What's the difference between a job number and a PID?
6. Walk me through how you'd find and kill a runaway process.
7. What does `ps aux | grep nginx | grep -v grep` do, and why the last part?
8. What do `S`, `R`, and `Z` mean in `ps` STAT? What's a zombie?

**Memory/disk**
9. In `free -h`, why is `available` higher than `free`?
10. What does high swap usage indicate?
11. Disk is full. What two commands do you run, and in what order?

**Logs**
12. What's the difference between `tail` and `tail -f`? When would you use each?
13. How do you count how many times an error appears in a log? (Two ways.)
14. What does "the last line before silence is the clue" mean in log debugging?
15. What's a pipe (`|`) and give an example of chaining three commands.

**Docker**
16. What's the difference between `docker run` and `docker start`?
17. What does `docker exec -it <name> bash` do, and when would you use it instead of `docker start`?
18. Your `docker` command errors with "daemon is not running" — what's the actual problem?

**The big picture**
19. You SSH into an unfamiliar Linux server. What are the first three commands you run, and why?
20. A service just crashed. Walk me through your complete investigation, command by command.
