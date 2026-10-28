# Day 4 — First Script Written From Scratch (Bash)

**Date:** 2026-10-27/28
**Goal:** Write `log-summary.sh` myself — not copy one — and test all its failure paths.

---

## What it does

`scripts/aws-cli/log-summary.sh` — takes a log file path, validates it, counts lines by severity (ERROR / WARN / INFO), prints a summary, and exits with a meaningful code.

---

## The script (written by me)

```bash
#!/usr/bin/env bash
set -uo pipefail

# ---------- 1. validate arguments ----------
if [ $# -ne 1 ]; then
  echo "Argument not equal to one" >&2
  exit 2
fi

LOGFILE="$1"

# ---------- 2. validate the file ----------
if [ ! -f "$LOGFILE" ] || [ ! -r "$LOGFILE" ]; then
  echo "$LOGFILE does not exist and not readable" >&2
  exit 2
fi

# ---------- 3. count lines ----------
TOTAL=$(wc -l < "$LOGFILE")
ERRORS=$(grep -c "ERROR" "$LOGFILE")
WARNS=$(grep -c "WARN" "$LOGFILE")
INFOS=$(grep -c "INFO" "$LOGFILE")

# ---------- 4. print the summary ----------
echo "=== LOG SUMMARY: $LOGFILE ==="
echo "  total  : $TOTAL"
echo "  ERROR  : $ERRORS"
echo "  WARN   : $WARNS"
echo "  INFO   : $INFOS"

# ---------- 5. exit with the right code ----------
if [ "$ERRORS" -gt 0 ]; then
  exit 1
fi
exit 0
```

---

## Test data

`/tmp/logtest/app.log` — 7 lines, known contents:

```
2026-10-26 10:00:01 INFO  service started
2026-10-26 10:00:02 INFO  connected to db
2026-10-26 10:00:05 WARN  slow query 2.4s
2026-10-26 10:00:09 ERROR connection timeout
2026-10-26 10:00:11 INFO  retrying
2026-10-26 10:00:14 ERROR connection refused
2026-10-26 10:00:15 INFO  recovered
```

---

## Test results — all five paths

### Test 1 — log containing errors

```
$ bash scripts/aws-cli/log-summary.sh /tmp/logtest/app.log; echo "exit: $?"
=== LOG SUMMARY: /tmp/logtest/app.log ===
  total  : 7
  ERROR  : 2
  WARN   : 1
  INFO   : 4
exit: 1
```

### Test 2 — clean log (no ERROR lines)

```
$ bash scripts/aws-cli/log-summary.sh /tmp/logtest/clean.log; echo "exit: $?"
=== LOG SUMMARY: /tmp/logtest/clean.log ===
  total  : 5
  ERROR  : 0
  WARN   : 1
  INFO   : 4
exit: 0
```

### Test 3 — nonexistent file

```
$ bash scripts/aws-cli/log-summary.sh /tmp/nope.log; echo "exit: $?"
/tmp/nope.log does not exist and not readable
exit: 2
```

### Test 4 — no argument

```
$ bash scripts/aws-cli/log-summary.sh; echo "exit: $?"
Argument not equal to one
exit: 2
```

### Test 5 — too many arguments

```
$ bash scripts/aws-cli/log-summary.sh a b; echo "exit: $?"
Argument not equal to one
exit: 2
```

**All five correct.** Exit codes: 1 when errors present, 0 when clean, 2 for any bad input.

---

## Bugs I hit and fixed

### Bug 1 — no spaces inside `[ ]`

```bash
if[$# -ne 1]; then          # ❌ bash tries to run a command called "if[$#"
if [ $# -ne 1 ]; then       # ✅
```

**Why:** `[` is not punctuation in bash — it's an actual command (a program). It needs spaces around it, exactly like `ls -l` does.

### Bug 2 — same thing, twice

```bash
if [! -f "LOGFILE"] || [! -r "LOGFILE"]; then     # ❌
if [ ! -f "$LOGFILE" ] || [ ! -r "$LOGFILE" ]; then  # ✅
```

### Bug 3 — missing `$` on the variable

```bash
"LOGFILE"      # ❌ the literal text "LOGFILE"
"$LOGFILE"     # ✅ whatever is inside the variable
```

**All three bugs were syntax, not logic.** The tests (`$# -ne 1`, `-f`, `-r`, `||`, `>&2`, `exit 2`) were all correct.

---

## Things I learned

**1. `grep -c` exits 1 when it finds zero matches** — even though it prints `0`.

```
zero matches  → output "0", exit code 1
some matches  → output "2", exit code 0
```

My script survives this because it uses `set -uo pipefail`, **not `-e`**. But if anyone adds `set -e`, the script would die the moment a log had no ERROR lines.

---

**2. `$?` must be read immediately.** While testing I wrote:

```bash
COUNT=$(grep -c "NOPE" file)
echo "value: $COUNT"       # this echo CLOBBERS $?
echo "exit: $?"            # now shows echo's exit code, not grep's
```

Fix: save it right away — `STATUS=$?` on the line immediately after.

---

**3. `wc -l < file` vs `wc -l file`**

```bash
wc -l /tmp/logtest/app.log     # → "7 /tmp/logtest/app.log"   (two things)
wc -l < /tmp/logtest/app.log   # → "7"                        (just the number)
```

Use `<` when you want the value alone, which is what a variable assignment needs.

---

**4. `/tmp` in Git Bash is not a real Linux folder**

It maps to `C:\Users\Imvin\AppData\Local\Temp`. Both paths refer to the same file. `cd /tmp && pwd -W` shows the Windows path.

---

**5. Test data with a known answer is how you prove a script works**

The test log has known contents (7 lines, 2 ERROR, 1 WARN, 4 INFO), so I can verify the output is *correct*, not just *plausible*. Without it I'd be guessing.

---

## What I would improve next

- Reword the error message: `-f ... || -r ...` is an **OR** test, so "does not exist **and** not readable" is misleading. Should be "missing **or** not readable".
- `printf` with field widths instead of hardcoded spaces, so alignment survives longer labels.
- Optionally count lines matching multiple severities more efficiently (one `awk` pass instead of four greps).

---

## What I learned (in my own words)

*(fill this in — 3-5 sentences: what surprised me about bash? why do exit codes matter? what would I do differently next time?)*
