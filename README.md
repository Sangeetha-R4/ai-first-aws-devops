# AI-First AWS DevOps — Portfolio

Hands-on work rebuilding production-grade AWS DevOps skills after a career break — building toward **Terraform + Docker + ECS + CI/CD**, with evidence for every claim in this repo.

> **Honest framing:** this is independent portfolio work, not professional experience. Each entry below is a lab I actually ran, with the real command output committed alongside it.

---

## What's in here

### `scripts/aws-cli/` — working operations tools

Three read-only tools, all with error handling and meaningful exit codes.

**`health-check.sh`** — confirms identity and region, then inventories the account.

```bash
./scripts/aws-cli/health-check.sh --profile portfolio --region ap-south-1
```

```
=== IDENTITY ===
  [ OK ] arn     : arn:aws:iam::<account>:user/Athena
  [ OK ] account : <account>
  [ OK ] region  : ap-south-1

=== NETWORKING (VPCs) ===
  [ OK ] vpc vpc-xxxxxxxx  cidr=172.31.0.0/16  default=True

=== STORAGE (S3) ===
  [ OK ] no buckets (0)
```

Exit codes: `0` all clear · `1` warnings · `2` bad config · `3` auth failure.

**`log-summary.sh`** — counts a log file's lines by severity.

```bash
./scripts/aws-cli/log-summary.sh /var/log/app.log
```

```
=== LOG SUMMARY: /var/log/app.log ===
  total  : 7
  ERROR  : 2
  WARN   : 1
  INFO   : 4
```

Exit codes: `0` clean · `1` log contains errors · `2` bad input.

**`log_summary.py`** — the same tool, rewritten in Python (same output, same exit codes).

```bash
python scripts/aws-cli/log_summary.py testdata/app.log
```

```
=== LOG SUMMARY: testdata/app.log ===
  total  : 7
  ERROR  : 2
  WARN   : 1
  INFO   : 4
```

Two implementations of one design — used to prove the concepts transfer across languages.

All scripts are read-only by design and were tested against their failure paths, not just the happy path.

### `lab-log/` — the evidence

One file per session: the commands actually run and the output actually returned. No paraphrasing — real terminal output.

| Entry | Topic |
|---|---|
| `day1.md` | Linux fundamentals — permissions, processes, disk/memory, logs |
| `day2.md` | Networking — interfaces, DNS, connectivity, ports, client/server |
| `day2-git.md` | Git — commit, branch, merge, rollback, push |
| `day3.md` | AWS CLI — identity, `--query`, inventory, IAM troubleshooting |
| `day4.md` | Bash scripting — first script written from scratch |
| `day6.md` | Python — porting the script; YAML and its silent-parse dangers |

---

## Skills demonstrated so far

| Area | Evidence |
|---|---|
| **Linux** | File permissions (`chmod`), process control (`ps`/`kill`), disk & memory analysis, log filtering |
| **Networking** | Interface/IP inspection, connectivity vs DNS isolation, port inspection, client-server model |
| **Git** | Three-stage workflow, branching and merging, rollback, `.gitignore` hygiene |
| **AWS CLI** | Named profiles, identity verification, JMESPath `--query`, read-only inventory |
| **IAM** | Diagnosed and fixed a real `AccessDenied` — least privilege, narrow policies over broad ones |
| **Bash** | Validation, exit codes, error handling, functions, loops, fail-fast design |
| **Python** | `sys.argv`/`sys.exit`, `with open()`, f-strings, `Counter`, guard clauses; YAML parsing |
| **Safety practice** | Read-only tooling, identity confirmed before every operation, no secrets committed |

---

## Approach

Deliberate choices, because these are the habits that matter in operations:

- **Read-only by default.** The AWS tools only call `describe`/`list`/`get`. Nothing here mutates an account.
- **Identity before action.** Every script proves which account it's talking to before touching anything. Working in the wrong account is how people destroy things.
- **Exit codes are the product.** Pretty output is for humans; the exit code is what automation reads. Distinct codes for distinct failure types.
- **Evidence over assertion.** Every lab-log entry contains real output. If it's claimed here, it ran.
- **Failure paths tested too.** A script that only works when everything's fine isn't finished.

---

## Roadmap

Currently in the foundations phase. Next milestones, in order:

- [x] Linux, networking, Git fundamentals
- [x] AWS CLI read-only operations + first scripts
- [x] Python tooling + YAML
- [ ] Terraform + Docker
- [ ] ECS Fargate deployment
- [ ] GitHub Actions CI/CD with OIDC
- [ ] Observability + runbooks
- [ ] AI-assisted incident triage with evaluation

---

## Repo conventions

- `lab-log/` — public. Session evidence, real output.
- `scripts/` — public. Working tools.
- `docs/` — private (gitignored). Personal study notes; not published.

No credentials, keys, tokens, or account-sensitive data are committed. AWS access uses a named CLI profile with read-only IAM permissions.