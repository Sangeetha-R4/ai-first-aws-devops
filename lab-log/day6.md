# Day 6 — Python: Second Language, Same Problem

**Date:** 2026-10-29
**Goal:** Port `log-summary.sh` to Python. Learn the concepts by re-implementing a solved problem.

---

## Why this approach

Rather than learn Python from tutorials, I re-implemented something I already understood. The *design* transfers; only the syntax changes. This is faster and reinforces the original concepts.

---

## The bridge: bash → Python

| Need | Bash | Python |
|---|---|---|
| Argument count | `$#` | `len(sys.argv)` |
| First argument | `$1` | `sys.argv[1]` |
| File exists | `[ -f "$X" ]` | `os.path.isfile(x)` |
| Readable | `[ -r "$X" ]` | `os.access(x, os.R_OK)` |
| Count lines | `wc -l < f` | `len(lines)` |
| Count matches | `grep -c "ERROR"` | `sum(1 for l in lines if "ERROR" in l)` |
| Exit | `exit 2` | `sys.exit(2)` |
| stderr | `>&2` | `file=sys.stderr` |
| Not equal | `-ne` | `!=` |
| And / or / not | `&&` / `\|\|` / `!` | `and` / `or` / `not` |
| Variable in string | `"$VAR"` | `f"{var}"` |

---

## The final script

```python
#!/usr/bin/env python3
"""log_summary.py - count log lines by severity"""

import sys
import os


def main():
    # 1. validate arguments
    if len(sys.argv) != 2:
        print("usage: python log_summary.py <logfile>", file=sys.stderr)
        sys.exit(2)

    logfile = sys.argv[1]

    # 2. validate the file (guard clause)
    if not os.path.isfile(logfile) or not os.access(logfile, os.R_OK):
        print(f"Error: {logfile} is missing or not readable", file=sys.stderr)
        sys.exit(2)

    # 3. read
    with open(logfile) as f:
        lines = f.read().splitlines()

    # 4. count
    total = len(lines)
    errors = sum(1 for l in lines if "ERROR" in l)
    warns = sum(1 for l in lines if "WARN" in l)
    infos = sum(1 for l in lines if "INFO" in l)

    # 5. report
    print(f"=== LOG SUMMARY: {logfile} ===")
    print(f"  total  : {total}")
    print(f"  ERROR  : {errors}")
    print(f"  WARN   : {warns}")
    print(f"  INFO   : {infos}")

    # 6. exit code
    if errors > 0:
        sys.exit(1)
    sys.exit(0)


if __name__ == "__main__":
    main()
```

---

## Test results — all 5 paths

```
=== TEST 1: log with errors (expect exit 1) ===
=== LOG SUMMARY: testdata/app.log ===
  total  : 7
  ERROR  : 2
  WARN   : 1
  INFO   : 4
exit: 1

=== TEST 2: clean log (expect exit 0) ===
=== LOG SUMMARY: testdata/clean.log ===
  total  : 5
  ERROR  : 0
  WARN   : 1
  INFO   : 4
exit: 0

=== TEST 3: missing file (expect exit 2) ===
Error: testdata/nope.log is missing or not readable
exit: 2

=== TEST 4: no argument (expect exit 2) ===
usage: python log_summary.py <logfile>
exit: 2

=== TEST 5: too many args (expect exit 2) ===
usage: python log_summary.py <logfile>
exit: 2
```

**Output matches the bash version byte-for-byte** (once indentation was aligned). The two implementations are interchangeable.

---

## Mistakes I made and fixed

### 1. Typed Python into the Command Prompt
```
C:\...> if os.path.isfile(logfile) & os.access(...):
'&' was unexpected at this time.
```
**Lesson:** Python code lives in `.py` files. The shell only runs commands like `python`, `git`, `dir`.

### 2. `or` instead of `not ... or not ...` — inverted logic
```python
if os.path.isfile(f) or os.access(f, os.R_OK):   # ❌ "good" logic, wrong
if not os.path.isfile(f) or not os.access(f, os.R_OK):   # ✅ guard clause
```
**Lesson (De Morgan):** checking for *failure* means negating each part and swapping `and`→`or`.

### 3. Spurious print on the success path
```python
print("File exits and it is readable")   # ❌ noise in output
```
**Lesson:** scripts are silent on success. Noise breaks anything that parses the output.

### 4. `f "..."` with a space
```python
print(f "Error: ...")    # ❌ SyntaxError
print(f"Error: ...")     # ✅
```
**Lesson:** `f` is a prefix and must touch the quote.

### 5. Double braces
```python
print(f"total: {{{total}}}")   # → "total: {7}"
print(f"total: {total}")       # → "total: 7"
```
**Lesson:** `{{` and `}}` are escapes for literal braces inside f-strings.

### 6. `{total}` outside the quotes
```python
print(f" total : ", {total})   # ❌ prints a SET: {7}
print(f"  total  : {total}")   # ✅
```
**Lesson:** `{x}` inside an f-string is a placeholder; outside it's a **set literal**.

### 7. `pip` installed to a different Python than `python` runs
```
pip install pyyaml     → installed into Python314
python -c "import yaml" → ModuleNotFoundError (different interpreter)
```
**Lesson:** always use `python -m pip install ...` — guarantees pip matches the running interpreter.

### 8. `/tmp` doesn't exist for native Windows Python
```
python -c "open('/tmp/logtest/app.log')"   → FileNotFoundError
```
**Lesson:** `/tmp` is a Git-Bash mount, invisible to native Windows programs. **Use relative paths** (`testdata/app.log`) — they work everywhere.

---

## YAML basics

Appears in GitHub Actions, Docker Compose, Kubernetes — all Phase 2.

### Rules
```yaml
# comment
key: value          # SPACE after colon is mandatory
list:
  - item            # SPACE after dash is mandatory
nested:
  child: true       # 2-space indent, NEVER tabs
```

### The dangerous part — YAML fails silently

Correct file:
```yaml
server:
  host: localhost
  port: 8080
ports:
  - 80
  - 443
```
Parses to:
```python
{'server': {'host': 'localhost', 'port': 8080}, 'ports': [80, 443]}
```

Broken file (`port:8080`, `-80`, no space):
```yaml
server:
 port:8080
ports:
 -80
```
Parses to:
```python
{'server': 'port:8080', 'ports': -80}
```

**No error was raised.** `server` became a string, `ports` became the integer `-80`, and `host` vanished. This is why YAML typos are notorious — they produce wrong data instead of failing.

**Always validate:**
```bash
python -c "import yaml; print(yaml.safe_load(open('file.yaml')))"
```

---

## What I learned (in my own words)

*(fill this in — 3-5 sentences: what transferred from bash? what surprised me about Python? why do guard clauses read better? what's the scariest thing about YAML?)*
